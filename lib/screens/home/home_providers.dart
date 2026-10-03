import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── State Providers for HomeScreen ──────────────────────────────────────────
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
final isGridViewProvider = StateProvider<bool>((ref) => true);
final documentSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedDocumentFilterProvider = StateProvider<String>((ref) => 'All');
