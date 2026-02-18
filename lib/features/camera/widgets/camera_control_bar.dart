import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/features/camera/models/camera_filter.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';

/// Top bar with flash, filter, and focus controls.
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FlashButton(flashMode: flashMode, enabled: hasController),
            _FilterChip(filter: filter),
            _FocusButton(focusMode: focusMode, enabled: hasController),
            _AutoCaptureChip(enabled: hasController, isOn: autoCapture),
          ],
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
      FlashMode.off => Icons.flash_off,
      FlashMode.auto => Icons.flash_auto,
      FlashMode.always => Icons.flash_on,
      FlashMode.torch => Icons.flashlight_on,
    };
    final label = switch (flashMode) {
      FlashMode.off => 'Off',
      FlashMode.auto => 'Auto',
      FlashMode.always => 'On',
      FlashMode.torch => 'Torch',
    };
    return _ControlChip(
      icon: icon,
      label: label,
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
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final CameraFilterType filter;

  const _FilterChip({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ControlChip(
      icon: filter.icon,
      label: filter.label,
      onTap: () {
        HapticFeedback.lightImpact();
        final values = CameraFilterType.values;
        final i = values.indexOf(filter);
        ref.read(cameraFilterProvider.notifier).state = values[(i + 1) % values.length];
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
    return _ControlChip(
      icon: isAuto ? Icons.filter_center_focus : Icons.filter_center_focus_rounded,
      label: isAuto ? 'Auto' : 'Locked',
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              final next = isAuto ? FocusMode.locked : FocusMode.auto;
              ref.read(cameraFocusModeProvider.notifier).state = next;
              unawaited(ref.read(cameraControllerProvider).valueOrNull?.setFocusMode(next) ?? Future.value());
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
    return _ControlChip(
      icon: isOn ? Icons.document_scanner : Icons.camera_alt_outlined,
      label: isOn ? 'Auto' : 'Manual',
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(cameraAutoCaptureProvider.notifier).state = !isOn;
      },
    );
  }
}

class _ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ControlChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

