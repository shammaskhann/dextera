import 'package:dextera/core/app_theme.dart';
import 'package:dextera/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dextera/screens/onboarding_screen.dart';
import 'dart:math' as math;
// dart:ui imports intentionally omitted; add if needed later

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(fontFamily: 'Manrope'),
          debugShowCheckedModeBanner: false,
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideOut; // 0.0 -> 1.0 (0s - 1s)

  @override
  void initState() {
    super.initState();
    initController();
  }

  initController() async {
    // Extend total duration to allow a 1s initial pause before slide-out
    // New timeline: idle 0.0-1.0s, slide-out 1.0-2.6s (slower), shrink 2.6-3.1s, text-in 3.1-4.0s
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Slide out: start after 1s idle, lengthen and smooth for a slow, steady exit
    // Timeline (seconds, total 4.0s): idle 0.0-1.0, slide-out 1.0-2.6 (1.6s), shrink 2.6-3.1 (0.5s), text 3.1-4.0 (0.9s)
    _slideOut = CurvedAnimation(
      parent: _controller,
      curve: Interval(1.0 / 4.0, 2.6 / 4.0, curve: Curves.easeInOut),
    );
    //delay for 0.8 s so the geometric get loads
    await Future.delayed(Duration(seconds: 1));
    // Auto-start
    _controller.forward();

    // When splash animation completes, push onboarding but keep splash
    // mounted underneath (opaque: false) so its background animation
    // continues and the transition doesn't look like a mobile screen swap.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // small delay to ensure final frame settles
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) {
                // pass useBackground=false to avoid duplicating background
                return const OnboardingScreen(useBackground: true);
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // helper: build positioned child that slides away in the direction
  Widget _slidingPositioned({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required Widget child,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          // choose direction: -1 left/up, +1 right/down, 0 none
          final dx = (left != null ? -1 : (right != null ? 1 : 0)).toDouble();
          final dy = (top != null ? -1 : (bottom != null ? 1 : 0)).toDouble();
          final len = math.sqrt(dx * dx + dy * dy);
          final dir = len == 0 ? Offset(0, 0) : Offset(dx / len, dy / len);
          // distance to move off-screen
          final distance =
              (size.width > size.height ? size.width : size.height) * 1.2;
          final offset = Offset(
            dir.dx * distance * _slideOut.value,
            dir.dy * distance * _slideOut.value,
          );

          return Transform.translate(offset: offset, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final dSize = height * 0.3;

    return Scaffold(
      backgroundColor: backgroundClr,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // -- TOP LEFT (stick to edge)
          _slidingPositioned(
            top: -470,
            left: -550,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/sq-tl.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- TOP RIGHT (stick to edge, no padding) ---
          _slidingPositioned(
            top: -350,
            right: -200,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/sq-tr.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- BOTTOM LEFT EXTRA (slightly offset) ---
          _slidingPositioned(
            bottom: -250,
            left: -400,
            child: SizedBox(
              height: height * 0.75,
              width: width * 0.75,
              child: SvgPicture.asset(
                "assets/images/sq-bl.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- TOP LEFT (center-top-left) ---
          _slidingPositioned(
            top: -250,
            left: width * 0.12,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/L-ctl-b.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          _slidingPositioned(
            top: -200,
            left: -220,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/tl-sharp.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- BOTTOM RIGHT EXTRA (slightly offset) ---
          _slidingPositioned(
            bottom: -170,
            right: -55,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/L-bl.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- BOTTOM LEFT (corner) ---
          _slidingPositioned(
            bottom: -150,
            left: -190,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/L-br.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- BOTTOM RIGHT (stick to edge) ---
          _slidingPositioned(
            bottom: -240,
            right: 0,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/s-br.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// --- SECOND RIGHT SHAPE (also stick, no padding) ---
          _slidingPositioned(
            top: 50,
            right: -350,
            child: SizedBox(
              child: SvgPicture.asset(
                "assets/images/S-trp.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          Center(
            child: SizedBox(
              height: dSize,
              width: dSize,
              child: SvgPicture.asset(
                "assets/icons/logo-D.svg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          // // Center stack: text (behind) and D logo (on top)
          // Center(
          //   child: AnimatedBuilder(
          //     animation: _controller,
          //     builder: (context, _) {
          //       // D logo scaling
          //       final scale = _shrink.value;

          //       // Text slide: from slightly left behind D to the right of D
          //       final textDx = lerpDouble(
          //         -dSize * 0.18,
          //         dSize * 0.78,
          //         _textIn.value,
          //       )!;
          //       final textOpacity = _textIn.value;

          //       return SizedBox(
          //         height: dSize,
          //         child: Stack(
          //           alignment: Alignment.center,
          //           children: [
          //             // Dextera text behind D
          //             Opacity(
          //               opacity: textOpacity,
          //               child: Transform.translate(
          //                 offset: Offset(textDx, 0),
          //                 child: Text(
          //                   'Dextera',
          //                   style: TextStyle(
          //                     color: Colors.white,
          //                     fontSize: dSize * 0.32,
          //                     fontWeight: FontWeight.bold,
          //                     letterSpacing: 1.2,
          //                   ),
          //                 ),
          //               ),
          //             ),

          //             // D logo on top
          //             Transform.scale(
          //               scale: scale,
          //               child: SizedBox(
          //                 height: dSize,
          //                 width: dSize,
          //                 child: SvgPicture.asset(
          //                   "assets/icons/logo-D.svg",
          //                   fit: BoxFit.contain,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
