import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final bool obscureText;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.hint,
    this.obscureText = false,
    this.controller,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool isPasswordField = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isPasswordField = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    bool isMobile = width < 600;
    return Container(
      width: isMobile ? width * 0.8 : width * 0.6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: lightPinkClr.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightBlueClr.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: isPasswordField,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          //password show/hide icon
          if (widget.obscureText)
            InkWell(
              onTap: () {
                // Implement show/hide password functionality if needed
                isPasswordField = !isPasswordField;
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isPasswordField ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
