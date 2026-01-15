import 'package:dextera/screens/components/custom_button.dart';
import 'package:dextera/screens/components/custom_textfield.dart';
import 'package:dextera/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:dextera/controllers/login_controller.dart';

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
                          Expanded(
                            child: Divider(color: Colors.white, thickness: 1),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "or",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.white, thickness: 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- Google Button ---
                    CustomButton(
                      label: "Continue with Google",
                      iconLink: "assets/icons/google.png",
                      onTap: () {},
                      isPrimary: false,
                    ),

                    SizedBox(height: spacing),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Dont have an account? ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: subtitleFontSize,
                          ),
                          children: [
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
