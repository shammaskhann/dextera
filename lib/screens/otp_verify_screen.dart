import 'package:dextera/controllers/otp_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
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
  final List<String> _previousTexts = [];
  final _otpController = OtpController();
  String _enteredOtp = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < otpLength; i++) {
      final controller = TextEditingController();
      controllers.add(controller);
      focusNodes.add(FocusNode());
      _previousTexts.add('');

      // Listen to controller changes for better web support
      final index = i;
      controller.addListener(() {
        _onControllerChanged(index);
      });
    }
  }

  void _onControllerChanged(int index) {
    if (_isPasting) return;

    final controller = controllers[index];
    final currentText = controller.text;
    final previousText = _previousTexts[index];

    // Update previous text
    _previousTexts[index] = currentText;

    // Detect if field became empty (backspace on filled field)
    if (previousText.isNotEmpty && currentText.isEmpty) {
      _handleFieldEmptied(index);
      return;
    }

    // Prevent multiple characters (except during paste)
    if (currentText.length > 1 && !_isPasting) {
      final lastChar = currentText[currentText.length - 1];
      if (RegExp(r'^[0-9]$').hasMatch(lastChar)) {
        controller.text = lastChar;
        controller.selection = TextSelection.collapsed(offset: 1);
        _previousTexts[index] = lastChar;
      } else {
        controller.text = '';
        _previousTexts[index] = '';
      }
    }
  }

  bool _isPasting = false;

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    _otpController.dispose();
    super.dispose();
  }

  /// Handles text changes including paste operations
  void _handleTextChange(String value, int index) {
    if (_isPasting) {
      return; // Paste is handled separately
    }

    // Extract only digits from the input
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      // If empty, the field is already clear
      return;
    }

    // Handle paste operation (multiple digits)
    if (digitsOnly.length > 1) {
      _handlePaste(digitsOnly, index);
      return;
    }

    // Handle single digit input
    final digit = digitsOnly.substring(0, 1);
    if (controllers[index].text != digit) {
      controllers[index].text = digit;
      controllers[index].selection = TextSelection.collapsed(offset: 1);
    }

    // Move to next field if not last
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < otpLength - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        // Last field filled, unfocus and verify
        focusNodes[index].unfocus();
        _verifyOtp();
      }
    });
  }

  /// Handles paste of multiple digits
  void _handlePaste(String digits, int startIndex) {
    _isPasting = true;

    // Distribute digits across fields starting from current index
    int filledCount = 0;
    for (int i = 0; i < digits.length && (startIndex + i) < otpLength; i++) {
      final digit = digits[i];
      controllers[startIndex + i].text = digit;
      controllers[startIndex + i].selection = TextSelection.collapsed(
        offset: 1,
      );
      _previousTexts[startIndex + i] = digit;
      filledCount++;
    }

    // Calculate the next focus index
    final nextIndex = startIndex + filledCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPasting = false;
      if (nextIndex < otpLength) {
        // Move to next empty field
        focusNodes[nextIndex].requestFocus();
      } else {
        // All fields filled, unfocus and verify
        final lastIndex = otpLength - 1;
        focusNodes[lastIndex].unfocus();
        _verifyOtp();
      }
    });
  }

  /// Handles keyboard events (backspace, enter, etc.)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, int index) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Handle backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (controllers[index].text.isNotEmpty) {
        // If field has text, let the default behavior clear it
        // We'll handle moving back in the change listener if needed
        return KeyEventResult.ignored; // Let TextField handle clearing
      } else if (index > 0) {
        // If field is empty, move to previous and select its text
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNodes[index - 1].requestFocus();
          controllers[index - 1].selection = TextSelection(
            baseOffset: 0,
            extentOffset: controllers[index - 1].text.length,
          );
        });
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    // Handle enter key
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _verifyOtp();
      return KeyEventResult.handled;
    }

    // Handle arrow keys for navigation
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNodes[index - 1].requestFocus();
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        index < otpLength - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNodes[index + 1].requestFocus();
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handles when field becomes empty (after backspace on filled field)
  void _handleFieldEmptied(int index) {
    if (index > 0) {
      // Move focus to previous field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNodes[index - 1].requestFocus();
      });
    }
  }

  void _verifyOtp() {
    final otp = _enteredOtp.isNotEmpty
        ? _enteredOtp
        : controllers.map((c) => c.text).join();

    if (otp.length == otpLength) {
      _otpController.verifyOtp(widget.email, otp, context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all digits.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

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
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
              SizedBox(height: 25.h),

              /// OTP Fields (responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.of(context).size.width;
                  final height = MediaQuery.of(context).size.height;
                  final horizontalPadding =
                      width * 0.12; // matches outer Padding
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
                  return OtpTextField(
                    margin: EdgeInsets.only(right: 12),
                    numberOfFields: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    //fieldHeight: fieldSizeByHeight,
                    fieldWidth: fieldSizeByWidth,
                    borderColor: Colors.white,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: fieldSize * 0.45,
                      fontWeight: FontWeight.w600,
                    ),
                    enabledBorderColor: Colors.white,
                    //set to true to show as box or false to show as dash
                    showFieldAsBox: true,
                    borderRadius: BorderRadius.circular(fieldSize * 0.12),
                    //runs when a code is typed in
                    onCodeChanged: (String code) {
                      _enteredOtp = code;
                    },
                    //runs when every textfield is filled
                    onSubmit: (String verificationCode) {
                      _enteredOtp = verificationCode;
                      _verifyOtp();
                    }, // end onSubmit
                  );

                  // return Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: List.generate(
                  //     otpLength,
                  //     (index) => Padding(
                  //       padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  //       child: SizedBox(
                  //         width: fieldSize,
                  //         height: fieldSize,
                  //         child: Focus(
                  //           focusNode: focusNodes[index],
                  //           autofocus: index == 0,
                  //           onKeyEvent: (node, event) {
                  //             return _handleKeyEvent(node, event, index);
                  //           },
                  //           child: TextField(
                  //             controller: controllers[index],
                  //             textAlign: TextAlign.center,
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: fieldSize * 0.45,
                  //               fontWeight: FontWeight.w600,
                  //             ),
                  //             keyboardType: TextInputType.number,
                  //             textInputAction: index < otpLength - 1
                  //                 ? TextInputAction.next
                  //                 : TextInputAction.done,
                  //             inputFormatters: [
                  //               FilteringTextInputFormatter.digitsOnly,
                  //               LengthLimitingTextInputFormatter(6),
                  //             ],
                  //             decoration: InputDecoration(
                  //               counterText: '',
                  //               filled: true,
                  //               fillColor: const Color(0xFF485067),
                  //               border: OutlineInputBorder(
                  //                 borderRadius: BorderRadius.circular(
                  //                   fieldSize * 0.12,
                  //                 ),
                  //                 borderSide: const BorderSide(
                  //                   color: Colors.white12,
                  //                   width: 1,
                  //                 ),
                  //               ),
                  //               focusedBorder: OutlineInputBorder(
                  //                 borderRadius: BorderRadius.circular(
                  //                   fieldSize * 0.12,
                  //                 ),
                  //                 borderSide: const BorderSide(
                  //                   color: Colors.white,
                  //                   width: 1.5,
                  //                 ),
                  //               ),
                  //             ),
                  //             onChanged: (val) => _handleTextChange(val, index),
                  //             onSubmitted: (_) {
                  //               if (index < otpLength - 1) {
                  //                 focusNodes[index + 1].requestFocus();
                  //               } else {
                  //                 _verifyOtp();
                  //               }
                  //             },
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 32),

              /// Verify button (responsive Container)
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;

                  // Determine whether we're on a narrow/mobile layout
                  final isMobile = screenWidth < 700;

                  // Button width: on mobile take a large fraction, on wide screens cap it
                  final buttonWidth = isMobile
                      ? math.min(constraints.maxWidth, screenWidth * 0.78)
                      : math.min(420.0, constraints.maxWidth * 0.45);

                  // Button height: use a responsive fraction of height with a sensible min
                  final buttonHeight = math.max(
                    48.0,
                    screenHeight * (isMobile ? 0.065 : 0.045),
                  );

                  return ListenableBuilder(
                    listenable: _otpController,
                    builder: (context, _) {
                      return Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _otpController.isLoading ? null : _verifyOtp,
                          child: Container(
                            width: buttonWidth,
                            height: buttonHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _otpController.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF1E2430),
                                          ),
                                    ),
                                  )
                                : Text(
                                    "Verify",
                                    style: TextStyle(
                                      color: const Color(0xFF1E2430),
                                      fontWeight: FontWeight.w600,
                                      fontSize: math.max(
                                        14.0,
                                        buttonHeight * 0.34,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              /// Resend code
              ListenableBuilder(
                listenable: _otpController,
                builder: (context, _) {
                  return TextButton(
                    onPressed: _otpController.isResending
                        ? null
                        : () {
                            _otpController.resendOtp(widget.email, context);
                          },
                    child: _otpController.isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          )
                        : const Text(
                            "Resend Code",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
