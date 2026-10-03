import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'image_filters.dart';

// ─────────────────────────────────────────────
//  Filter Thumbnail Bar (GPU Accelerated)
// ─────────────────────────────────────────────
class FilterBar extends StatelessWidget {
  final ImageFilterType selected;
  final String sourcePath;
  final ValueChanged<ImageFilterType> onSelect;

  const FilterBar({
    super.key,
    required this.selected,
    required this.sourcePath,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 116,
        color: AppColors.darkCard,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: ImageFilterType.values.length,
          itemBuilder: (context, index) {
            final type = ImageFilterType.values[index];
            final isActive = selected == type;
            final meta = filterMetaMap[type]!;

            return GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                onSelect(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 10),
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Thumbnail image rendered with instant GPU ColorFilter
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                        child: _buildThumbnail(type),
                      ),
                    ),
                    // Label strip
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.darkBg,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(13)),
                      ),
                      child: Center(
                        child: Text(
                          meta.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnail(ImageFilterType type) {
    final meta = filterMetaMap[type]!;
    final colorFilter = meta.colorFilter;

    Widget thumb = Image.file(
      File(sourcePath),
      cacheWidth: 140,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return Container(
          color: AppColors.darkSurfaceContainerHigh,
          child: const Center(
            child: Icon(Icons.photo_outlined,
                size: 20, color: AppColors.darkTextSecondary),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.darkSurfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.photo_outlined,
              size: 20, color: AppColors.darkTextSecondary),
        ),
      ),
    );

    if (colorFilter != null) {
      thumb = ColorFiltered(
        colorFilter: colorFilter,
        child: thumb,
      );
    }

    return thumb;
  }
}
