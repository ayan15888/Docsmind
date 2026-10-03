import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

// ─────────────────────────────────────────────
//  Filter Types & Metadata
// ─────────────────────────────────────────────
enum ImageFilterType {
  original,
  magic, // Auto-enhanced document scan
  grayscale, // Classic greyscale
  blackWhite, // High-contrast B&W document
  vivid, // Punchy vivid colours
  warm, // Warm temperature boost
}

class FilterMeta {
  final String label;
  final String emoji;
  final String description;
  final ColorFilter? colorFilter;

  const FilterMeta(this.label, this.emoji, this.description,
      [this.colorFilter]);
}

const filterMetaMap = {
  ImageFilterType.original: FilterMeta(
    'Original',
    '',
    'No changes',
    null,
  ),
  ImageFilterType.magic: FilterMeta(
    'Magic',
    '',
    'Auto enhance',
    ColorFilter.matrix([
      1.22,
      -0.06,
      -0.06,
      0,
      8,
      -0.06,
      1.22,
      -0.06,
      0,
      8,
      -0.06,
      -0.06,
      1.22,
      0,
      8,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  ImageFilterType.grayscale: FilterMeta(
    'Grayscale',
    '',
    'Grey tones',
    ColorFilter.matrix([
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  ImageFilterType.blackWhite: FilterMeta(
    'B&W Doc',
    '',
    'Document black & white',
    ColorFilter.matrix([
      0.2126 * 2.8,
      0.7152 * 2.8,
      0.0722 * 2.8,
      0,
      -115,
      0.2126 * 2.8,
      0.7152 * 2.8,
      0.0722 * 2.8,
      0,
      -115,
      0.2126 * 2.8,
      0.7152 * 2.8,
      0.0722 * 2.8,
      0,
      -115,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  ImageFilterType.vivid: FilterMeta(
    'Vivid',
    '',
    'Boost colours',
    ColorFilter.matrix([
      1.40,
      -0.20,
      -0.20,
      0,
      0,
      -0.20,
      1.40,
      -0.20,
      0,
      0,
      -0.20,
      -0.20,
      1.40,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  ImageFilterType.warm: FilterMeta(
    'Warm',
    '',
    'Warm tones',
    ColorFilter.matrix([
      1.18,
      0,
      0,
      0,
      12,
      0,
      1.04,
      0,
      0,
      4,
      0,
      0,
      0.84,
      0,
      -10,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
};

// ─────────────────────────────────────────────
//  Image Processing (Optimized for performance)
// ─────────────────────────────────────────────
class ImageFilters {
  /// Build thumbnail previews for all filters from [sourcePath].
  static Future<Map<ImageFilterType, String>> buildAllThumbnails(
      String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final src = img.decodeImage(bytes);
    if (src == null) return {};

    final thumb = img.copyResize(src, width: 140);
    final results = <ImageFilterType, String>{};
    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;

    for (final type in ImageFilterType.values) {
      final processed = apply(thumb, type);
      final outBytes = img.encodeJpg(processed, quality: 75);
      final f = File('${tempDir.path}/thumb_${type.name}_$ts.jpg');
      await f.writeAsBytes(outBytes);
      results[type] = f.path;
    }
    return results;
  }

  /// Apply [filter] to full-resolution image at [sourcePath].
  /// Returns the path to the processed temp file.
  static Future<String> processFullImage(Map<String, dynamic> args) async {
    final String path = args['path'];
    final ImageFilterType filter = args['filter'];

    if (filter == ImageFilterType.original) return path;

    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Failed to decode image');

    final processed = apply(decoded, filter);
    final outBytes = img.encodeJpg(processed, quality: 90);
    final tempDir = Directory.systemTemp;
    final out = File(
        '${tempDir.path}/filtered_${filter.name}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await out.writeAsBytes(outBytes);
    return out.path;
  }

  /// Pure filter logic — optimized direct pixel adjustments without slow convolutions.
  static img.Image apply(img.Image src, ImageFilterType filter) {
    switch (filter) {
      case ImageFilterType.original:
        return src;

      case ImageFilterType.magic:
        // Fast auto-enhance: boosted contrast + subtle brightness + saturation lift
        return img.adjustColor(
          src,
          contrast: 1.25,
          brightness: 1.05,
          saturation: 1.12,
        );

      case ImageFilterType.grayscale:
        // Fast grayscale
        return img.grayscale(src);

      case ImageFilterType.blackWhite:
        // Fast high-contrast B&W document thresholding
        final gray = img.grayscale(src);
        return img.adjustColor(
          gray,
          contrast: 2.8,
          brightness: 1.12,
        );

      case ImageFilterType.vivid:
        // Fast saturation boost
        return img.adjustColor(
          src,
          saturation: 1.5,
          contrast: 1.15,
          brightness: 1.02,
        );

      case ImageFilterType.warm:
        // Fast warm paper tone
        return img.adjustColor(
          src,
          gamma: 1.04,
          brightness: 1.04,
          contrast: 1.05,
          amount: 1.0,
        );
    }
  }
}
