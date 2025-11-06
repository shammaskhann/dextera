import 'package:dextera/screens/components/custom_button.dart';
import 'package:dextera/screens/components/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:flutter_svg/svg.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    return Scaffold(
      backgroundColor: backgroundClr,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Create an account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Seamlessly continue past conversations, build personal case files,\n"
                "and provide feedback to refine your answers",
                style: TextStyle(
                  color: Colors.white70,
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
              CustomTextField(
                hint: "Confirm Password",
                controller: confirmController,
                obscureText: true,
              ),
              const SizedBox(height: 25),

              // --- Continue Button ---
              CustomButton(label: "Continue", onTap: () {}, isPrimary: true),

              const SizedBox(height: 25),

              // --- Divider with OR ---
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white, thickness: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("or", style: TextStyle(color: Colors.white70)),
                  ),
                  Expanded(child: Divider(color: Colors.white, thickness: 1)),
                ],
              ),
              const SizedBox(height: 25),

              // --- Google Button ---
              CustomButton(
                label: "Continue with Google",
                icon: SvgPicture.asset("assets/icons/google.svg", height: 20),
                onTap: () {},
                isPrimary: false,
              ),

              const SizedBox(height: 30),
              RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  children: [
                    TextSpan(
                      text: "Login",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
