import 'dart:ui';

import 'package:dextera/core/app_theme.dart';
import 'package:dextera/screens/components/animated_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  // If useBackground is false the screen assumes an existing background
  // (for example the splash underneath) and will render transparent
  // scaffold so the underlying animation continues to show.
  const OnboardingScreen({super.key, this.useBackground = true});

  final bool useBackground;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlide;
  late final Animation<double> _textSlide;
  late final Animation<double> _textOpacity;
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final dSize = height * 0.3;
    return Scaffold(
      // If we're reusing the splash's background, make scaffold transparent
      backgroundColor: backgroundClr,
      body: Stack(
        children: [
          AnimatedBackground(),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: const Color.fromRGBO(0, 0, 0, 0.1)),
          ),

          // Main content: animated D logo and revealing text
          Center(
            child: SizedBox(
              height: dSize,
              width: dSize * 1.8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final moveDx =
                      constraints.maxWidth * 0.18; // how much D moves left

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Text that will slide out from behind D
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          final tx = lerpDouble(0, moveDx, _textSlide.value)!;
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: Transform.translate(
                              offset: Offset(tx, 0),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'extra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: dSize * 0.32,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      // D logo on top which will slide left and shrink
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          final sx = _logoScale.value;
                          final lx = -_logoSlide.value * moveDx;
                          return Transform.translate(
                            offset: Offset(lx, 0),
                            child: Transform.scale(scale: sx, child: child),
                          );
                        },
                        child: SizedBox(
                          height: dSize - 10,
                          width: dSize - 10,
                          child: SvgPicture.asset(
                            "assets/icons/logo-D.svg",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _textSlide = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Start the logo animation when screen appears, then reveal text
    _logoController.forward().whenComplete(() => _textController.forward());
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
