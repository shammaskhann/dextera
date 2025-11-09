import 'package:dextera/screens/components/custom_button.dart';
import 'package:dextera/screens/components/custom_textfield.dart';
import 'package:dextera/screens/otp_verify_screen.dart';
import 'package:dextera/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:flutter_svg/svg.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: backgroundClr,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Seamlessly pick up where you left off \nManage your case files and continue tailoring your experience",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

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

                const SizedBox(height: 25),

                // --- Continue Button ---
                CustomButton(
                  label: "Continue",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OtpVerificationScreen(email: emailController.text),
                      ),
                    );
                  },
                  isPrimary: true,
                ),

                const SizedBox(height: 15),

                // --- Divider with OR ---
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                  ),
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

                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: "Dont have an account? ",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: const TextStyle(
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
      ),
    );
  }
}
