import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';
import 'image_filters.dart';
import 'filter_bar.dart';
import 'ocr_result_sheet.dart';

// ─────────────────────────────────────────────
//  Document Editor Screen
// ─────────────────────────────────────────────
class DocumentEditorScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const DocumentEditorScreen({super.key, required this.imagePath});

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  ImageFilterType _selectedFilter = ImageFilterType.original;
  bool _isSaving = false;
  bool _isRunningOcr = false;

  // Cached full-resolution processed image (if generated for OCR or saving)
  String? _cachedFilteredPath;
  ImageFilterType? _cachedFilterType;

  OcrResult? _ocrResult;

  void _onFilterSelect(ImageFilterType filterType) {
    if (filterType == _selectedFilter) return;
    setState(() {
      _selectedFilter = filterType;
      _ocrResult = null; // reset cached OCR if filter changes
    });
  }

  /// Returns full-resolution processed image file path for the active filter.
  Future<String> _getOrProcessFilteredImagePath() async {
    if (_selectedFilter == ImageFilterType.original) {
      return widget.imagePath;
    }

    if (_cachedFilteredPath != null &&
        _cachedFilterType == _selectedFilter &&
        await File(_cachedFilteredPath!).exists()) {
      return _cachedFilteredPath!;
    }

    final processedPath = await compute(
      ImageFilters.processFullImage,
      {'path': widget.imagePath, 'filter': _selectedFilter},
    );

    _cachedFilteredPath = processedPath;
    _cachedFilterType = _selectedFilter;
    return processedPath;
  }

  Future<void> _saveAndReplace() async {
    if (_selectedFilter == ImageFilterType.original) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final processedPath = await _getOrProcessFilteredImagePath();
      final processedFile = File(processedPath);

      if (await processedFile.exists()) {
        final outBytes = await processedFile.readAsBytes();
        await File(widget.imagePath).writeAsBytes(outBytes);

        // Invalidate Flutter image cache so other screens show updated image
        await FileImage(File(widget.imagePath)).evict();

        // Clean up temporary isolate file
        if (processedPath != widget.imagePath) {
          try {
            await processedFile.delete();
          } catch (_) {}
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Runs MLKit OCR and opens the standard text scanner UI sheet.
  Future<void> _extractText() async {
    if (_isRunningOcr || _isSaving) return;

    // If we already have OCR results for this image, open directly
    if (_ocrResult != null) {
      AppHaptics.selectionClick();
      OcrResultSheet.show(context, _ocrResult!);
      return;
    }

    setState(() => _isRunningOcr = true);

    try {
      final scanner = ref.read(documentScannerProvider);
      final path = await _getOrProcessFilteredImagePath();
      final result = await scanner.recognizeText(path);

      if (!mounted) return;

      if (!result.hasText) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No text detected in this document',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        return;
      }

      AppHaptics.mediumImpact();
      setState(() => _ocrResult = result);

      if (mounted) {
        OcrResultSheet.show(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e'),
            backgroundColor: AppColors.googleRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningOcr = false);
    }
  }

  Widget _buildFilteredPreview() {
    final meta = filterMetaMap[_selectedFilter];
    final colorFilter = meta?.colorFilter;

    Widget imageWidget = Image.file(
      File(widget.imagePath),
      key: ValueKey(widget.imagePath),
      fit: BoxFit.contain,
    );

    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: colorFilter,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDocumentViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildFilteredPreview(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Document',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          // ── Text Scanner / OCR Action ──
          AnimatedOpacity(
            opacity: (_isSaving || _isRunningOcr) ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: _isRunningOcr
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.text_fields_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    tooltip: 'Extract Text',
                    onPressed:
                        (_isSaving || _isRunningOcr) ? null : _extractText,
                  ),
          ),
          // ── Minimalist Flat Save Button ──
          AnimatedOpacity(
            opacity: _isSaving ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(right: 14, left: 4),
              child: FilledButton(
                onPressed: _isSaving ? null : _saveAndReplace,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dark document background
          Container(color: AppColors.darkBg),

          // Pinch-to-zoom image viewer
          _buildDocumentViewer(),

          // Saving overlay
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Saving document...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // OCR Processing overlay
          if (_isRunningOcr)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scanning document text...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: FilterBar(
        selected: _selectedFilter,
        sourcePath: widget.imagePath,
        onSelect: _onFilterSelect,
      ),
    );
  }
}
