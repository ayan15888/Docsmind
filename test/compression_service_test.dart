// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();

  group('CompressionResult Tests', () {
    test('calculates saved percentage correctly', () {
      const res = CompressionResult(
        outputPaths: ['/tmp/test.pdf'],
        originalTotalBytes: 1000,
        compressedTotalBytes: 400,
        format: 'PDF',
      );
      expect(res.savedPercentage, closeTo(60.0, 0.1));
    });

    test('clamps negative savings to 0%', () {
      const res = CompressionResult(
        outputPaths: ['/tmp/test.pdf'],
        originalTotalBytes: 500,
        compressedTotalBytes: 600,
        format: 'PDF',
      );
      expect(res.savedPercentage, equals(0.0));
    });
  });

  group('DocumentScannerService Compression Tests', () {
    late File testImageFile;

    setUp(() async {
      // Create a test image file
      final image = img.Image(width: 1200, height: 800);
      img.fill(image, color: img.ColorRgb8(200, 150, 100));
      for (int y = 0; y < 800; y += 40) {
        for (int x = 0; x < 1200; x += 40) {
          img.fillRect(image,
              x1: x,
              y1: y,
              x2: x + 20,
              y2: y + 20,
              color: img.ColorRgb8(50, 80, 220));
        }
      }
      final rawJpg = img.encodeJpg(image, quality: 90);
      final tempDir = Directory.systemTemp;
      testImageFile = File(
          '${tempDir.path}/test_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testImageFile.writeAsBytes(rawJpg);
    });

    tearDown(() async {
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
    });

    test('compress mixed files to PDF', () async {
      final service = DocumentScannerService();
      final result = await service.compressMixedFiles(
        [testImageFile.path],
        format: 'PDF',
        quality: 40,
        watermarkText: 'TEST WATERMARK',
      );

      expect(result, isNotNull);
      expect(result!.outputPaths.length, equals(1));
      expect(result.format, equals('PDF'));
      expect(File(result.outputPaths.first).existsSync(), isTrue);

      // Clean up output
      for (final p in result.outputPaths) {
        final f = File(p);
        if (await f.exists()) await f.delete();
      }
    });

    test('compress mixed files to JPEG', () async {
      final service = DocumentScannerService();
      final result = await service.compressMixedFiles(
        [testImageFile.path],
        format: 'JPEG',
        quality: 30,
      );

      expect(result, isNotNull);
      expect(result!.outputPaths.isNotEmpty, isTrue);
      expect(result.format, equals('JPEG'));
      expect(File(result.outputPaths.first).existsSync(), isTrue);

      // Clean up output
      for (final p in result.outputPaths) {
        final f = File(p);
        if (await f.exists()) await f.delete();
      }
    });
  });
}
