import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// holds the last captured image path (or null if none)
final cameraPathProvider = StateProvider<String?>((ref) => null);

// holds the current captured XFile from camera (for preview before save)
final capturedImageProvider = StateProvider<XFile?>((ref) => null);
