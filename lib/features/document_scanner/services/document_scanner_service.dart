import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class DocumentScannerService {
  static final DocumentScannerService _instance = DocumentScannerService._internal();

  factory DocumentScannerService() {
    return _instance;
  }

  DocumentScannerService._internal();

  static const int _maxSize = 500;
  static const int _edgeThreshold = 25;
  static const double _minDocAreaFraction = 0.03;

  /// Detect document edges from image using grayscale + Sobel + bounding box.
  /// Returns a DetectedDocument with corner information (proportional 0–1).
  Future<DetectedDocument?> detectDocumentEdges(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        return _fallbackDocument(imagePath, false);
      }

      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return _fallbackDocument(imagePath, false);
      }

      final corners = _detectDocumentCorners(decoded);
      final isDetected = corners != null && corners.length >= 4;

      return DetectedDocument(
        originalPath: imagePath,
        croppedPath: imagePath,
        corners: isDetected ? corners : _getDefaultDocumentCorners(),
        isDetected: isDetected,
      );
    } catch (e) {
      debugPrint('Edge detection error: $e');
      return _fallbackDocument(imagePath, false);
    }
  }

  /// Document detection from a camera frame. Uses Y plane (first plane) for speed.
  bool detectDocumentInCameraImage(CameraImage image) {
    if (image.planes.isEmpty) return false;
    final plane = image.planes.first;
    final bytesPerRow = plane.bytesPerRow;
    return detectDocumentInFrame(
      plane.bytes,
      image.width,
      image.height,
      bytesPerRow: bytesPerRow > 0 ? bytesPerRow : null,
    );
  }

  /// Quick document detection from camera Y plane (luminance). Returns true if a document-like region is detected.
  /// Use for auto-capture; [bytesPerRow] defaults to [width] (use when stride > width).
  bool detectDocumentInFrame(
    Uint8List yPlane,
    int width,
    int height, {
    int? bytesPerRow,
  }) {
    if (width < 40 || height < 40) return false;
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
      return false;
    }
    final corners = _detectDocumentCorners(gray);
    return corners != null && corners.length >= 4;
  }

  /// Run edge detection and find document bounding box; return 4 corners in 0–1 coords.
  List<Offset>? _detectDocumentCorners(img.Image source) {
    final w = source.width;
    final h = source.height;
    if (w < 10 || h < 10) return null;

    // Resize for speed
    final scale = _maxSize / (w > h ? w : h);
    final sw = (w * scale).round().clamp(50, w);
    final sh = (h * scale).round().clamp(50, h);
    img.Image resized = img.copyResize(source, width: sw, height: sh);
    final rw = resized.width;
    final rh = resized.height;

    // Grayscale then Sobel edges
    resized = img.grayscale(resized);
    resized = img.sobel(resized, amount: 1.0);

    // Collect strong edge points (optionally ignore outer 10% to reduce frame edges)
    const margin = 0.1;
    final xMin = (rw * margin).round();
    final xMax = (rw * (1 - margin)).round();
    final yMin = (rh * margin).round();
    final yMax = (rh * (1 - margin)).round();

    int minX = rw, maxX = 0, minY = rh, maxY = 0;
    int edgeCount = 0;

    for (int y = yMin; y < yMax; y++) {
      for (int x = xMin; x < xMax; x++) {
        final p = resized.getPixel(x, y);
        final luminance = img.getLuminanceRgb(p.r.toInt(), p.g.toInt(), p.b.toInt());
        if (luminance >= _edgeThreshold) {
          edgeCount++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (edgeCount < 50) return null;

    final boxW = maxX - minX + 1;
    final boxH = maxY - minY + 1;
    final areaFraction = (boxW * boxH) / (rw * rh);
    if (areaFraction < _minDocAreaFraction || boxW < 20 || boxH < 20) {
      return null;
    }

    // Map back to original image coordinates (proportional 0–1)
    final left = minX / rw;
    final right = maxX / rw;
    final top = minY / rh;
    final bottom = maxY / rh;

    // Add small margin and clamp
    const pad = 0.02;
    final l = (left - pad).clamp(0.0, 1.0);
    final r = (right + pad).clamp(0.0, 1.0);
    final t = (top - pad).clamp(0.0, 1.0);
    final b = (bottom + pad).clamp(0.0, 1.0);

    return [
      Offset(l, t),   // Top-left
      Offset(r, t),   // Top-right
      Offset(r, b),   // Bottom-right
      Offset(l, b),   // Bottom-left
    ];
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
      Offset(0.1, 0.12),   // Top-left
      Offset(0.9, 0.08),   // Top-right
      Offset(0.92, 0.9),   // Bottom-right
      Offset(0.08, 0.92),  // Bottom-left
    ];
  }
}

/// Represents a detected document with corner points
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
