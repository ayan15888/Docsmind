import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/core/providers.dart';

// ── Providers ──────────────────────────────────────────────────
final compressionQualityProvider = StateProvider<double>((ref) => 80.0);
final compressionFormatProvider = StateProvider<String>((ref) => 'JPEG');
final compressStatusProvider = StateProvider<String?>((ref) => null);

// ── Screen ─────────────────────────────────────────────────────
class CompressScreen extends ConsumerWidget {
  const CompressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quality = ref.watch(compressionQualityProvider);
    final format = ref.watch(compressionFormatProvider);
    final status = ref.watch(compressStatusProvider);
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: Text(
              'Compress',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quality Slider ─────────────────────────
                  _SectionCard(
                    title: 'Output Quality',
                    subtitle: 'Higher quality = larger file size',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quality',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${quality.round()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            thumbColor: AppColors.primary,
                            overlayColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            min: 10,
                            max: 100,
                            divisions: 9,
                            value: quality,
                            onChanged: (v) => ref
                                .read(compressionQualityProvider.notifier)
                                .state = v,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Smallest',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.grey.shade500)),
                            Text('Highest',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Format Picker ──────────────────────────
                  _SectionCard(
                    title: 'Output Format',
                    subtitle: 'Select the file format for compressed output',
                    child: Row(
                      children: ['JPEG', 'PNG', 'WEBP'].map((f) {
                        final selected = format == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(compressionFormatProvider.notifier)
                                .state = f,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                f,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Estimated Output ───────────────────────
                  _SectionCard(
                    title: 'Estimated Compression',
                    subtitle: 'Based on selected quality level',
                    child: _CompressionPreview(quality: quality),
                  ),

                  const SizedBox(height: 16),

                  // ── Documents to Compress ──────────────────
                  _SectionCard(
                    title: 'Scanned Documents',
                    subtitle: documents.isEmpty
                        ? 'No documents yet — scan some first'
                        : '${documents.length} document(s) ready to compress',
                    child: documents.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey.shade400, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Go to Documents tab and scan first',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ...documents.take(3).map((path) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _DocCompressRow(path: path),
                                  )),
                              if (documents.length > 3)
                                Text(
                                  '+ ${documents.length - 3} more',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 28),

                  // ── Compress Button ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.compress_rounded),
                      label: Text(
                        documents.isEmpty
                            ? 'No Documents to Compress'
                            : 'Compress All (${documents.length})',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: documents.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(compressStatusProvider.notifier)
                                  .state =
                                  '✅ Compressed ${documents.length} document(s) at ${quality.round()}% quality';
                            },
                    ),
                  ),

                  if (status != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CompressionPreview extends StatelessWidget {
  final double quality;
  const _CompressionPreview({required this.quality});

  @override
  Widget build(BuildContext context) {
    // Approximate size reduction heuristic
    final reduction = ((100 - quality) * 0.7).clamp(0.0, 70.0).round();
    return Row(
      children: [
        Expanded(
          child: _StatBlock(
            label: 'Size Reduction',
            value: '~$reduction%',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBlock(
            label: 'Quality Retained',
            value: '${quality.round()}%',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBlock(
            label: 'Speed',
            value: quality < 50 ? 'Fast' : quality < 80 ? 'Normal' : 'Slow',
            color: quality < 50 ? Colors.blue : Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DocCompressRow extends StatelessWidget {
  final String path;
  const _DocCompressRow({required this.path});

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last.split('\\').last;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 40,
              height: 40,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 20, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.compress_rounded, size: 16, color: Colors.grey.shade400),
      ],
    );
  }
}
