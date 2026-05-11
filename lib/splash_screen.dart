import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Logo drop-in from top
  late Animation<Alignment> _alignmentAnimation;

  // Logo fade-in at the start (NEW)
  late Animation<double> _logoFadeAnimation;

  // Logo scale-up explosion
  late Animation<double> _scaleAnimation;

  // White → gradient background fade
  late Animation<double> _gradientFadeAnimation;

  // Logo opacity fade-out as it scales (NEW — prevents harsh pixelation)
  late Animation<double> _logoScaleFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Total duration kept at 3 s to match your AppRoot timer.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // ── 1. Logo slides in from top (0% → 22%) ──────────────────────────
    // Slightly extended interval so the drop feels less rushed.
    // easeOutBack gives a tiny overshoot bounce — feels premium.
    _alignmentAnimation =
        AlignmentTween(
          begin: const Alignment(0.0, -1.5), // starts further off-screen
          end: Alignment.center,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.22, curve: Curves.easeOutBack),
          ),
        );

    // ── 2. Logo fades in as it drops (0% → 20%) ────────────────────────
    // Prevents the logo from "popping" into existence.
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeIn),
      ),
    );

    // ── 3. Logo holds centre, then scales up (48% → 78%) ──────────────
    // Slightly later start gives the viewer a moment to read the logo.
    // easeInCubic accelerates into the scale — feels like a dramatic zoom.
    _scaleAnimation = Tween<double>(begin: 1.0, end: 18.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.78, curve: Curves.easeInCubic),
      ),
    );

    // ── 4. Logo fades out as it scales (55% → 80%) ────────────────────
    // Smoothly hides pixelation that occurs at extreme scale values.
    _logoScaleFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.80, curve: Curves.easeIn),
      ),
    );

    // ── 5. Background gradient fades in (72% → 100%) ──────────────────
    // Starts before the logo fully disappears for a seamless crossfade.
    _gradientFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // ✅ NO Timer, NO Navigator here.
    // AppRoot flips _showSplash = false after 3 seconds.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Base white background ──────────────────────────────────
              // ColoredBox is lighter than Container for a solid colour.
              const ColoredBox(color: Colors.white),

              // ── Gradient overlay (fades in near the end) ──────────────
              // DecoratedBox skips the extra layout pass Container adds.
              Opacity(
                opacity: _gradientFadeAnimation.value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF5F6D), // red-pink
                        Color(0xFFFFC371), // warm orange
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // ── Animated logo ──────────────────────────────────────────
              Align(
                alignment: _alignmentAnimation.value,
                child: Opacity(
                  // Combines the fade-in AND the scale fade-out via multiply.
                  // During drop-in  : _logoFadeAnimation       drives 0 → 1
                  // During scale-up : _logoScaleFadeAnimation  drives 1 → 0
                  // clamp() guards against any floating-point overshoot.
                  opacity:
                      (_logoFadeAnimation.value * _logoScaleFadeAnimation.value)
                          .clamp(0.0, 1.0),
                  child: RepaintBoundary(
                    // RepaintBoundary isolates the logo layer so Flutter
                    // rasterises it separately — fewer repaints during scale.
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      filterQuality: FilterQuality.high,
                      child: Image.asset(
                        'assets/logo.png',
                        width: 130,
                        height: 130,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
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
