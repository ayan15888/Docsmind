import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/features/camera/widgets/document_preview_dialog.dart';

const int _kMaxVisible = 5;
const double _kCardWidth = 56;
const double _kCardHeight = 72;
const double _kStackOffset = 6;

// Shows kept scanned documents as a stack of thumbnails. Tap to open gallery.
class ScannedDocumentsStack extends ConsumerWidget {
  const ScannedDocumentsStack({super.key});
 @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(keptScannedDocumentsProvider);
    if (paths.isEmpty) return const SizedBox.shrink();

    final displayPaths = paths.length > _kMaxVisible ? paths.sublist(0, _kMaxVisible) : paths;
    return GestureDetector(
      onTap: () => _openGallery(context, ref),
      child: SizedBox(
        width: _kCardWidth + _kStackOffset * (displayPaths.length - 1) + 8,
        height: _kCardHeight + 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = displayPaths.length - 1; i >= 0; i--)
              Positioned(
                left: i * _kStackOffset,
                top: 4,
                child: _StackCard(
                  path: displayPaths[i],
                  index: i,
                  total: displayPaths.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, WidgetRef rootRef) {
    final initialPaths = rootRef.read(keptScannedDocumentsProvider);
    if (initialPaths.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final paths = ref.watch(keptScannedDocumentsProvider);
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
              child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scanned documents (${paths.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final scanner = ref.read(documentScannerProvider);
                        final pdfPath = await scanner.buildPdfFromImages(paths);
                        if (pdfPath == null) return;
                        await Share.shareXFiles(
                          [XFile(pdfPath)],
                          text: 'Scanned PDF',
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Share as PDF'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: paths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemBuilder: (_, i) {
                    final path = paths[i];
                    final file = File(path);
                    return _GridItem(
                      path: path,
                      exists: file.existsSync(),
                      onOpen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _FullScreenDocumentPager(
                              paths: paths,
                              initialIndex: i,
                            ),
                          ),
                        );
                      },
                      onEdit: () async {
                        if (!file.existsSync()) return;
                        final scanner = ref.read(documentScannerProvider);
                        final scan = await scanner.detectDocumentEdges(path);
                        // ignore: use_build_context_synchronously
                        await showDialog(
                          context: context,
                          builder: (context) => InteractivePreviewDialog(
                            image: XFile(path),
                            detectedDoc: scan,
                            onKeep: (corners) async {
                              final croppedPath = await scanner.cropToBoundingBox(path, corners);
                              if (!context.mounted) return;
                              // Update kept and documents lists with new path.
                              final kept = ref.read(keptScannedDocumentsProvider);
                              ref.read(keptScannedDocumentsProvider.notifier).state = [
                                for (final p in kept) if (p == path) croppedPath else p,
                              ];
                              final docs = ref.read(documentsProvider);
                              ref.read(documentsProvider.notifier).state = [
                                for (final p in docs) if (p == path) croppedPath else p,
                              ];
                              Navigator.pop(context);
                            },
                            onDiscard: () {
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      onDelete: () {
                        final current = ref.read(keptScannedDocumentsProvider);
                        ref.read(keptScannedDocumentsProvider.notifier).state =
                            current.where((p) => p != path).toList();
                        final docs = ref.read(documentsProvider);
                        ref.read(documentsProvider.notifier).state = docs.where((p) => p != path).toList();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),);
      },
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  final String path;
  final int index;
  final int total;

  const _StackCard({
    required this.path,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCardWidth,
      height: _kCardHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: File(path).existsSync()
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                width: _kCardWidth,
                height: _kCardHeight,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                ),
              )
            : const Center(
                child: Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
              ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final String path;
  final bool exists;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GridItem({
    required this.path,
    required this.exists,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: exists
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                'Edit',
                style: TextStyle(fontSize: 12),
              ),
            ),
            TextButton.icon(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                foregroundColor: Colors.red,
              ),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text(
                'Delete',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FullScreenDocumentPager extends StatelessWidget {
  final List<String> paths;
  final int initialIndex;

  const _FullScreenDocumentPager({
    required this.paths,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanned document'),
      ),
      body: PageView.builder(
        controller: controller,
        scrollDirection: Axis.vertical,
        itemCount: paths.length,
        itemBuilder: (_, index) {
          final path = paths[index];
          final file = File(path);
          if (!file.existsSync()) {
            return const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white, size: 48),
            );
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                file,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
