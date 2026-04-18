import 'dart:developer';

import 'package:dextera/screens/components/custom_button.dart';
import 'package:dextera/screens/components/custom_textfield.dart';
import 'package:dextera/screens/home_chat_screen.dart';
import 'package:dextera/screens/signup_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:dextera/controllers/login_controller.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _controller = LoginController();

  @override
  void initState() {
    super.initState();

    // ── Web only: initialize Google Sign-In and listen for the button result
    if (kIsWeb) {
      final stream = _controller.initializeForWeb();
      stream?.listen((GoogleSignInAccount? account) async {
        if (account != null && mounted) {
          await _controller.handleGoogleCredential(account, context: context);

          // Navigate on success
          if (mounted && _controller.errorMessage == null) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/chat', (route) => false);
          } else if (mounted && _controller.errorMessage != null) {
            log('Google login failed: ${_controller.errorMessage}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundClr,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final containerWidth = isMobile
              ? double.infinity
              : MediaQuery.of(context).size.width * 0.7;
          final horizontalPadding = isMobile ? 8.0 : 32.0;
          final titleFontSize = isMobile ? 28.0 : 32.0;
          final subtitleFontSize = isMobile ? 12.0 : 14.0;
          final spacing = isMobile ? 20.0 : 30.0;
          final smallSpacing = isMobile ? 8.0 : 10.0;
          final largeSpacing = isMobile ? 30.0 : 40.0;
          final buttonSpacing = isMobile ? 20.0 : 25.0;
          final dividerPadding = isMobile
              ? MediaQuery.of(context).size.width * 0.05
              : MediaQuery.of(context).size.width * 0.1;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SizedBox(
                width: containerWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: spacing),
                    Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: smallSpacing),
                    Text(
                      "Seamlessly pick up where you left off \nManage your case files and continue tailoring your experience",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: subtitleFontSize,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: largeSpacing),

                    // --- Text fields ---
                    CustomTextField(
                      hint: "Email Address",
                      controller: emailController,
                    ),
                    CustomTextField(
                      hint: "Password",
                      controller: passwordController,
                      obscureText: true,
                    ),

                    SizedBox(height: buttonSpacing),

                    // --- Continue Button ---
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        return CustomButton(
                          label: "Continue",
                          onTap: () {
                            _controller.login(
                              emailController.text.trim(),
                              passwordController.text,
                              context,
                            );
                          },
                          isPrimary: true,
                          isLoading: _controller.isLoading,
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    // --- Divider with OR ---
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: dividerPadding),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.white, thickness: 1),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "or",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.white, thickness: 1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- Google Button: renderButton on web, CustomButton on mobile ---
                    if (kIsWeb)
                      web.renderButton()
                    else
                      CustomButton(
                        label: "Continue with Google",
                        iconLink: "assets/icons/google.png",
                        onTap: () => _controller.continueWithGoogle(context),
                        isPrimary: false,
                      ),

                    SizedBox(height: spacing),

                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/signup'),
                      child: RichText(
                        text: TextSpan(
                          text: "Dont have an account? ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: subtitleFontSize,
                          ),
                          children: const [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
