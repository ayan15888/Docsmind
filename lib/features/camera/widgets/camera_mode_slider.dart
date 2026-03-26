import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';

class CameraModeSlider extends ConsumerWidget {
  const CameraModeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(cameraDocumentModeProvider);
    
    // We want to center the selected item, so we use a ListView or just a Row in a SingleChildScrollView.
    // For simplicity and perfect centering, a scrollable row with padding works well.
    return SizedBox(
      height: 40,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: DocumentMode.values.map((mode) {
                final isSelected = currentMode == mode;
                
                final label = switch (mode) {
                  DocumentMode.auto => 'AUTO',
                  DocumentMode.a4 => 'A4',
                  DocumentMode.a3 => 'A3',
                  DocumentMode.businessCard => 'BUSINESS CARD',
                };

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(cameraDocumentModeProvider.notifier).state = mode;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.yellow.shade600 : Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
