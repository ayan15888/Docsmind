import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';

// ── Models & State Providers ────────────────────────────────────────────────
class SelectedFileItem {
  final String path;
  final String name;
  final int sizeBytes;
  final bool isPdf;

  const SelectedFileItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.isPdf,
  });
}

final selectedFilesProvider =
    StateProvider<List<SelectedFileItem>>((ref) => []);
final compressionQualityProvider = StateProvider<double>((ref) => 60.0);
final compressionFormatProvider = StateProvider<String>((ref) => 'PDF');
final watermarkTextProvider = StateProvider<String>((ref) => '');
final isCompressingProvider = StateProvider<bool>((ref) => false);
final compressStatusProvider = StateProvider<String?>((ref) => null);
final lastCompressionResultProvider =
    StateProvider<CompressionResult?>((ref) => null);

// ── Material Design 3 Compress Screen ───────────────────────────────────────
class CompressScreen extends ConsumerWidget {
  const CompressScreen({super.key});

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _pickFromGallery(WidgetRef ref, BuildContext context) async {
    try {
      AppHaptics.selectionClick();
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage();

      if (pickedList.isNotEmpty) {
        final newItems = <SelectedFileItem>[];
        for (final xf in pickedList) {
          final f = File(xf.path);
          if (await f.exists()) {
            final size = await f.length();
            final name = xf.name.isNotEmpty
                ? xf.name
                : xf.path.split(Platform.pathSeparator).last;
            newItems.add(SelectedFileItem(
              path: xf.path,
              name: name,
              sizeBytes: size,
              isPdf: false,
            ));
          }
        }
        if (newItems.isNotEmpty) {
          final current = ref.read(selectedFilesProvider);
          ref.read(selectedFilesProvider.notifier).state = [
            ...current,
            ...newItems
          ];
          ref.read(lastCompressionResultProvider.notifier).state = null;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _pickFromFiles(WidgetRef ref, BuildContext context) async {
    try {
      AppHaptics.selectionClick();
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final newItems = <SelectedFileItem>[];

        for (final file in result.files) {
          final filePath = file.path;
          if (filePath != null && File(filePath).existsSync()) {
            final f = File(filePath);
            final size = file.size > 0 ? file.size : await f.length();
            final name =
                file.name.isNotEmpty ? file.name : f.uri.pathSegments.last;
            final isPdf = name.toLowerCase().endsWith('.pdf') ||
                (file.extension?.toLowerCase() == 'pdf');
            newItems.add(SelectedFileItem(
              path: filePath,
              name: name,
              sizeBytes: size,
              isPdf: isPdf,
            ));
          }
        }

        if (newItems.isNotEmpty) {
          final current = ref.read(selectedFilesProvider);
          ref.read(selectedFilesProvider.notifier).state = [
            ...current,
            ...newItems
          ];
          ref.read(lastCompressionResultProvider.notifier).state = null;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick files: $e')),
        );
      }
    }
  }

  Future<void> _addScannedDocuments(WidgetRef ref, List<String> docs) async {
    AppHaptics.selectionClick();
    final newItems = <SelectedFileItem>[];
    final current = ref.read(selectedFilesProvider);
    final existingPaths = current.map((e) => e.path).toSet();

    for (final path in docs) {
      if (existingPaths.contains(path)) continue;
      final f = File(path);
      if (await f.exists()) {
        final size = await f.length();
        final name = path.split(Platform.pathSeparator).last;
        newItems.add(SelectedFileItem(
          path: path,
          name: name,
          sizeBytes: size,
          isPdf: name.toLowerCase().endsWith('.pdf'),
        ));
      }
    }

    ref.read(selectedFilesProvider.notifier).state = [...current, ...newItems];
    ref.read(lastCompressionResultProvider.notifier).state = null;
  }

  Future<void> _executeCompression(WidgetRef ref, BuildContext context) async {
    final selectedFiles = ref.read(selectedFilesProvider);
    if (selectedFiles.isEmpty) return;

    ref.read(isCompressingProvider.notifier).state = true;
    ref.read(compressStatusProvider.notifier).state = 'Compressing files...';
    ref.read(lastCompressionResultProvider.notifier).state = null;

    final quality = ref.read(compressionQualityProvider);
    final format = ref.read(compressionFormatProvider);
    final watermark = ref.read(watermarkTextProvider);

    try {
      final scanner = ref.read(documentScannerProvider);
      final filePaths = selectedFiles.map((e) => e.path).toList();

      final result = await scanner.compressMixedFiles(
        filePaths,
        format: format,
        quality: quality,
        watermarkText: watermark.trim(),
      );

      if (result != null && result.outputPaths.isNotEmpty) {
        ref.read(lastCompressionResultProvider.notifier).state = result;
        ref.read(compressStatusProvider.notifier).state =
            'Compression completed!';
        AppHaptics.heavyImpact();
      } else {
        ref.read(compressStatusProvider.notifier).state =
            'Failed to compress files. Please check file format and try again.';
        AppHaptics.lightImpact();
      }
    } catch (e) {
      ref.read(compressStatusProvider.notifier).state = 'Compression error: $e';
      AppHaptics.lightImpact();
    } finally {
      ref.read(isCompressingProvider.notifier).state = false;
    }
  }

  Future<void> _saveToDevice(
      BuildContext context, CompressionResult result) async {
    try {
      if (result.outputPaths.isEmpty) return;

      if (result.format == 'PDF' || result.outputPaths.length == 1) {
        final firstPath = result.outputPaths.first;
        final file = File(firstPath);
        if (!await file.exists()) {
          throw Exception('Compressed source file not found');
        }
        final bytes = await file.readAsBytes();
        final ext = result.format.toLowerCase();
        final defaultName =
            'docsmind_compressed_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final chosenPath = await FilePicker.saveFile(
          dialogTitle: 'Save Compressed Document',
          fileName: defaultName,
          type: result.format == 'PDF' ? FileType.custom : FileType.image,
          allowedExtensions:
              result.format == 'PDF' ? ['pdf'] : ['jpg', 'png', 'jpeg'],
          bytes: bytes,
        );

        if (chosenPath != null) {
          try {
            final dest = File(chosenPath);
            if (!chosenPath.startsWith('content://') && !await dest.exists()) {
              await dest.writeAsBytes(bytes, flush: true);
            }
          } catch (_) {}

          AppHaptics.heavyImpact();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved successfully!')),
            );
          }
        }
      } else {
        final targetDir = await FilePicker.getDirectoryPath(
          dialogTitle:
              'Select Folder to Save ${result.outputPaths.length} Images',
        );

        if (targetDir != null) {
          int savedCount = 0;
          for (int i = 0; i < result.outputPaths.length; i++) {
            final src = File(result.outputPaths[i]);
            if (await src.exists()) {
              final ext = result.format.toLowerCase();
              final destPath =
                  '$targetDir/compressed_page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$ext';
              await src.copy(destPath);
              savedCount++;
            }
          }

          AppHaptics.heavyImpact();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved $savedCount images to chosen folder!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final quality = ref.watch(compressionQualityProvider);
    final format = ref.watch(compressionFormatProvider);
    final isCompressing = ref.watch(isCompressingProvider);
    final status = ref.watch(compressStatusProvider);
    final selectedFiles = ref.watch(selectedFilesProvider);
    final lastResult = ref.watch(lastCompressionResultProvider);
    final scannedDocs = ref.watch(documentsProvider);

    final totalInputBytes =
        selectedFiles.fold<int>(0, (sum, item) => sum + item.sizeBytes);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Material 3 Pinned Top App Bar ──
          SliverAppBar(
            toolbarHeight: 96,
            title: Text(
              'Compress Files',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
                fontSize: 30,
              ),
            ),
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            pinned: false,
            floating: false,
            centerTitle: false,
            backgroundColor: colorScheme.primary,
            scrolledUnderElevation: 0,
            elevation: 0,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Source Selection Bar ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Add files to compress',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // 1. Photo Gallery
                      Expanded(
                        child: _M3SourceCard(
                          icon: Icons.photo_library_outlined,
                          containerColor: colorScheme.primaryContainer,
                          onContainerColor: colorScheme.onPrimaryContainer,
                          label: 'Gallery',
                          subtitle: 'Photos',
                          onTap: () => _pickFromGallery(ref, context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Storage / Files
                      Expanded(
                        child: _M3SourceCard(
                          icon: Icons.folder_open_rounded,
                          containerColor: colorScheme.secondaryContainer,
                          onContainerColor: colorScheme.onSecondaryContainer,
                          label: 'Files',
                          subtitle: 'PDFs & Docs',
                          onTap: () => _pickFromFiles(ref, context),
                        ),
                      ),
                      // 3. Scanned docs (if available)
                      if (scannedDocs.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _M3SourceCard(
                            icon: Icons.document_scanner_rounded,
                            containerColor: colorScheme.tertiaryContainer,
                            onContainerColor: colorScheme.onTertiaryContainer,
                            label: 'Scans',
                            subtitle: '${scannedDocs.length} pages',
                            onTap: () => _addScannedDocuments(ref, scannedDocs),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Selected Files Queue ──
                  _M3SectionCard(
                    title: 'Files Queue',
                    subtitle: selectedFiles.isEmpty
                        ? 'No files selected'
                        : '${selectedFiles.length} file(s) • ${formatBytes(totalInputBytes)}',
                    trailing: selectedFiles.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              AppHaptics.selectionClick();
                              ref.read(selectedFilesProvider.notifier).state =
                                  [];
                              ref
                                  .read(lastCompressionResultProvider.notifier)
                                  .state = null;
                            },
                            child: Text(
                              'Clear All',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                    child: selectedFiles.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.post_add_rounded,
                                    size: 40,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Choose images or PDFs above to compress',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < selectedFiles.length; i++)
                                _M3SelectedFileTile(
                                  item: selectedFiles[i],
                                  onDelete: () {
                                    AppHaptics.selectionClick();
                                    final list = List<SelectedFileItem>.from(
                                        selectedFiles)
                                      ..removeAt(i);
                                    ref
                                        .read(selectedFilesProvider.notifier)
                                        .state = list;
                                    ref
                                        .read(lastCompressionResultProvider
                                            .notifier)
                                        .state = null;
                                  },
                                ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // ── Compression Quality Slider ──
                  _M3SectionCard(
                    title: 'Target Quality',
                    subtitle:
                        'Balanced quality maintains high clarity with significant file size reduction',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${quality.toInt()}%',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                quality < 45
                                    ? 'Maximum Compression'
                                    : (quality > 75
                                        ? 'High Clarity'
                                        : 'Balanced Compression'),
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          min: 15,
                          max: 95,
                          divisions: 16,
                          value: quality,
                          onChanged: (v) => ref
                              .read(compressionQualityProvider.notifier)
                              .state = v,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Output Format Picker ──
                  _M3SectionCard(
                    title: 'Output Format',
                    subtitle: format == 'PDF'
                        ? 'Combine into a single multi-page PDF'
                        : 'Compress into separate $format image files',
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'PDF',
                            label: Text('PDF Document'),
                          ),
                          ButtonSegment(
                            value: 'JPEG',
                            label: Text('JPEG'),
                          ),
                          ButtonSegment(
                            value: 'PNG',
                            label: Text('PNG'),
                          ),
                        ],
                        selected: {format},
                        onSelectionChanged: (set) {
                          AppHaptics.selectionClick();
                          ref.read(compressionFormatProvider.notifier).state =
                              set.first;
                        },
                      ),
                    ),
                  ),

                  // ── Optional Watermark ──
                  if (format == 'PDF') ...[
                    const SizedBox(height: 16),
                    _M3SectionCard(
                      title: 'Watermark (Optional)',
                      subtitle: 'Stamp text diagonally across pages',
                      child: TextField(
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. CONFIDENTIAL, DRAFT, COPY',
                          hintStyle: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onChanged: (val) => ref
                            .read(watermarkTextProvider.notifier)
                            .state = val,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Compress Action Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: (selectedFiles.isEmpty || isCompressing)
                          ? null
                          : () => _executeCompression(ref, context),
                      child: isCompressing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              selectedFiles.isEmpty
                                  ? 'Select Files to Compress'
                                  : 'Compress ${selectedFiles.length} ${selectedFiles.length == 1 ? 'File' : 'Files'}',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  // ── Compression Result Card ──
                  if (lastResult != null) ...[
                    const SizedBox(height: 20),
                    _M3CompressionSuccessCard(
                      result: lastResult,
                      onSave: () => _saveToDevice(context, lastResult),
                    ),
                  ] else if (status != null && !isCompressing) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── M3 Source Selection Card ────────────────────────────────────────────────
class _M3SourceCard extends StatelessWidget {
  final IconData icon;
  final Color containerColor;
  final Color onContainerColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _M3SourceCard({
    required this.icon,
    required this.containerColor,
    required this.onContainerColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: containerColor,
                ),
                child: Icon(icon, color: onContainerColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── M3 Selected File Tile ───────────────────────────────────────────────────
class _M3SelectedFileTile extends StatelessWidget {
  final SelectedFileItem item;
  final VoidCallback onDelete;

  const _M3SelectedFileTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final file = File(item.path);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: item.isPdf
                  ? Container(
                      color: colorScheme.errorContainer,
                      child: Center(
                        child: Text(
                          'PDF',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : (file.existsSync()
                      ? Image.file(
                          file,
                          cacheWidth: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image, size: 20),
                        )
                      : const Icon(Icons.broken_image, size: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  CompressScreen.formatBytes(item.sizeBytes),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── M3 Section Container Card ───────────────────────────────────────────────
class _M3SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _M3SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ── M3 Compression Success Card ─────────────────────────────────────────────
class _M3CompressionSuccessCard extends StatelessWidget {
  final CompressionResult result;
  final VoidCallback onSave;

  const _M3CompressionSuccessCard({
    required this.result,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final savedPct = result.savedPercentage.round();

    return Card.outlined(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Compression Complete',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    savedPct > 0 ? '$savedPct% Saved' : 'Optimized',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _M3MetricItem(
                    label: 'Original Size',
                    value:
                        CompressScreen.formatBytes(result.originalTotalBytes),
                    isMuted: true,
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  _M3MetricItem(
                    label: 'Compressed Size',
                    value:
                        CompressScreen.formatBytes(result.compressedTotalBytes),
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSave,
                    child: const Text('Save to File'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      AppHaptics.heavyImpact();
                      Share.shareXFiles(
                        result.outputPaths.map((p) => XFile(p)).toList(),
                        text: 'Compressed with DocsMind',
                      );
                    },
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── M3 Metric Item ──────────────────────────────────────────────────────────
class _M3MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isMuted;
  final bool isHighlight;

  const _M3MetricItem({
    required this.label,
    required this.value,
    this.isMuted = false,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final valueColor = isHighlight
        ? colorScheme.tertiary
        : (isMuted ? colorScheme.outline : colorScheme.onSurface);

    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: isMuted ? TextDecoration.lineThrough : null,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
