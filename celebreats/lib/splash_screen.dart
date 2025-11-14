import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Total duration of the animation sequence
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // Move logo from top center to center (first 20% = 1.2 seconds)
    _alignmentAnimation =
        AlignmentTween(
          begin: const Alignment(0.0, -1.0),
          end: Alignment.center,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.2, curve: Curves.easeInOut),
          ),
        );

    // Logo expands (from 3s to 5s)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Gradient fades in right after logo expansion (from 5s to 6s)
    _gradientFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate to Get Started screen after full animation completes
    Timer(const Duration(seconds: 6), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/getStarted');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to rebuild background opacity and allow AlignTransition/ScaleTransition to animate
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // White background before gradient appears
              Container(color: Colors.white),

              // Gradient background (fades in after expansion)
              Opacity(
                opacity: _gradientFadeAnimation.value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF5F6D), // reddish top
                        Color(0xFFFFC371), // orange bottom
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Animated logo: keeps horizontally centered while moving down
              AlignTransition(
                alignment: _alignmentAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 140,
                    height: 140,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
