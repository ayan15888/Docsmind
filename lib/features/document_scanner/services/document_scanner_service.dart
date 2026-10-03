import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:docsmind/features/document_scanner/services/pdfx_renderer.dart'
    as pfx;

class DocumentScannerService {
  static final DocumentScannerService _instance =
      DocumentScannerService._internal();

  factory DocumentScannerService() {
    return _instance;
  }

  DocumentScannerService._internal();

  // ─────────────────────────────────────────────
  //  MLKit Document Scanner
  // ─────────────────────────────────────────────

  /// Launch the MLKit Document Scanner UI and return a list of scanned image
  /// paths. Returns an empty list if the user cancels or an error occurs.
  Future<List<String>> scanWithMLKit({
    int pageLimit = 1,
    bool galleryImportAllowed = true,
    ScannerMode scannerMode = ScannerMode.full,
  }) async {
    final options = DocumentScannerOptions(
      pageLimit: pageLimit,
      isGalleryImport: galleryImportAllowed,
      documentFormat: DocumentFormat.jpeg,
      mode: scannerMode,
    );

    final scanner = DocumentScanner(options: options);
    try {
      final result = await scanner.scanDocument();
      return result.images;
    } catch (e) {
      debugPrint('[DocsMind] MLKit scanner error: $e');
      return [];
    } finally {
      scanner.close();
    }
  }

  // ─────────────────────────────────────────────
  //  MLKit OCR — Text Recognition
  // ─────────────────────────────────────────────

  /// Recognize all text in an image file using MLKit's on-device OCR.
  /// Returns an [OcrResult] with full text plus structured blocks/lines/words.
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('[DocsMind] OCR: recognizing text in $imagePath');
    final stopwatch = Stopwatch()..start();

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);
      stopwatch.stop();
      debugPrint('[DocsMind] OCR: done in ${stopwatch.elapsedMilliseconds}ms '
          '— ${result.blocks.length} blocks, ${result.text.length} chars');

      final blocks = result.blocks.map((b) {
        final lines = b.lines.map((l) {
          final words = l.elements
              .map((e) => OcrWord(text: e.text, boundingBox: e.boundingBox))
              .toList();
          return OcrLine(
              text: l.text, words: words, boundingBox: l.boundingBox);
        }).toList();
        return OcrBlock(text: b.text, lines: lines, boundingBox: b.boundingBox);
      }).toList();

      Size? imageSize;
      try {
        final bytes = await File(imagePath).readAsBytes();
        final decoded = await decodeImageFromList(bytes);
        imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        decoded.dispose();
      } catch (_) {}

      return OcrResult(
        fullText: result.text,
        blocks: blocks,
        processingMs: stopwatch.elapsedMilliseconds,
        imageSize: imageSize,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[DocsMind] OCR error: $e');
      return OcrResult(
          fullText: '', blocks: [], processingMs: 0, error: e.toString());
    } finally {
      recognizer.close();
    }
  }

  // ─────────────────────────────────────────────
  //  Dart-only Edge Detection (live preview / fallback)
  // ─────────────────────────────────────────────

  /// Detect document edges from image using pure Dart (no native code).
  /// Returns a [DetectedDocument] with corner information (proportional 0–1).
  Future<DetectedDocument?> detectDocumentEdges(String imagePath) async {
    debugPrint('[DocsMind] detectDocumentEdges (Dart) → path=$imagePath');
    final stopwatch = Stopwatch()..start();

    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('[DocsMind]    File does not exist');
        return _fallbackDocument(imagePath);
      }

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        debugPrint('[DocsMind]    Failed to decode image');
        return _fallbackDocument(imagePath);
      }

      debugPrint(
          '[DocsMind]   Image decoded: ${decoded.width}x${decoded.height}');
      final corners = _detectDocumentCorners(decoded);
      final isDetected = corners != null && corners.length >= 4;

      stopwatch.stop();
      debugPrint(
          '[DocsMind]   ${isDetected ? " Document detected" : " No document found"} (${stopwatch.elapsedMilliseconds}ms)');

      return DetectedDocument(
        originalPath: imagePath,
        croppedPath: imagePath,
        corners: isDetected ? corners : _getDefaultDocumentCorners(),
        isDetected: isDetected,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '[DocsMind]    Edge detection error (${stopwatch.elapsedMilliseconds}ms): $e');
      return _fallbackDocument(imagePath);
    }
  }

  // ─────────────────────────────────────────────
  //  Live Camera Detection (Dart)
  // ─────────────────────────────────────────────

  /// Quick document detection from camera Y plane (luminance).
  /// Returns corners in 0–1 coordinates when a document-like region is detected.
  LiveDetectionResult? detectDocumentInFrameLive(
    Uint8List yPlane,
    int width,
    int height, {
    int? bytesPerRow,
  }) {
    if (width < 40 || height < 40) return null;
    final stride = bytesPerRow ?? width;
    const step = 4;
    final sw = (width / step).floor().clamp(50, 400);
    final sh = (height / step).floor().clamp(50, 400);
    final smallW = sw;
    final smallH = sh;
    final bytes = Uint8List(smallW * smallH * 3);
    for (int y = 0; y < smallH; y++) {
      for (int x = 0; x < smallW; x++) {
        final srcX = (x * width / smallW).floor().clamp(0, width - 1);
        final srcY = (y * height / smallH).floor().clamp(0, height - 1);
        final lum = yPlane[srcY * stride + srcX];
        final i = (y * smallW + x) * 3;
        bytes[i] = lum;
        bytes[i + 1] = lum;
        bytes[i + 2] = lum;
      }
    }
    img.Image gray;
    try {
      gray = img.Image.fromBytes(
        width: smallW,
        height: smallH,
        bytes: bytes.buffer,
        numChannels: 3,
      );
    } catch (_) {
      return null;
    }
    final corners = _detectDocumentCorners(gray);
    if (corners == null || corners.length < 4) return null;
    return LiveDetectionResult(isDetected: true, corners: corners);
  }

  // ─────────────────────────────────────────────
  //  Dart Fallback: Crop to Bounding Box
  // ─────────────────────────────────────────────

  /// Crop the image to the bounding box of the provided corners.
  Future<String> cropToBoundingBox(
      String imagePath, List<Offset> corners) async {
    try {
      if (corners.length < 4) return imagePath;
      final file = File(imagePath);
      if (!file.existsSync()) return imagePath;

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imagePath;

      final w = decoded.width;
      final h = decoded.height;

      final xs = corners
          .map((c) => (c.dx <= 1.0 ? c.dx * w : c.dx)
              .clamp(0.0, w.toDouble() - 1)
              .toInt())
          .toList();
      final ys = corners
          .map((c) => (c.dy <= 1.0 ? c.dy * h : c.dy)
              .clamp(0.0, h.toDouble() - 1)
              .toInt())
          .toList();

      final minX = xs.reduce((a, b) => a < b ? a : b);
      final maxX = xs.reduce((a, b) => a > b ? a : b);
      final minY = ys.reduce((a, b) => a < b ? a : b);
      final maxY = ys.reduce((a, b) => a > b ? a : b);

      final cropW = (maxX - minX).clamp(1, w);
      final cropH = (maxY - minY).clamp(1, h);

      final cropped =
          img.copyCrop(decoded, x: minX, y: minY, width: cropW, height: cropH);

      final dir = file.parent;
      final name = file.uri.pathSegments.last;
      final croppedName = name
          .replaceFirst('.jpg', '_cropped.jpg')
          .replaceFirst('.jpeg', '_cropped.jpeg');
      final newPath = '${dir.path}${Platform.pathSeparator}$croppedName';

      final encoded = img.encodeJpg(cropped, quality: 95);
      await File(newPath).writeAsBytes(encoded, flush: true);
      return newPath;
    } catch (_) {
      return imagePath;
    }
  }

  /// Build a single PDF file from a list of image paths and return its path.
  Future<String?> buildPdfFromImages(
    List<String> imagePaths, {
    String? watermarkText,
    double? quality,
  }) async {
    if (imagePaths.isEmpty) return null;
    try {
      final pdf = pw.Document();

      for (final path in imagePaths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        var bytes = await file.readAsBytes();

        // Apply compression if quality is specified and less than 100
        if (quality != null && quality < 100.0) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            bytes = Uint8List.fromList(
                img.encodeJpg(decoded, quality: quality.toInt()));
          }
        }

        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                pw.Center(
                  child: pw.FittedBox(
                    fit: pw.BoxFit.contain,
                    child: pw.Image(image),
                  ),
                ),
                if (watermarkText != null && watermarkText.isNotEmpty)
                  pw.Center(
                    child: pw.Transform.rotate(
                      angle: 0.785398, // 45 degrees in radians
                      child: pw.Text(
                        watermarkText,
                        style: pw.TextStyle(
                          color: const PdfColor(0, 0, 0, 0.3),
                          fontSize: 80,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      final dir = await getTemporaryDirectory();
      final pdfPath =
          '${dir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save(), flush: true);
      return pdfPath;
    } catch (e) {
      debugPrint('Error building PDF: $e');
      return null;
    }
  }

  /// Compresses a list of images to a specific format (JPEG, PNG, or WEBP) and quality.
  /// Returns a list of compressed image file paths.
  Future<List<String>> compressImages(
    List<String> imagePaths, {
    required String format,
    required double quality,
  }) async {
    final List<String> compressedPaths = [];
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < imagePaths.length; i++) {
      final file = File(imagePaths[i]);
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      List<int> encodedBytes;
      String extension;

      final formatUpper = format.toUpperCase();
      if (formatUpper == 'PNG') {
        encodedBytes = img.encodePng(decoded,
            level: ((100 - quality) / 10).clamp(0, 9).toInt());
        extension = 'png';
      } else {
        // Default to JPEG (also falls back for WEBP since encodeWebP is not
        // supported in the pure-Dart 'image' package)
        encodedBytes = img.encodeJpg(decoded, quality: quality.toInt());
        extension = 'jpg';
      }

      final outPath = '${tempDir.path}/compressed_${timestamp}_$i.$extension';
      await File(outPath).writeAsBytes(encodedBytes, flush: true);
      compressedPaths.add(outPath);
    }
    return compressedPaths;
  }

  /// Compresses a mixed list of images and/or PDF files to the target format (PDF, JPEG, or PNG).
  /// Renders PDF pages using native engine with memory-stream fallback, downsamples and compresses
  /// images according to [quality], and applies optional [watermarkText].
  Future<CompressionResult?> compressMixedFiles(
    List<String> filePaths, {
    required String format,
    required double quality,
    String? watermarkText,
  }) async {
    if (filePaths.isEmpty) return null;

    int originalTotalBytes = 0;
    for (final path in filePaths) {
      final f = File(path);
      if (await f.exists()) {
        originalTotalBytes += await f.length();
      }
    }

    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final formatUpper = format.toUpperCase();

    // ── Output Format: PDF ──────────────────────────────────────────
    if (formatUpper == 'PDF') {
      final pdf = pw.Document();
      int pageCount = 0;

      for (final path in filePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        if (path.toLowerCase().endsWith('.pdf')) {
          // Robust PDF opening with openFile and openData fallback
          pfx.PdfDocument? doc;
          try {
            doc = await pfx.PdfDocument.openFile(path);
          } catch (e) {
            debugPrint(
                'Failed to open PDF with openFile, falling back to openData: $e');
            try {
              final pdfBytes = await file.readAsBytes();
              doc = await pfx.PdfDocument.openData(pdfBytes);
            } catch (e2) {
              debugPrint('Failed to open PDF with openData: $e2');
            }
          }

          if (doc != null) {
            try {
              // Scale resolution based on user quality setting
              final double scale;
              final int jpgQuality;
              if (quality <= 35) {
                scale = (0.75 + (quality / 100.0) * 0.45).clamp(0.80, 1.05);
                jpgQuality = (quality * 1.1).clamp(25, 45).toInt();
              } else if (quality <= 70) {
                scale = (0.90 + (quality / 100.0) * 0.55).clamp(1.05, 1.35);
                jpgQuality = (quality * 0.95).clamp(45, 65).toInt();
              } else {
                scale = (1.05 + (quality / 100.0) * 0.65).clamp(1.35, 1.70);
                jpgQuality = (quality * 0.90).clamp(65, 82).toInt();
              }

              for (int i = 1; i <= doc.pagesCount; i++) {
                pfx.PdfPage? page;
                try {
                  page = await doc.getPage(i);
                  final renderW = (page.width * scale).roundToDouble();
                  final renderH = (page.height * scale).roundToDouble();

                  final pageImage = await page.render(
                    width: renderW,
                    height: renderH,
                    format: pfx.PdfPageImageFormat.jpeg,
                    backgroundColor: '#FFFFFF',
                    quality: jpgQuality,
                  );

                  if (pageImage != null && pageImage.bytes.isNotEmpty) {
                    _addPageToPdf(pdf, pageImage.bytes, watermarkText);
                    pageCount++;
                  }
                } catch (pe) {
                  debugPrint('Error rendering page $i: $pe');
                } finally {
                  await page?.close();
                }
              }
            } finally {
              await doc.close();
            }
          } else {
            // Fallback for corrupt or password-locked PDFs: try raw JPEG extraction
            final pdfBytes = await file.readAsBytes();
            final extracted = _extractJpegsFromPdf(pdfBytes);
            for (final jBytes in extracted) {
              final compressedBytes = _recompressImageBytes(jBytes, quality);
              _addPageToPdf(pdf, compressedBytes, watermarkText);
              pageCount++;
            }
          }
        } else {
          // Standard Image file
          final bytes = await file.readAsBytes();
          final compressedBytes = _recompressImageBytes(bytes, quality);
          _addPageToPdf(pdf, compressedBytes, watermarkText);
          pageCount++;
        }
      }

      if (pageCount == 0) return null;

      final outPath = '${tempDir.path}/compressed_doc_$ts.pdf';
      final pdfBytes = await pdf.save();
      await File(outPath).writeAsBytes(pdfBytes, flush: true);

      var compressedTotalBytes = await File(outPath).length();

      // If output is somehow larger than original on a single PDF, retry with aggressive compression
      if (filePaths.length == 1 &&
          filePaths.first.toLowerCase().endsWith('.pdf') &&
          compressedTotalBytes >= originalTotalBytes &&
          originalTotalBytes > 50 * 1024) {
        try {
          final aggressivePdf = pw.Document();
          int aggCount = 0;
          pfx.PdfDocument? doc;
          try {
            doc = await pfx.PdfDocument.openFile(filePaths.first);
          } catch (_) {
            try {
              final b = await File(filePaths.first).readAsBytes();
              doc = await pfx.PdfDocument.openData(b);
            } catch (_) {}
          }

          if (doc != null) {
            try {
              for (int i = 1; i <= doc.pagesCount; i++) {
                pfx.PdfPage? page;
                try {
                  page = await doc.getPage(i);
                  final pageImage = await page.render(
                    width: (page.width * 0.85).roundToDouble(),
                    height: (page.height * 0.85).roundToDouble(),
                    format: pfx.PdfPageImageFormat.jpeg,
                    backgroundColor: '#FFFFFF',
                    quality: 40,
                  );
                  if (pageImage != null && pageImage.bytes.isNotEmpty) {
                    _addPageToPdf(
                        aggressivePdf, pageImage.bytes, watermarkText);
                    aggCount++;
                  }
                } finally {
                  await page?.close();
                }
              }
            } finally {
              await doc.close();
            }

            if (aggCount > 0) {
              final aggBytes = await aggressivePdf.save();
              if (aggBytes.length < compressedTotalBytes) {
                await File(outPath).writeAsBytes(aggBytes, flush: true);
                compressedTotalBytes = aggBytes.length;
              }
            }
          }
        } catch (_) {}
      }

      return CompressionResult(
        outputPaths: [outPath],
        originalTotalBytes: originalTotalBytes,
        compressedTotalBytes: compressedTotalBytes,
        format: 'PDF',
      );
    }

    // ── Output Format: JPEG or PNG ──────────────────────────────────
    final List<String> outputPaths = [];
    int compressedTotalBytes = 0;
    int index = 0;

    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      if (path.toLowerCase().endsWith('.pdf')) {
        pfx.PdfDocument? doc;
        try {
          doc = await pfx.PdfDocument.openFile(path);
        } catch (e) {
          try {
            final pdfBytes = await file.readAsBytes();
            doc = await pfx.PdfDocument.openData(pdfBytes);
          } catch (_) {}
        }

        if (doc != null) {
          try {
            final double scale;
            final int jpgQuality;
            if (quality <= 35) {
              scale = (0.75 + (quality / 100.0) * 0.45).clamp(0.80, 1.05);
              jpgQuality = (quality * 1.1).clamp(25, 45).toInt();
            } else if (quality <= 70) {
              scale = (0.90 + (quality / 100.0) * 0.55).clamp(1.05, 1.35);
              jpgQuality = (quality * 0.95).clamp(45, 65).toInt();
            } else {
              scale = (1.05 + (quality / 100.0) * 0.65).clamp(1.35, 1.70);
              jpgQuality = (quality * 0.90).clamp(65, 82).toInt();
            }

            for (int i = 1; i <= doc.pagesCount; i++) {
              pfx.PdfPage? page;
              try {
                page = await doc.getPage(i);
                final renderW = (page.width * scale).roundToDouble();
                final renderH = (page.height * scale).roundToDouble();

                final targetFmt = formatUpper == 'PNG'
                    ? pfx.PdfPageImageFormat.png
                    : pfx.PdfPageImageFormat.jpeg;

                final pageImage = await page.render(
                  width: renderW,
                  height: renderH,
                  format: targetFmt,
                  backgroundColor: '#FFFFFF',
                  quality: jpgQuality,
                );

                if (pageImage != null && pageImage.bytes.isNotEmpty) {
                  final ext = formatUpper == 'PNG' ? 'png' : 'jpg';
                  final outPath =
                      '${tempDir.path}/compressed_${ts}_${index++}.$ext';
                  await File(outPath)
                      .writeAsBytes(pageImage.bytes, flush: true);
                  outputPaths.add(outPath);
                  compressedTotalBytes += pageImage.bytes.length;
                }
              } finally {
                await page?.close();
              }
            }
          } finally {
            await doc.close();
          }
        }
      } else {
        // Image file
        final bytes = await file.readAsBytes();
        final compressedBytes = _recompressImageBytes(bytes, quality);
        final ext = formatUpper == 'PNG' ? 'png' : 'jpg';
        final outPath = '${tempDir.path}/compressed_${ts}_${index++}.$ext';
        await File(outPath).writeAsBytes(compressedBytes, flush: true);
        outputPaths.add(outPath);
        compressedTotalBytes += compressedBytes.length;
      }
    }

    if (outputPaths.isEmpty) return null;

    return CompressionResult(
      outputPaths: outputPaths,
      originalTotalBytes: originalTotalBytes,
      compressedTotalBytes: compressedTotalBytes,
      format: formatUpper,
    );
  }

  /// Recompresses image bytes at [quality] and downsamples dimensions with guaranteed size reduction.
  Uint8List _recompressImageBytes(Uint8List rawBytes, double quality) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      img.Image processed = decoded;

      // Select target dimensions and JPEG quality
      final int maxDim;
      final int jpgQuality;
      if (quality <= 35) {
        maxDim = 1100;
        jpgQuality = (quality * 1.1).clamp(25, 45).toInt();
      } else if (quality <= 70) {
        maxDim = 1500;
        jpgQuality = (quality * 0.95).clamp(45, 65).toInt();
      } else {
        maxDim = 1920;
        jpgQuality = (quality * 0.88).clamp(65, 80).toInt();
      }

      if (processed.width > maxDim || processed.height > maxDim) {
        if (processed.width >= processed.height) {
          processed = img.copyResize(processed,
              width: maxDim, interpolation: img.Interpolation.linear);
        } else {
          processed = img.copyResize(processed,
              height: maxDim, interpolation: img.Interpolation.linear);
        }
      }

      var outJpg =
          Uint8List.fromList(img.encodeJpg(processed, quality: jpgQuality));

      // If output JPEG isn't smaller than rawBytes, do aggressive downscale pass
      if (outJpg.length >= rawBytes.length && rawBytes.length > 25 * 1024) {
        final downscaled = img.copyResize(
          processed,
          width: (processed.width * 0.75).round(),
          interpolation: img.Interpolation.linear,
        );
        final aggressiveJpg = Uint8List.fromList(
          img.encodeJpg(downscaled, quality: (jpgQuality - 15).clamp(20, 50)),
        );
        if (aggressiveJpg.length < rawBytes.length) {
          outJpg = aggressiveJpg;
        }
      }

      return outJpg.length < rawBytes.length ? outJpg : rawBytes;
    } catch (_) {
      return rawBytes;
    }
  }

  /// Extracts embedded JPEG byte streams from a PDF binary buffer.
  List<Uint8List> _extractJpegsFromPdf(Uint8List pdfBytes) {
    final List<Uint8List> jpegs = [];
    int index = 0;
    while (index < pdfBytes.length - 3) {
      if (pdfBytes[index] == 0xFF &&
          pdfBytes[index + 1] == 0xD8 &&
          pdfBytes[index + 2] == 0xFF) {
        final startIndex = index;
        int endIndex = startIndex + 3;
        while (endIndex < pdfBytes.length - 1) {
          if (pdfBytes[endIndex] == 0xFF && pdfBytes[endIndex + 1] == 0xD9) {
            endIndex += 2;
            break;
          }
          endIndex++;
        }
        if (endIndex > startIndex + 100) {
          final jpeg = pdfBytes.sublist(startIndex, endIndex);
          jpegs.add(jpeg);
        }
        index = endIndex;
      } else {
        index++;
      }
    }
    return jpegs;
  }

  /// Adds an image page to a PDF with adaptive orientation and optional diagonal watermark.
  void _addPageToPdf(
    pw.Document pdf,
    Uint8List imageBytes,
    String? watermarkText,
  ) {
    final image = pw.MemoryImage(imageBytes);
    final imgW = image.width?.toDouble() ?? 595.28;
    final imgH = image.height?.toDouble() ?? 841.89;
    final isLandscape = imgW > imgH;
    final pageFormat = isLandscape
        ? const PdfPageFormat(841.89, 595.28, marginAll: 0)
        : const PdfPageFormat(595.28, 841.89, marginAll: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Stack(
          alignment: pw.Alignment.center,
          fit: pw.StackFit.expand,
          children: [
            pw.Image(image, fit: pw.BoxFit.contain),
            if (watermarkText != null && watermarkText.trim().isNotEmpty)
              pw.Center(
                child: pw.Transform.rotate(
                  angle: -0.785398, // -45 degrees diagonal
                  child: pw.Text(
                    watermarkText.trim(),
                    style: pw.TextStyle(
                      color: const PdfColor(0.8, 0, 0, 0.28),
                      fontSize: 52,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Internal Helpers — Improved Edge Detection
  // ─────────────────────────────────────────────

  /// Improved document corner detection using edge scanning from all 4 sides.
  /// Returns 4 corners in normalized 0–1 coordinates, or null if no document found.
  List<Offset>? _detectDocumentCorners(img.Image source) {
    final w = source.width;
    final h = source.height;
    if (w < 30 || h < 30) return null;

    // Step 1: Resize for speed (max 400px on longest side)
    const maxDim = 400;
    final scale = maxDim / (w > h ? w : h);
    final sw = (w * scale).round().clamp(30, w);
    final sh = (h * scale).round().clamp(30, h);
    img.Image small = img.copyResize(source, width: sw, height: sh);
    final rw = small.width;
    final rh = small.height;

    // Step 2: Convert to grayscale
    small = img.grayscale(small);

    // Step 3: Build luminance array for fast access
    final lum = List<List<int>>.generate(rh, (y) {
      return List<int>.generate(rw, (x) {
        final p = small.getPixel(x, y);
        return p.r.toInt(); // grayscale so r=g=b
      });
    });

    // Step 4: Compute gradient magnitude (simplified Sobel)
    final grad = List<List<int>>.generate(rh, (_) => List<int>.filled(rw, 0));
    for (int y = 1; y < rh - 1; y++) {
      for (int x = 1; x < rw - 1; x++) {
        final gx = -lum[y - 1][x - 1] +
            lum[y - 1][x + 1] -
            2 * lum[y][x - 1] +
            2 * lum[y][x + 1] -
            lum[y + 1][x - 1] +
            lum[y + 1][x + 1];
        final gy = -lum[y - 1][x - 1] -
            2 * lum[y - 1][x] -
            lum[y - 1][x + 1] +
            lum[y + 1][x - 1] +
            2 * lum[y + 1][x] +
            lum[y + 1][x + 1];
        // Use Manhattan distance for speed (avoids sqrt)
        grad[y][x] = (gx.abs() + gy.abs()).clamp(0, 255);
      }
    }

    // Step 5: Adaptive threshold — compute mean gradient, use 1.5x as threshold
    int gradSum = 0;
    int gradCount = 0;
    for (int y = 1; y < rh - 1; y++) {
      for (int x = 1; x < rw - 1; x++) {
        if (grad[y][x] > 5) {
          gradSum += grad[y][x];
          gradCount++;
        }
      }
    }
    final meanGrad = gradCount > 0 ? gradSum / gradCount : 30;
    final threshold = (meanGrad * 0.8).round().clamp(15, 100);

    // Step 6: Build binary edge map
    final edge = List<List<bool>>.generate(rh, (y) {
      return List<bool>.generate(rw, (x) => grad[y][x] >= threshold);
    });

    // Step 7: Scan from each side to find the document boundary
    const scanMargin = 3; // skip outer 3 pixels (camera noise)

    final topEdge = List<int>.filled(rw, rh);
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      for (int y = scanMargin; y < rh - scanMargin; y++) {
        if (edge[y][x]) {
          topEdge[x] = y;
          break;
        }
      }
    }

    final bottomEdge = List<int>.filled(rw, 0);
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      for (int y = rh - scanMargin - 1; y >= scanMargin; y--) {
        if (edge[y][x]) {
          bottomEdge[x] = y;
          break;
        }
      }
    }

    final leftEdge = List<int>.filled(rh, rw);
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      for (int x = scanMargin; x < rw - scanMargin; x++) {
        if (edge[y][x]) {
          leftEdge[y] = x;
          break;
        }
      }
    }

    final rightEdge = List<int>.filled(rh, 0);
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      for (int x = rw - scanMargin - 1; x >= scanMargin; x--) {
        if (edge[y][x]) {
          rightEdge[y] = x;
          break;
        }
      }
    }

    // Step 8: Filter valid edge data
    final validTop = <int>[];
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      if (topEdge[x] < rh - scanMargin) validTop.add(topEdge[x]);
    }

    final validBottom = <int>[];
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      if (bottomEdge[x] > scanMargin) validBottom.add(bottomEdge[x]);
    }

    final validLeft = <int>[];
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      if (leftEdge[y] < rw - scanMargin) validLeft.add(leftEdge[y]);
    }

    final validRight = <int>[];
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      if (rightEdge[y] > scanMargin) validRight.add(rightEdge[y]);
    }

    if (validTop.length < 10 ||
        validBottom.length < 10 ||
        validLeft.length < 10 ||
        validRight.length < 10) {
      debugPrint('[DocsMind] Not enough edge data from all 4 sides');
      return null;
    }

    validTop.sort();
    validBottom.sort();
    validLeft.sort();
    validRight.sort();

    final topY = validTop[(validTop.length * 0.25).round()];
    final bottomY = validBottom[(validBottom.length * 0.75).round()];
    final leftX = validLeft[(validLeft.length * 0.25).round()];
    final rightX = validRight[(validRight.length * 0.75).round()];

    final docW = rightX - leftX;
    final docH = bottomY - topY;
    if (docW < rw * 0.15 || docH < rh * 0.15) {
      debugPrint(
          '[DocsMind] Detected region too small: ${docW}x$docH in ${rw}x$rh');
      return null;
    }

    // Step 9: Refine corners
    final tlX =
        _refineCornerX(leftEdge, topY, (topY + docH * 0.3).round(), true);
    final tlY =
        _refineCornerY(topEdge, leftX, (leftX + docW * 0.3).round(), true);

    final trX =
        _refineCornerX(rightEdge, topY, (topY + docH * 0.3).round(), false);
    final trY =
        _refineCornerY(topEdge, (rightX - docW * 0.3).round(), rightX, true);

    final brX = _refineCornerX(
        rightEdge, (bottomY - docH * 0.3).round(), bottomY, false);
    final brY = _refineCornerY(
        bottomEdge, (rightX - docW * 0.3).round(), rightX, false);

    final blX =
        _refineCornerX(leftEdge, (bottomY - docH * 0.3).round(), bottomY, true);
    final blY =
        _refineCornerY(bottomEdge, leftX, (leftX + docW * 0.3).round(), false);

    // Step 10: Convert to normalized 0-1 coordinates with small padding
    const pad = 0.005;
    final corners = [
      Offset(
        ((tlX ?? leftX) / rw - pad).clamp(0.0, 1.0),
        ((tlY ?? topY) / rh - pad).clamp(0.0, 1.0),
      ),
      Offset(
        ((trX ?? rightX) / rw + pad).clamp(0.0, 1.0),
        ((trY ?? topY) / rh - pad).clamp(0.0, 1.0),
      ),
      Offset(
        ((brX ?? rightX) / rw + pad).clamp(0.0, 1.0),
        ((brY ?? bottomY) / rh + pad).clamp(0.0, 1.0),
      ),
      Offset(
        ((blX ?? leftX) / rw - pad).clamp(0.0, 1.0),
        ((blY ?? bottomY) / rh + pad).clamp(0.0, 1.0),
      ),
    ];

    final area = _quadArea(corners);
    if (area < 0.05 || area > 0.98) {
      debugPrint('[DocsMind] Quad area out of range: $area');
      return null;
    }

    debugPrint(
        '[DocsMind]  Detected corners: $corners (area=${area.toStringAsFixed(3)})');
    return corners;
  }

  double? _refineCornerX(
      List<int> edgeByRow, int yStart, int yEnd, bool findMin) {
    final values = <int>[];
    final safeStart = yStart.clamp(0, edgeByRow.length - 1);
    final safeEnd = yEnd.clamp(0, edgeByRow.length - 1);
    for (int y = safeStart; y <= safeEnd; y++) {
      if (edgeByRow[y] > 0 && edgeByRow[y] < edgeByRow.length) {
        values.add(edgeByRow[y]);
      }
    }
    if (values.isEmpty) return null;
    values.sort();
    return values[values.length ~/ 2].toDouble();
  }

  double? _refineCornerY(
      List<int> edgeByCol, int xStart, int xEnd, bool findMin) {
    final values = <int>[];
    final safeStart = xStart.clamp(0, edgeByCol.length - 1);
    final safeEnd = xEnd.clamp(0, edgeByCol.length - 1);
    for (int x = safeStart; x <= safeEnd; x++) {
      if (edgeByCol[x] > 0 && edgeByCol[x] < edgeByCol.length) {
        values.add(edgeByCol[x]);
      }
    }
    if (values.isEmpty) return null;
    values.sort();
    return values[values.length ~/ 2].toDouble();
  }

  double _quadArea(List<Offset> corners) {
    if (corners.length < 4) return 0;
    double area = 0;
    for (int i = 0; i < corners.length; i++) {
      final j = (i + 1) % corners.length;
      area += corners[i].dx * corners[j].dy;
      area -= corners[j].dx * corners[i].dy;
    }
    return (area / 2).abs();
  }

  DetectedDocument _fallbackDocument(String imagePath) {
    return DetectedDocument(
      originalPath: imagePath,
      croppedPath: imagePath,
      corners: _getDefaultDocumentCorners(),
      isDetected: false,
    );
  }

  List<Offset> _getDefaultDocumentCorners() {
    return const [
      Offset(0.05, 0.05),
      Offset(0.95, 0.05),
      Offset(0.95, 0.95),
      Offset(0.05, 0.95),
    ];
  }
}

/// Represents a detected document with corner points.
class DetectedDocument {
  final String originalPath;
  final String croppedPath;
  final List<Offset> corners;
  final bool isDetected;

  DetectedDocument({
    required this.originalPath,
    required this.croppedPath,
    required this.corners,
    required this.isDetected,
  });
}

/// Lightweight result used while streaming camera frames.
class LiveDetectionResult {
  final bool isDetected;
  final List<Offset> corners;

  LiveDetectionResult({
    required this.isDetected,
    required this.corners,
  });
}

// ─────────────────────────────────────────────
//  OCR Data Models
// ─────────────────────────────────────────────

/// Top-level result from [DocumentScannerService.recognizeText].
class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;
  final int processingMs;
  final String? error;
  final Size? imageSize;

  bool get hasText => fullText.trim().isNotEmpty;
  bool get hasError => error != null;

  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.processingMs,
    this.error,
    this.imageSize,
  });
}

/// A block of text (paragraph-level grouping from MLKit).
class OcrBlock {
  final String text;
  final List<OcrLine> lines;
  final Rect? boundingBox;

  const OcrBlock({
    required this.text,
    required this.lines,
    this.boundingBox,
  });
}

/// A single line of text within an [OcrBlock].
class OcrLine {
  final String text;
  final List<OcrWord> words;
  final Rect? boundingBox;

  const OcrLine({
    required this.text,
    required this.words,
    this.boundingBox,
  });
}

/// A single word/element within an [OcrLine].
class OcrWord {
  final String text;
  final Rect? boundingBox;

  const OcrWord({required this.text, this.boundingBox});
}

// ─────────────────────────────────────────────
//  Compression Data Model
// ─────────────────────────────────────────────

/// Result of a multi-file or single-file compression operation.
class CompressionResult {
  final List<String> outputPaths;
  final int originalTotalBytes;
  final int compressedTotalBytes;
  final String format;

  const CompressionResult({
    required this.outputPaths,
    required this.originalTotalBytes,
    required this.compressedTotalBytes,
    required this.format,
  });

  /// Percentage of space saved (0% to 99.9%).
  double get savedPercentage {
    if (originalTotalBytes <= 0) return 0;
    final saved =
        (originalTotalBytes - compressedTotalBytes) / originalTotalBytes;
    return (saved * 100).clamp(0.0, 99.9);
  }
}
