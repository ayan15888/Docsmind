import 'package:flutter/material.dart';

/// Camera preview filter applied as an overlay (visual only; capture is unfiltered).
enum CameraFilterType {
  none,
  grayscale,
  sepia,
  warm,
  cool,
  vintage,
}

extension CameraFilterTypeX on CameraFilterType {
  String get label {
    switch (this) {
      case CameraFilterType.none:
        return 'None';
      case CameraFilterType.grayscale:
        return 'B&W';
      case CameraFilterType.sepia:
        return 'Sepia';
      case CameraFilterType.warm:
        return 'Warm';
      case CameraFilterType.cool:
        return 'Cool';
      case CameraFilterType.vintage:
        return 'Vintage';
    }
  }

  IconData get icon {
    switch (this) {
      case CameraFilterType.none:
        return Icons.filter_none;
      case CameraFilterType.grayscale:
        return Icons.filter_b_and_w;
      case CameraFilterType.sepia:
        return Icons.filter;
      case CameraFilterType.warm:
        return Icons.wb_sunny;
      case CameraFilterType.cool:
        return Icons.ac_unit;
      case CameraFilterType.vintage:
        return Icons.auto_fix_high;
    }
  }

  /// ColorFilter for overlay; null means no filter.
  ColorFilter? get colorFilter {
    switch (this) {
      case CameraFilterType.none:
        return null;
      case CameraFilterType.grayscale:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case CameraFilterType.sepia:
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);
      case CameraFilterType.warm:
        return const ColorFilter.matrix([
          1.1,  0.1,  0,    0, 0,
          0.1,  0.95, 0.05, 0, 0,
          0,    0.05, 0.9,  0, 0,
          0,    0,    0,    1, 0,
        ]);
      case CameraFilterType.cool:
        return const ColorFilter.matrix([
          0.9,  0.05, 0.05, 0, 0,
          0.05, 0.95, 0.1,  0, 0,
          0.1,  0.1,  1.1,  0, 0,
          0,    0,    0,    1, 0,
        ]);
      case CameraFilterType.vintage:
        return const ColorFilter.matrix([
          0.9,  0.4,  0.1,  0, 0,
          0.25, 0.75, 0.2,  0, 0,
          0.2,  0.3,  0.7,  0, 0,
          0,    0,    0,    1, 0,
        ]);
    }
  }
}
