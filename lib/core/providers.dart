import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';

// holds the last captured image path (or null if none)
final cameraPathProvider = StateProvider<String?>((ref) => null);

// holds the current captured XFile from camera (for preview before save)
final capturedImageProvider = StateProvider<XFile?>((ref) => null);

// stores the last document edge detection result for the captured image
final lastScanResultProvider = StateProvider<DetectedDocument?>((ref) => null);

// holds dark mode state
final darkModeProvider = StateProvider<bool>((ref) => false);

// holds camera initialization state
final cameraInitializedProvider = StateProvider<bool>((ref) => false);

// holds image list for documents
final documentsProvider = StateProvider<List<String>>((ref) => []);

// paths of scans the user tapped "Keep" on (for stack display on camera screen)
final keptScannedDocumentsProvider = StateProvider<List<String>>((ref) => []);

// holds loading state for capture operation
final isCapturingProvider = StateProvider<bool>((ref) => false);

// holds error state
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Document scanner service
final documentScannerProvider = Provider((ref) => DocumentScannerService());

// ─────────────────────────────────────────────
//  OpenCV Connection Status Provider
// ─────────────────────────────────────────────

/// Checks OpenCV native library availability on startup.
/// Returns an [OpenCVStatus] with connection details.
final opencvStatusProvider = FutureProvider<OpenCVStatus>((ref) async {
  final scanner = ref.read(documentScannerProvider);
  return scanner.checkOpenCVConnection();
});
