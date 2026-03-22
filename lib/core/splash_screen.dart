import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Slide animation
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    // Start animation
    _animationController.forward();

    // Navigate to home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuart,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.appName,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CaterpillarAnimation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CaterpillarAnimation extends StatefulWidget {
  const CaterpillarAnimation({Key? key}) : super(key: key);

  @override
  State<CaterpillarAnimation> createState() => _CaterpillarAnimationState();
}

class _CaterpillarAnimationState extends State<CaterpillarAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Curve the linear value slightly for a smooth startup and stop
        final double value = _controller.value;
        // Head moves across the box
        final double headX = -40 + (value * 280);
        final bool foodEaten = headX >= 135;
        final int segmentsCount = foodEaten ? 6 : 5;

        return SizedBox(
          width: 240,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The Food Pixel
              if (!foodEaten)
                Positioned(
                  left: 140,
                  top: 32,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 0, 0, 0), // green pixel food
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              // The Caterpillar Pixels
              for (int i = 0; i < segmentsCount; i++)
                Positioned(
                  left: headX - (i * 24),
                  // Smooth continuous crawling arch effect mapping sine from -1..1 to 0..1
                  top: 24 - ((math.sin(value * math.pi * 16 - (i * 0.6)) + 1.0) / 2.0 * 12.0),
                  child: i == 0
                      ? CustomPaint(
                          size: const Size(28, 28),
                          painter: HeadPainter(
                            // Smooth continuous mouth chomp! Map sine to 0.0 -> maxAngle
                            mouthAngle: value >= 1.0 
                                ? 0 
                                : ((math.sin(value * math.pi * 24) + 1.0) / 2.0 * (math.pi / 2.5)),
                            color: AppColors.primary,
                          ),
                        )
                      : Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: i.isEven ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class HeadPainter extends CustomPainter {
  final double mouthAngle;
  final Color color;

  HeadPainter({required this.mouthAngle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2);
    // Arc for mouth facing right
    canvas.drawArc(rect, mouthAngle / 2, 2 * math.pi - mouthAngle, true, paint);

    // Give it a tiny eye
    final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.25), size.width * 0.12, eyePaint);
  }

  @override
  bool shouldRepaint(HeadPainter oldDelegate) => 
      oldDelegate.mouthAngle != mouthAngle || oldDelegate.color != color;
}
