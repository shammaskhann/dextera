import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final String? label;
  final bool obscureText;
  final TextEditingController? controller;
  final String? errorText;
  final Function(String)? onChanged;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.hint,
    this.label,
    this.obscureText = false,
    this.controller,
    this.errorText,
    this.onChanged,
    this.keyboardType = TextInputType.text,
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
    final double fieldWidth = isMobile ? width * 0.85 : width * 0.6;

    return Container(
      width: fieldWidth,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: TextStyle(
                color: whiteClr.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errorText != null
                    ? Colors.red.withOpacity(0.5)
                    : lightBlueClr.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    onChanged: widget.onChanged,
                    keyboardType: widget.keyboardType,
                    obscureText: isPasswordField,
                    style: TextStyle(color: whiteClr, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(color: whiteClr),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                if (widget.obscureText)
                  InkWell(
                    onTap: () {
                      isPasswordField = !isPasswordField;
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        isPasswordField
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: whiteClr,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                widget.errorText!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
