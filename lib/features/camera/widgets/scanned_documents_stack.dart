import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/constants/app_constants.dart';

const int _kMaxVisible = 5;
const double _kCardWidth = 56;
const double _kCardHeight = 72;
const double _kStackOffset = 6;

/// Shows kept scanned documents as a stack of thumbnails. Tap to open gallery.
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

  void _openGallery(BuildContext context, WidgetRef ref) {
    final paths = ref.read(keptScannedDocumentsProvider);
    if (paths.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Scanned documents (${paths.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: paths.length,
                  itemBuilder: (_, i) {
                    final path = paths[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: File(path).existsSync()
                            ? Image.file(
                                File(path),
                                fit: BoxFit.contain,
                                height: 200,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Image not found', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
