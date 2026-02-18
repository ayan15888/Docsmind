import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/constants/app_constants.dart';

/// Bottom action buttons: Discard (left), Capture FAB (center), Keep scanning (right).
class CameraActionButtons extends StatelessWidget {
  const CameraActionButtons({
    super.key,
    required this.onCapture,
    required this.onDiscard,
    required this.onKeepScanning,
  });

  final VoidCallback onCapture;
  final VoidCallback onDiscard;
  final VoidCallback onKeepScanning;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              _DiscardButton(onPressed: onDiscard),
              const Spacer(),
              _CaptureFAB(onPressed: onCapture),
              const Spacer(),
              _KeepScanningButton(onPressed: onKeepScanning),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscardButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DiscardButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.close,
      label: 'Discard',
      color: Colors.red,
      onPressed: onPressed,
    );
  }
}

class _KeepScanningButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _KeepScanningButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.check,
      label: 'Keep Scanning',
      color: Colors.green,
      onPressed: onPressed,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _CaptureFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.camera, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
