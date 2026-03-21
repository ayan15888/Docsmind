import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════
//  Black & White Color Palette (shared)
// ══════════════════════════════════════════
class _BWColors {
  static const Color black = Colors.black;
  static const Color darkGray = Color(0xFF222222);
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color white = Colors.white;
}

/// Bottom action buttons: Discard, Capture, Keep — minimalist B&W style.
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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding:
            const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              _BWColors.black.withValues(alpha: 0.7),
              _BWColors.black.withValues(alpha: 0.95),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Discard button
            _BWSmallButton(
              icon: Icons.close_rounded,
              label: 'Discard',
              color: _BWColors.lightGray,
              onPressed: onDiscard,
            ),

            // Center capture button
            _BWCaptureButton(onPressed: onCapture),

            // Keep scanning button
            _BWSmallButton(
              icon: Icons.check_rounded,
              label: 'Done',
              color: _BWColors.white,
              onPressed: onKeepScanning,
            ),
          ],
        ),
      ),
    );
  }
}

/// The big black & white capture button with concentric rings
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
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _BWColors.white.withValues(alpha: 0.15),
                Colors.transparent,
              ],
              radius: 1.5,
            ),
          ),
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
                      color: _BWColors.white.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Inner ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _BWColors.lightGray.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              // Center button
              Container(
                width: 56,
                height: 56,
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
                      color: _BWColors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.circle,
                  color: _BWColors.darkGray.withValues(alpha: 0.6),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small B&W action button (discard / keep)
class _BWSmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _BWSmallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: _BWColors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
