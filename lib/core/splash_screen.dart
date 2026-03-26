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
        final double value = _controller.value;
        
        final double caterpillarStopValue = 0.60;
        final double bulletStartValue = 0.65;
        final double blastValue = 0.72;

        final double moveProgress = math.min(value, caterpillarStopValue) / caterpillarStopValue;
        final double headX = -40 + (moveProgress * 210); // max 170
        final bool foodEaten = value >= caterpillarStopValue;
        
        final bool shouldBlast = value >= blastValue;
        final double blastProgress = shouldBlast ? (value - blastValue) / (1.0 - blastValue) : 0.0;
        
        final double stickmanX = 270;
        final bool isShooting = value >= bulletStartValue && value < bulletStartValue + 0.08; 

        final double bulletProgress = value >= bulletStartValue && value < blastValue 
            ? (value - bulletStartValue) / (blastValue - bulletStartValue) 
            : 0.0;
        final double bulletX = stickmanX - 10 - (bulletProgress * (stickmanX - headX - 20));
        final bool showBullet = value >= bulletStartValue && value < blastValue;
        
        final int segmentsCount = foodEaten ? 6 : 5;

        return SizedBox(
          width: 320,
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Stickman
              Positioned(
                left: stickmanX,
                top: 25,
                child: CustomPaint(
                  size: const Size(30, 60),
                  painter: StickmanPainter(isShooting: isShooting),
                ),
              ),

              // The Food Pixel
              if (!foodEaten && !shouldBlast)
                Positioned(
                  left: 180,
                  top: 48,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 0, 0, 0),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // Bullet
              if (showBullet)
                Positioned(
                  left: bulletX,
                  top: 49,
                  child: Container(
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Caterpillar Normal
              if (!shouldBlast)
                for (int i = segmentsCount - 1; i >= 0; i--)
                  Positioned(
                    left: headX - (i * 24),
                    top: 40 - ((math.sin(value * math.pi * 16 - (i * 0.6)) + 1.0) / 2.0 * 12.0),
                    child: i == 0
                        ? CustomPaint(
                            size: const Size(28, 28),
                            painter: HeadPainter(
                              mouthAngle: foodEaten 
                                  ? ((math.sin(value * math.pi * 30) + 1.0) / 2.0 * (math.pi / 4)) 
                                  : ((math.sin(moveProgress * math.pi * 24) + 1.0) / 2.0 * (math.pi / 2.5)),
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

              // Blasted Particles
              if (shouldBlast)
                for (int i = 0; i < 6; i++)
                  for (int j = 0; j < 5; j++)
                    Builder(
                      builder: (context) {
                        int k = i * 5 + j;
                        double angle = k * math.pi * 2 / 30;
                        double distance = blastProgress * (80 + (k % 7) * 20) * 1.5;
                        double pX = (170 - i * 24) + distance * math.cos(angle);
                        double pY = 40 + distance * math.sin(angle) + (blastProgress * blastProgress * 120);
                        
                        return Positioned(
                          left: pX,
                          top: pY,
                          child: Transform.rotate(
                            angle: blastProgress * 20 * (j % 2 == 0 ? 1 : -1),
                            child: Container(
                              width: 10 * (1 - blastProgress * 0.5),
                              height: 10 * (1 - blastProgress * 0.5),
                              decoration: BoxDecoration(
                                color: (i == 0 || j % 2 == 0) 
                                    ? AppColors.primary 
                                    : AppColors.primary.withValues(alpha: 0.8),
                                shape: j % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                              ),
                            ),
                          ),
                        );
                      }
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

class StickmanPainter extends CustomPainter {
  final bool isShooting;

  StickmanPainter({required this.isShooting});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Head
    canvas.drawCircle(const Offset(15, 10), 8, paint);
    
    // Body
    canvas.drawLine(const Offset(15, 18), const Offset(15, 35), paint);
    
    // Legs
    canvas.drawLine(const Offset(15, 35), const Offset(5, 55), paint);
    canvas.drawLine(const Offset(15, 35), const Offset(25, 55), paint);
    
    // Arms holding gun
    if (isShooting) {
      // Arms pointing left
      canvas.drawLine(const Offset(15, 23), const Offset(-5, 24), paint);
      // Gun
      canvas.drawLine(const Offset(-5, 24), const Offset(-15, 24), paint..strokeWidth = 4);
      canvas.drawLine(const Offset(-5, 24), const Offset(-5, 28), paint..strokeWidth = 3);
      
      // Muzzle flash
      final flashPaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(-20, 24), 4, flashPaint);
      canvas.drawCircle(const Offset(-25, 24), 2, flashPaint);
    } else {
      // Resting arms
      canvas.drawLine(const Offset(15, 23), const Offset(5, 32), paint);
      // Gun pointing down/left
      canvas.drawLine(const Offset(5, 32), const Offset(-2, 40), paint..strokeWidth = 4);
    }
  }

  @override
  bool shouldRepaint(StickmanPainter oldDelegate) => oldDelegate.isShooting != isShooting;
}
