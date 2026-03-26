import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════
//  Black & White Color Palette (shared)
// ══════════════════════════════════════════
class _BWColors {
  static const Color black = Colors.black;
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color white = Colors.white;
}

/// Bottom action bar: Discard | Capture | Done — compact, icon-only.
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
            ),
            padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 18,
          bottom: bottomPad > 0 ? bottomPad + 8 : 20,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Discard — left side
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BWIconButton(
                  icon: Icons.close_rounded,
                  onPressed: onDiscard,
                  isDestructive: true,
                ),
              ),
            ),

            // Capture — perfectly centred
            _BWCaptureButton(onPressed: onCapture),

            // Done — right side
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _BWIconButton(
                  icon: Icons.check_rounded,
                  onPressed: onKeepScanning,
                  isDestructive: false,
                ),
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

// ══════════════════════════════════════════
//  Capture Button
// ══════════════════════════════════════════
class _BWCaptureButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _BWCaptureButton({required this.onPressed});

  @override
  State<_BWCaptureButton> createState() => _BWCaptureButtonState();
}

class _BWCaptureButtonState extends State<_BWCaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.heavyImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _BWColors.white.withValues(alpha: 0.8),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _BWColors.white.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Inner ring
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _BWColors.lightGray.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              ),
              // Solid centre disc
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _BWColors.lightGray,
                      _BWColors.white.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _BWColors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  Icon-only Action Button
// ══════════════════════════════════════════
class _BWIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _BWIconButton({
    required this.icon,
    required this.onPressed,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFFF5C5C)
        : _BWColors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
