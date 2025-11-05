import 'package:dextera/core/app_theme.dart';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _pinkBallAlignment;
  late Animation<Alignment> _blueBallAlignment;
  late Animation<Alignment> _yellowBallAlignment;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    // Animations for ball movement
    _pinkBallAlignment = Tween<Alignment>(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _blueBallAlignment = Tween<Alignment>(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _yellowBallAlignment = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return Stack(
          children: [
            // pink blur layer
            Align(
              alignment: _pinkBallAlignment.value,
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      lightPinkClr.withAlpha((0.6 * 255).round()),
                      lightPinkClr.withAlpha((0.05 * 255).round()),
                      // Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            //  blue blur layer
            Align(
              alignment: _blueBallAlignment.value,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      lightBlueClr.withAlpha((0.6 * 255).round()),
                      lightBlueClr.withAlpha((0.05 * 255).round()),
                    ],
                  ),
                ),
              ),
            ),

            // yellow blur layer
            Align(
              alignment: _yellowBallAlignment.value,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      lightGreenClr.withAlpha((0.6 * 255).round()),
                      lightGreenClr.withAlpha((0.05 * 255).round()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
