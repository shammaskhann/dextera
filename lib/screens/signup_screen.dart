import 'package:dextera/screens/components/custom_button.dart';
import 'package:dextera/screens/components/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:dextera/controllers/signup_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final _controller = SignupController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundClr,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Text(
                "Create an account",
                style: TextStyle(
                  color: whiteClr,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Seamlessly continue past conversations, build personal case files,\n"
                "and provide feedback to refine your answers",
                style: TextStyle(
                  color: whiteClr.withOpacity(0.70),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Text fields ---
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      CustomTextField(
                        hint: "Enter your username",
                        label: "Username",
                        controller: usernameController,
                        errorText: _controller.usernameError,
                        onChanged: (val) => _controller.validateUsername(val),
                      ),
                      CustomTextField(
                        hint: "e.g. name@example.com",
                        label: "Email Address",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _controller.emailError,
                        onChanged: (val) => _controller.validateEmail(val),
                      ),
                      CustomTextField(
                        hint: "Minimum 6 characters",
                        label: "Password",
                        controller: passwordController,
                        obscureText: true,
                        errorText: _controller.passwordError,
                        onChanged: (val) => _controller.validatePassword(val),
                      ),
                      CustomTextField(
                        hint: "Repeat your password",
                        label: "Confirm Password",
                        controller: confirmController,
                        obscureText: true,
                        errorText: _controller.confirmPasswordError,
                        onChanged:
                            (val) => _controller.validateConfirmPassword(
                              val,
                              passwordController.text,
                            ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),

              // --- Continue Button ---
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return CustomButton(
                    label: "Continue",
                    onTap: () {
                      _controller.register(
                        usernameController.text.trim(),
                        emailController.text.trim(),
                        passwordController.text,
                        confirmController.text,
                        context,
                      );
                    },
                    isPrimary: true,
                    isLoading: _controller.isLoading,
                  );
                },
              ),

              const SizedBox(height: 25),

              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(
                      color: whiteClr.withOpacity(0.70),
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: TextStyle(
                          color: whiteClr,
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
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
