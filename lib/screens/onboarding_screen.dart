// import 'dart:developer';
// import 'dart:ui';
// import 'dart:math' as math;

// import 'package:dextera/core/app_theme.dart';
// import 'package:dextera/screens/components/animated_component.dart';
// import 'package:dextera/screens/signuo_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// class OnboardingScreen extends StatefulWidget {
//   // If useBackground is false the screen assumes an existing background
//   // (for example the splash underneath) and will render transparent
//   // scaffold so the underlying animation continues to show.
//   const OnboardingScreen({super.key, this.useBackground = true});

//   final bool useBackground;

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen>
//     with TickerProviderStateMixin {
//   late final AnimationController _logoController;
//   late final AnimationController _textController;
//   late final Animation<double> _logoScale;
//   late final Animation<double> _logoSlide;
//   late final Animation<double> _textSlide;
//   late final Animation<double> _textOpacity;
//   late final AnimationController _buttonsController;
//   late final Animation<double> _buttonsSlide;
//   late final Animation<double> _buttonsOpacity;
//   // (no final swap state needed; layout remains animated)
//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height;
//     final width = MediaQuery.of(context).size.width;

//     final dSize = height * 0.3;
//     return Scaffold(
//       // If we're reusing the splash's background, make scaffold transparent
//       backgroundColor: backgroundClr,
//       body: Stack(
//         children: [
//           AnimatedBackground(),

//           ClipRect(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//               child: Container(color: const Color.fromRGBO(0, 0, 0, 0.1)),
//             ),
//           ),

//           // Main content: animated D logo and revealing text
//           Positioned.fill(
//             child: Center(
//               child: Container(
//                 width: dSize * 1.8,
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     final maxWidth = constraints.maxWidth;
//                     // how much D moves left, based on available width
//                     final moveDx = maxWidth * 0.238;

//                     return Column(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Stack(
//                           alignment: Alignment.topCenter,
//                           children: [
//                             // Text that will slide out from behind D
//                             AnimatedBuilder(
//                               animation: _textController,
//                               builder: (context, child) {
//                                 final tx = lerpDouble(
//                                   0,
//                                   moveDx,
//                                   _textSlide.value,
//                                 )!;
//                                 return Opacity(
//                                   opacity: _textOpacity.value,
//                                   child: Transform.translate(
//                                     offset: Offset(tx, 0),
//                                     child: child,
//                                   ),
//                                 );
//                               },
//                               child: Align(
//                                 alignment: Alignment.topCenter,
//                                 child: Text(
//                                   'extera',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: dSize * 0.39,
//                                     fontFamily: 'Manrope',
//                                     fontWeight: FontWeight.bold,
//                                     letterSpacing: 1.5,
//                                   ),
//                                 ),
//                               ),
//                             ),

//                             // D logo on top which will slide left and shrink.
//                             // Use a scaled SizedBox so layout height matches visual size.
//                             AnimatedBuilder(
//                               animation: _logoController,
//                               builder: (context, _) {
//                                 final sx = _logoScale.value;
//                                 final lx = -_logoSlide.value * moveDx;
//                                 final scaledSize = dSize * sx;
//                                 return Transform.translate(
//                                   offset: Offset(lx, 0),
//                                   child: Align(
//                                     alignment: Alignment.topCenter,
//                                     child: SizedBox(
//                                       height: scaledSize,
//                                       width: scaledSize,
//                                       child: SvgPicture.asset(
//                                         "assets/icons/logo-D.svg",
//                                         fit: BoxFit.contain,
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 12),

//                         // Buttons below, centered under text
//                         Align(
//                           alignment: Alignment.topCenter,
//                           child: AnimatedBuilder(
//                             animation: _buttonsController,
//                             builder: (context, child) {
//                               final by = lerpDouble(
//                                 0,
//                                 dSize * 0.18,
//                                 _buttonsSlide.value,
//                               )!;
//                               return Opacity(
//                                 opacity: _buttonsOpacity.value,
//                                 child: Transform.translate(
//                                   offset: Offset(0, by),
//                                   child: child,
//                                 ),
//                               );
//                             },
//                             child: Wrap(
//                               spacing: 16,
//                               alignment: WrapAlignment.center,
//                               children: [
//                                 Container(
//                                   margin: const EdgeInsets.symmetric(
//                                     horizontal: 8.0,
//                                   ),
//                                   child: Material(
//                                     color: Colors.transparent,
//                                     child: GestureDetector(
//                                       onTap: () async {
//                                         log('Get Started tapped');
//                                         Navigator.of(context).push(
//                                           MaterialPageRoute(
//                                             builder: (_) =>
//                                                 const SignupScreen(),
//                                           ),
//                                         );
//                                       },

//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 16,
//                                           vertical: 12,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: const Color(0xFFDEDFE3),
//                                           borderRadius: BorderRadius.circular(
//                                             28,
//                                           ),
//                                           border: Border.all(
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                         child: Row(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             Text(
//                                               "Get Started",
//                                               style: const TextStyle(
//                                                 color: Color(0xFF09090A),
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 8),
//                                             const Icon(
//                                               Icons.arrow_forward_ios,
//                                               size: 14,
//                                               color: Color(0xFF09090A),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 _buildActionButton('Learn More', () {
//                                   log('Learn More tapped');
//                                 }),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();

//     _logoController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );

//     _textController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _buttonsController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );

//     // Make the D logo shrink more when revealing the text so the text
//     // can sit comfortably beside it. End scale reduced from 0.5 -> 0.38.
//     _logoScale = Tween<double>(begin: 1.0, end: 0.5).animate(
//       CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
//     );

//     _logoSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
//     );

//     _textSlide = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

//     _textOpacity = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

//     _buttonsSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
//     );

//     _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _buttonsController, curve: Curves.easeIn),
//     );

//     // // Start the logo animation when screen appears, then reveal text and buttons
//     // _logoController.forward().whenComplete(
//     //   () => _textController.forward().whenComplete(
//     //     () => _buttonsController.forward(),
//     //   ),
//     // );
//     _logoController.forward().whenComplete(() {
//       if (!mounted) return;
//       _textController.forward().whenComplete(() {
//         if (!mounted) return;
//         _buttonsController.forward();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     @override
//     void dispose() {
//       // Stop all animations and remove listeners before disposal
//       try {
//         _logoController.stop();
//         _textController.stop();
//         _buttonsController.stop();
//       } catch (_) {}

//       _logoController.dispose();
//       _textController.dispose();
//       _buttonsController.dispose();
//       super.dispose();
//     }
//   }

//   Widget _buildActionButton(String label, VoidCallback onTap) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: Material(
//         color: Colors.transparent,
//         child: GestureDetector(
//           onTap: () {
//             debugPrint('Onboarding button tapped: $label');
//             try {
//               onTap();
//             } catch (e, st) {
//               debugPrint('Error in onTap for $label: $e\n$st');
//             }
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: const Color(0xFFDEDFE3),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: Colors.white),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     color: Color(0xFF09090A),
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 const Icon(
//                   Icons.arrow_forward_ios,
//                   size: 14,
//                   color: Color(0xFF09090A),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:developer';
import 'dart:ui';
import 'dart:math' as math;

import 'package:dextera/core/app_theme.dart';
import 'package:dextera/screens/components/animated_component.dart';
import 'package:dextera/screens/signuo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
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
  late final AnimationController _buttonsController;
  late final Animation<double> _buttonsSlide;
  late final Animation<double> _buttonsOpacity;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final dSize = height * 0.3;
    return Scaffold(
      backgroundColor: backgroundClr,
      body: Stack(
        children: [
          // background (interactive or not, as before)
          AnimatedBackground(),

          // --------- IMPORTANT: make blur non-blocking -----------
          // IgnorePointer lets pointer events pass through to widgets above it.
          IgnorePointer(
            ignoring: true,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: const Color.fromRGBO(0, 0, 0, 0.1)),
              ),
            ),
          ),
          // -------------------------------------------------------

          // Main content: animated D logo and revealing text
          Positioned.fill(
            child: Center(
              child: Container(
                width: dSize * 1.8,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final moveDx = maxWidth * 0.238;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Text that will slide out from behind D
                            AnimatedBuilder(
                              animation: _textController,
                              builder: (context, child) {
                                final tx = lerpDouble(
                                  0,
                                  moveDx,
                                  _textSlide.value,
                                )!;
                                return Opacity(
                                  opacity: _textOpacity.value,
                                  child: Transform.translate(
                                    offset: Offset(tx, 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  'extera',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: dSize * 0.39,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // D logo
                            AnimatedBuilder(
                              animation: _logoController,
                              builder: (context, _) {
                                final sx = _logoScale.value;
                                final lx = -_logoSlide.value * moveDx;
                                final scaledSize = dSize * sx;
                                return Transform.translate(
                                  offset: Offset(lx, 0),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      height: scaledSize,
                                      width: scaledSize,
                                      child: SvgPicture.asset(
                                        "assets/icons/logo-D.svg",
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.topCenter,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.18),
                              end: Offset.zero,
                            ).animate(_buttonsController),
                            child: FadeTransition(
                              opacity: _buttonsOpacity,
                              child: Wrap(
                                spacing: 16,
                                alignment: WrapAlignment.center,
                                runAlignment: WrapAlignment.start,
                                children: [
                                  // Get Started button (GestureDetector)
                                  Material(
                                    color: Colors.transparent,
                                    child: GestureDetector(
                                      onTap: () async {
                                        debugPrint('Get Started tapped');
                                        // small delay and mounted check to avoid mid-dispose issues
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );
                                        if (!mounted) return;
                                        // use pushReplacement if you don't want Onboarding kept in backstack
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SignupScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDEDFE3),
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "Get Started",
                                              style: TextStyle(
                                                color: Color(0xFF09090A),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Color(0xFF09090A),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Learn More
                                  _buildActionButton('Learn More', () {
                                    debugPrint('Learn More tapped');
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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

    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

    _buttonsSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );

    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeIn),
    );

    // chain with mounted guards
    _logoController.forward().whenComplete(() {
      if (!mounted) return;
      _textController.forward().whenComplete(() {
        if (!mounted) return;
        _buttonsController.forward();
      });
    });
  }

  @override
  void dispose() {
    // stop and dispose controllers safely
    try {
      _logoController.stop();
      _textController.stop();
      _buttonsController.stop();
    } catch (_) {}
    _logoController.dispose();
    _textController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            debugPrint('Onboarding button tapped: $label');
            try {
              onTap();
            } catch (e, st) {
              debugPrint('Error in onTap for $label: $e\n$st');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDEDFE3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF09090A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF09090A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
