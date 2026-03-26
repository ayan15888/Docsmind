import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';

class _BWColors {
  static const Color black = Colors.black;
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color white = Colors.white;
}

/// Top bar with flash control only.
class CameraControlBar extends ConsumerWidget {
  const CameraControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(cameraControllerProvider);
    final flashMode = ref.watch(cameraFlashModeProvider);
    final hasController = controllerAsync.valueOrNull != null;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _BWColors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: _BWColors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: _FlashButton(flashMode: flashMode, enabled: hasController),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashButton extends ConsumerWidget {
  final FlashMode flashMode;
  final bool enabled;
  const _FlashButton({required this.flashMode, required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (flashMode) {
      FlashMode.off => Icons.flash_off_rounded,
      FlashMode.auto => Icons.flash_auto_rounded,
      FlashMode.always => Icons.flash_on_rounded,
      FlashMode.torch => Icons.flashlight_on_rounded,
    };
    final label = switch (flashMode) {
      FlashMode.off => 'Off',
      FlashMode.auto => 'Auto',
      FlashMode.always => 'On',
      FlashMode.torch => 'Torch',
    };
    final isActive = flashMode != FlashMode.off;
    
    final color = isActive ? _BWColors.white : _BWColors.lightGray.withValues(alpha: 0.6);

    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              final next = switch (flashMode) {
                FlashMode.off => FlashMode.auto,
                FlashMode.auto => FlashMode.always,
                FlashMode.always => FlashMode.torch,
                FlashMode.torch => FlashMode.off,
              };
              ref.read(cameraFlashModeProvider.notifier).state = next;
              unawaited(ref.read(cameraControllerProvider).valueOrNull?.setFlashMode(next));
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
