import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int otpLength = 6;
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < otpLength; i++) {
      controllers.add(TextEditingController());
      focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isEmpty) return;
    if (RegExp(r'^[0-9]$').hasMatch(value)) {
      // move to next field if valid digit
      if (index < otpLength - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    } else {
      // remove invalid input
      controllers[index].clear();
    }
  }

  void _onKey(KeyEvent event, int index) {
    if (event is! KeyDownEvent) return;

    // Handle backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        controllers[index].text.isEmpty &&
        index > 0) {
      focusNodes[index - 1].requestFocus();
      controllers[index - 1].clear();
    }

    // Handle enter key
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _verifyOtp();
    }
  }

  void _verifyOtp() {
    final otp = controllers.map((c) => c.text).join();
    if (otp.length == otpLength) {
      debugPrint("Entered OTP: $otp");
      // Call your API or logic here
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Verifying $otp...")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all digits.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E2430),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "OTP Verification",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "A One-Time Password has been sent to ${widget.email}\nEnter the 6 digit code to verify it’s really you",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 25.h),

              /// OTP Fields (responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.of(context).size.width;
                  final height = MediaQuery.of(context).size.height;
                  const horizontalPadding = 48.0; // matches outer Padding
                  const spacing = 19.0;
                  final availableWidth =
                      width - horizontalPadding - (otpLength - 1) * spacing;
                  // size based on available width per field and a fraction of height
                  final fieldSizeByWidth = availableWidth / otpLength;
                  final fieldSizeByHeight =
                      height * 0.25; // 16% of screen height
                  final fieldSize = math.max(
                    48.0,
                    math.min(fieldSizeByWidth, fieldSizeByHeight),
                  );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      otpLength,
                      (index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                        child: SizedBox(
                          width: fieldSize,
                          height: fieldSize,
                          child: Focus(
                            focusNode: focusNodes[index],
                            onKeyEvent: (node, event) {
                              _onKey(event, index);
                              return KeyEventResult.handled;
                            },
                            child: TextField(
                              controller: controllers[index],
                              autofocus: index == 0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fieldSize * 0.45,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFF485067),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    fieldSize * 0.12,
                                  ),
                                  borderSide: const BorderSide(
                                    color: Colors.white12,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    fieldSize * 0.12,
                                  ),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (val) => _onChanged(val, index),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              /// Verify button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _verifyOtp,
                child: const Text(
                  "Verify",
                  style: TextStyle(
                    color: Color(0xFF1E2430),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Resend code
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Resending code...")),
                  );
                },
                child: const Text(
                  "Resend Code",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
