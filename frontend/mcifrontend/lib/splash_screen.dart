import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mcifrontend/home_screen.dart'; // Your home page import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _titleScaleController;
  late final AnimationController _titleFadeController;
  late final AnimationController _subtitleFadeSlideController;

  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  bool _showLottie = true;

  @override
  void initState() {
    super.initState();

    // Animation controllers for Dayventure texts
    _titleFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.8,
      upperBound: 1.0,
    );

    _subtitleFadeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _titleFade = CurvedAnimation(
      parent: _titleFadeController,
      curve: Curves.easeIn,
    );

    _titleScale = CurvedAnimation(
      parent: _titleScaleController,
      curve: Curves.elasticOut,
    );

    _subtitleFade = CurvedAnimation(
      parent: _subtitleFadeSlideController,
      curve: Curves.easeIn,
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _subtitleFadeSlideController,
      curve: Curves.easeOut,
    ));

    // Step 1: Show Lottie for 1 second
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showLottie = false; // Hide Lottie, show texts now
      });

      // Step 2: Run Dayventure animations
      _titleFadeController.forward();
      _titleScaleController.forward();

      Future.delayed(const Duration(milliseconds: 1100), () {
        _subtitleFadeSlideController.forward();

        // Step 3: After subtitle animation, wait and navigate to HomePage
        Future.delayed(const Duration(milliseconds: 2200), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MyHomePage(title: 'MCI Frontend'),
            ),
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _titleFadeController.dispose();
    _titleScaleController.dispose();
    _subtitleFadeSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double titleFontSize = size.width * 0.09;
    final double iconSize = size.width * 0.06;
    final double subtitleFontSize = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFF003A70),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0058A3), Color(0xFF001C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _showLottie
              ? Lottie.asset(
                  'assets/animation/Animation - 1748176828640.json',
                  width: size.width * 0.5,
                  fit: BoxFit.contain,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _titleFade,
                      child: ScaleTransition(
                        scale: _titleScale,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Dayventure',
                              style: GoogleFonts.lobster(
                                textStyle: TextStyle(
                                  fontSize: titleFontSize,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: size.width * 0.005,
                              ),
                              child: Icon(
                                CupertinoIcons.globe,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: Text(
                          'Lass uns die perfekte Idee für\neinen Ausflug finden!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.urbanist(
                            textStyle: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
