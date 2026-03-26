import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Status of the native OpenCV connection.
class OpenCVStatus {
  final bool isAvailable;
  final String? version;
  final String? error;
  final DateTime checkedAt;

  OpenCVStatus({
    required this.isAvailable,
    this.version,
    this.error,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  @override
  String toString() =>
      'OpenCVStatus(available=$isAvailable, version=$version, error=$error)';
}

class DocumentScannerService {
  static const MethodChannel _channel =
      MethodChannel('docsmind/opencv_document');

  static final DocumentScannerService _instance =
      DocumentScannerService._internal();

  factory DocumentScannerService() {
    return _instance;
  }

  DocumentScannerService._internal();

  // ─────────────────────────────────────────────
  //  Developer Log: OpenCV Connection Check
  // ─────────────────────────────────────────────

  /// Check whether the native OpenCV library is available.
  /// Returns an [OpenCVStatus] with connection details.
  Future<OpenCVStatus> checkOpenCVConnection() async {
    debugPrint('┌──────────────────────────────────────');
    debugPrint('│ [DocsMind] Checking OpenCV connection...');
    debugPrint('└──────────────────────────────────────');

    try {
      final stopwatch = Stopwatch()..start();
      final result = await _channel.invokeMethod('isOpenCVAvailable');
      stopwatch.stop();

      debugPrint('┌──────────────────────────────────────');
      debugPrint(
          '│ [DocsMind] OpenCV Response (${stopwatch.elapsedMilliseconds}ms):');

      if (result == null) {
        debugPrint('│   ❌ Received null response from native');
        debugPrint('└──────────────────────────────────────');
        return OpenCVStatus(
            isAvailable: false, error: 'Null response from native');
      }

      final isAvailable = result['isAvailable'] == true;
      final version = result['version'] as String?;
      final error = result['error'] as String?;

      if (isAvailable) {
        debugPrint('│   ✅ OpenCV CONNECTED');
        debugPrint('│   📦 Version: $version');
      } else {
        debugPrint('│   ❌ OpenCV DISCONNECTED');
        debugPrint('│   ⚠️  Error: $error');
      }
      debugPrint('└──────────────────────────────────────');

      return OpenCVStatus(
        isAvailable: isAvailable,
        version: version,
        error: error,
      );
    } on MissingPluginException catch (e) {
      debugPrint('┌──────────────────────────────────────');
      debugPrint('│ [DocsMind] ❌ MethodChannel not registered');
      debugPrint('│   Platform may not support OpenCV');
      debugPrint('│   Error: $e');
      debugPrint('└──────────────────────────────────────');
      return OpenCVStatus(
        isAvailable: false,
        error: 'MethodChannel not registered (platform unsupported)',
      );
    } catch (e) {
      debugPrint('┌──────────────────────────────────────');
      debugPrint('│ [DocsMind] ❌ Unexpected error checking OpenCV');
      debugPrint('│   Error: $e');
      debugPrint('└──────────────────────────────────────');
      return OpenCVStatus(isAvailable: false, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────
  //  Native Document Processing (Perspective Transform + Enhancement)
  // ─────────────────────────────────────────────

  /// Process a document image using native OpenCV:
  /// 1. Perspective transform to get a top-down view
  /// 2. Apply enhancement filter (whiteboard, grayscale, bw, color)
  /// Returns the processed image path.
  Future<String> processDocumentNative(
    String imagePath,
    List<Offset> corners, {
    String filter = 'whiteboard',
    String documentMode = 'auto',
  }) async {
    debugPrint('┌──────────────────────────────────────');
    debugPrint('│ [DocsMind] Processing document natively...');
    debugPrint('│   Path: $imagePath');
    debugPrint('│   Filter: $filter');
    debugPrint('│   Mode: $documentMode');
    debugPrint('│   Corners: $corners');
    debugPrint('└──────────────────────────────────────');

    try {
      final stopwatch = Stopwatch()..start();
      final cornersList = corners.map((c) => [c.dx, c.dy]).toList();

      final result = await _channel.invokeMethod('processDocument', {
        'path': imagePath,
        'corners': cornersList,
        'filter': filter,
        'mode': documentMode,
      });
      stopwatch.stop();

      final outputPath = result['outputPath'] as String?;
      debugPrint('┌──────────────────────────────────────');
      debugPrint(
          '│ [DocsMind] ✅ Native processing done (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('│   Output: $outputPath');
      debugPrint('└──────────────────────────────────────');

      if (outputPath != null && File(outputPath).existsSync()) {
        return outputPath;
      }
      return imagePath;
    } on MissingPluginException {
      debugPrint(
          '[DocsMind] processDocument not available, falling back to Dart crop');
      return cropToBoundingBox(imagePath, corners);
    } catch (e) {
      debugPrint('[DocsMind] ❌ processDocumentNative error: $e');
      return cropToBoundingBox(imagePath, corners);
    }
  }

  /// Apply a filter to an existing image using native OpenCV.
  /// Filters: 'color', 'grayscale', 'whiteboard', 'bw'
  Future<String> applyFilterNative(String imagePath, String filter) async {
    debugPrint('[DocsMind] Applying filter "$filter" to: $imagePath');
    try {
      final result = await _channel.invokeMethod('applyFilter', {
        'path': imagePath,
        'filter': filter,
      });
      final outputPath = result['outputPath'] as String?;
      if (outputPath != null && File(outputPath).existsSync()) {
        return outputPath;
      }
      return imagePath;
    } catch (e) {
      debugPrint('[DocsMind] ❌ applyFilterNative error: $e');
      return imagePath;
    }
  }

  // ─────────────────────────────────────────────
  //  Dart Fallback: Crop to Bounding Box
  // ─────────────────────────────────────────────

  /// Crop the image to the bounding box of the provided corners.
  /// Used as fallback when native processing is unavailable.
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
  Future<String?> buildPdfFromImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return null;
    try {
      final pdf = pw.Document();

      for (final path in imagePaths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.FittedBox(
                fit: pw.BoxFit.contain,
                child: pw.Image(image),
              ),
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

  // ─────────────────────────────────────────────
  //  Edge Detection (Dart fallback)
  // ─────────────────────────────────────────────

  /// Detect document edges from image using pure Dart (no ML Kit / native).
  /// Returns a DetectedDocument with corner information (proportional 0–1).
  Future<DetectedDocument?> detectDocumentEdges(String imagePath) async {
    debugPrint('[DocsMind] detectDocumentEdges (Dart) → path=$imagePath');
    final stopwatch = Stopwatch()..start();

    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('[DocsMind]   ❌ File does not exist');
        return _fallbackDocument(imagePath, false);
      }

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        debugPrint('[DocsMind]   ❌ Failed to decode image');
        return _fallbackDocument(imagePath, false);
      }

      debugPrint(
          '[DocsMind]   Image decoded: ${decoded.width}x${decoded.height}');
      final corners = _detectDocumentCorners(decoded);
      final isDetected = corners != null && corners.length >= 4;

      stopwatch.stop();
      debugPrint(
          '[DocsMind]   ${isDetected ? "✅ Document detected" : "⚠️ No document found"} (${stopwatch.elapsedMilliseconds}ms)');

      return DetectedDocument(
        originalPath: imagePath,
        croppedPath: imagePath,
        corners: isDetected ? corners : _getDefaultDocumentCorners(),
        isDetected: isDetected,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '[DocsMind]   ❌ Edge detection error (${stopwatch.elapsedMilliseconds}ms): $e');
      return _fallbackDocument(imagePath, false);
    }
  }

  // ─────────────────────────────────────────────
  //  Edge Detection (Native OpenCV)
  // ─────────────────────────────────────────────

  /// Detect document edges from image using native OpenCV.
  /// Returns a DetectedDocument with corner information (proportional 0–1).
  Future<DetectedDocument?> detectDocumentEdgesNative(String imagePath) async {
    debugPrint(
        '[DocsMind] detectDocumentEdgesNative (OpenCV) → path=$imagePath');
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _channel
          .invokeMethod('detectDocumentEdges', {'path': imagePath});
      stopwatch.stop();

      if (result == null || result['isDetected'] != true) {
        debugPrint(
            '[DocsMind]   ⚠️ Native OpenCV: no document detected (${stopwatch.elapsedMilliseconds}ms)');
        return _fallbackDocument(imagePath, false);
      }

      final corners = (result['corners'] as List)
          .map<Offset>(
              (c) => Offset((c[0] as num).toDouble(), (c[1] as num).toDouble()))
          .toList();

      debugPrint(
          '[DocsMind]   ✅ Native OpenCV: document detected (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('[DocsMind]   Corners: $corners');

      return DetectedDocument(
        originalPath: imagePath,
        croppedPath: imagePath,
        corners: corners,
        isDetected: true,
      );
    } on MissingPluginException {
      stopwatch.stop();
      debugPrint(
          '[DocsMind]   ❌ Native OpenCV: MethodChannel not available (${stopwatch.elapsedMilliseconds}ms)');
      return _fallbackDocument(imagePath, false);
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '[DocsMind]   ❌ Native OpenCV error (${stopwatch.elapsedMilliseconds}ms): $e');
      return _fallbackDocument(imagePath, false);
    }
  }

  // ─────────────────────────────────────────────
  //  Live Camera Detection
  // ─────────────────────────────────────────────

  /// Simple live detection result used during camera preview.
  LiveDetectionResult? detectDocumentInCameraImageLive(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final bytesPerRow = plane.bytesPerRow;
    return detectDocumentInFrameLive(
      plane.bytes,
      image.width,
      image.height,
      bytesPerRow: bytesPerRow > 0 ? bytesPerRow : null,
    );
  }

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
    // For each row, find leftmost and rightmost edge pixel
    // For each column, find topmost and bottommost edge pixel
    const scanMargin = 3; // skip outer 3 pixels (camera noise)

    // Find top boundary: scan from top down for each column
    final topEdge = List<int>.filled(rw, rh);
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      for (int y = scanMargin; y < rh - scanMargin; y++) {
        if (edge[y][x]) {
          topEdge[x] = y;
          break;
        }
      }
    }

    // Find bottom boundary: scan from bottom up for each column
    final bottomEdge = List<int>.filled(rw, 0);
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      for (int y = rh - scanMargin - 1; y >= scanMargin; y--) {
        if (edge[y][x]) {
          bottomEdge[x] = y;
          break;
        }
      }
    }

    // Find left boundary: scan from left to right for each row
    final leftEdge = List<int>.filled(rh, rw);
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      for (int x = scanMargin; x < rw - scanMargin; x++) {
        if (edge[y][x]) {
          leftEdge[y] = x;
          break;
        }
      }
    }

    // Find right boundary: scan from right to left for each row
    final rightEdge = List<int>.filled(rh, 0);
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      for (int x = rw - scanMargin - 1; x >= scanMargin; x--) {
        if (edge[y][x]) {
          rightEdge[y] = x;
          break;
        }
      }
    }

    // Step 8: Find the document quad by looking for consistent edge regions
    // Use median-based approach to filter out noise

    // Filter valid top edge values (ignore columns with no edge found)
    final validTop = <int>[];
    final validTopX = <int>[];
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      if (topEdge[x] < rh - scanMargin) {
        validTop.add(topEdge[x]);
        validTopX.add(x);
      }
    }

    final validBottom = <int>[];
    final validBottomX = <int>[];
    for (int x = scanMargin; x < rw - scanMargin; x++) {
      if (bottomEdge[x] > scanMargin) {
        validBottom.add(bottomEdge[x]);
        validBottomX.add(x);
      }
    }

    final validLeft = <int>[];
    final validLeftY = <int>[];
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      if (leftEdge[y] < rw - scanMargin) {
        validLeft.add(leftEdge[y]);
        validLeftY.add(y);
      }
    }

    final validRight = <int>[];
    final validRightY = <int>[];
    for (int y = scanMargin; y < rh - scanMargin; y++) {
      if (rightEdge[y] > scanMargin) {
        validRight.add(rightEdge[y]);
        validRightY.add(y);
      }
    }

    // Need enough edge data from all 4 sides
    if (validTop.length < 10 ||
        validBottom.length < 10 ||
        validLeft.length < 10 ||
        validRight.length < 10) {
      debugPrint('[DocsMind] Not enough edge data from all 4 sides');
      return null;
    }

    // Sort to find median values
    validTop.sort();
    validBottom.sort();
    validLeft.sort();
    validRight.sort();

    // Use the 25th and 75th percentile to find robust edge positions
    final topY = validTop[(validTop.length * 0.25).round()];
    final bottomY = validBottom[(validBottom.length * 0.75).round()];
    final leftX = validLeft[(validLeft.length * 0.25).round()];
    final rightX = validRight[(validRight.length * 0.75).round()];

    // Validate: document must be at least 15% of image in each dimension
    final docW = rightX - leftX;
    final docH = bottomY - topY;
    if (docW < rw * 0.15 || docH < rh * 0.15) {
      debugPrint(
          '[DocsMind] Detected region too small: ${docW}x$docH in ${rw}x$rh');
      return null;
    }

    // Step 9: Refine corners by scanning the actual edge near each corner
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

    // Validate: area of quad must be reasonable
    final area = _quadArea(corners);
    if (area < 0.05 || area > 0.98) {
      debugPrint('[DocsMind] Quad area out of range: $area');
      return null;
    }

    debugPrint(
        '[DocsMind] ✅ Detected corners: $corners (area=${area.toStringAsFixed(3)})');
    return corners;
  }

  /// Refine X coordinate of a corner by looking at edge values in a Y range.
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
    // Use median for robustness
    return values[values.length ~/ 2].toDouble();
  }

  /// Refine Y coordinate of a corner by looking at edge values in an X range.
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

  /// Calculate area of a normalized quadrilateral (Shoelace formula).
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

  DetectedDocument _fallbackDocument(String imagePath, bool useDefaultCorners) {
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
