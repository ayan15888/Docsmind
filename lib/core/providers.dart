import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';

import 'package:flutter/material.dart';

// holds ThemeMode state (system, light, dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// holds legacy dark mode boolean state for backward compatibility
final darkModeProvider = StateProvider<bool>((ref) => false);

// holds image list for documents
final documentsProvider = StateProvider<List<String>>((ref) => []);

// holds error state
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Document scanner service
final documentScannerProvider = Provider((ref) => DocumentScannerService());
