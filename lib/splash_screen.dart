import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _dotsController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _dot1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _dot2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    _dot3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/logo.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: SlideTransition(
                    position: _textSlide,
                    child: child,
                  ),
                );
              },
              child: Text(
                'Claridad que impulsa\nel crecimiento',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: const Color.fromARGB(255, 1, 15, 56),
                  letterSpacing: 0.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: _dotsController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(_dot1.value),
                    const SizedBox(width: 10),
                    _buildDot(_dot2.value),
                    const SizedBox(width: 10),
                    _buildDot(_dot3.value),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(double value) {
    return Transform.translate(
      offset: Offset(0, -8 * value),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3366FF).withValues(alpha: 0.4 + 0.6 * value),
        ),
      ),
    );
  }
}
