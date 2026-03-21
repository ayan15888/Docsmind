import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/features/camera/models/camera_filter.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';

// ══════════════════════════════════════════
//  Black & White Color Palette
// ══════════════════════════════════════════
class _BWColors {
  static const Color black = Colors.black;
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color white = Colors.white;
}

/// Top bar with flash, filter, and focus controls — B&W style.
class CameraControlBar extends ConsumerWidget {
  const CameraControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(cameraControllerProvider);
    final flashMode = ref.watch(cameraFlashModeProvider);
    final filter = ref.watch(cameraFilterProvider);
    final focusMode = ref.watch(cameraFocusModeProvider);
    final hasController = controllerAsync.valueOrNull != null;
    final autoCapture = ref.watch(cameraAutoCaptureProvider);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _BWColors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _BWColors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _BWColors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FlashButton(flashMode: flashMode, enabled: hasController),
            _BWDivider(),
            _FilterChip(filter: filter),
            _BWDivider(),
            _FocusButton(focusMode: focusMode, enabled: hasController),
            _BWDivider(),
            _AutoCaptureChip(enabled: hasController, isOn: autoCapture),
          ],
        ),
      ),
    );
  }
}

class _BWDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      decoration: BoxDecoration(
        color: _BWColors.white.withValues(alpha: 0.2),
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
    return _BWControlChip(
      icon: icon,
      label: label,
      isActive: isActive,
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
              unawaited(ref
                  .read(cameraControllerProvider)
                  .valueOrNull
                  ?.setFlashMode(next));
            }
          : null,
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final CameraFilterType filter;
  const _FilterChip({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BWControlChip(
      icon: filter.icon,
      label: filter.label,
      isActive: filter != CameraFilterType.none,
      onTap: () {
        HapticFeedback.lightImpact();
        final values = CameraFilterType.values;
        final i = values.indexOf(filter);
        ref.read(cameraFilterProvider.notifier).state =
            values[(i + 1) % values.length];
      },
    );
  }
}

class _FocusButton extends ConsumerWidget {
  final FocusMode focusMode;
  final bool enabled;
  const _FocusButton({required this.focusMode, required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuto = focusMode == FocusMode.auto;
    return _BWControlChip(
      icon: isAuto ? Icons.filter_center_focus : Icons.center_focus_strong,
      label: isAuto ? 'Auto' : 'Lock',
      isActive: !isAuto,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              final next = isAuto ? FocusMode.locked : FocusMode.auto;
              ref.read(cameraFocusModeProvider.notifier).state = next;
              unawaited(ref
                      .read(cameraControllerProvider)
                      .valueOrNull
                      ?.setFocusMode(next) ??
                  Future.value());
            }
          : null,
    );
  }
}

class _AutoCaptureChip extends ConsumerWidget {
  final bool enabled;
  final bool isOn;
  const _AutoCaptureChip({required this.enabled, required this.isOn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BWControlChip(
      icon: isOn ? Icons.auto_awesome : Icons.touch_app_outlined,
      label: isOn ? 'Auto' : 'Tap',
      isActive: isOn,
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(cameraAutoCaptureProvider.notifier).state = !isOn;
      },
    );
  }
}

class _BWControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _BWControlChip({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? _BWColors.white : _BWColors.lightGray.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
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
