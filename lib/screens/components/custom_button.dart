import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final String? iconLink;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    this.onTap,
    this.isPrimary = true,
    this.iconLink,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    bool isMobile = width < 600;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isMobile ? width * 0.8 : width * 0.6,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? whiteClr : lightBlueClr,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? Colors.transparent : whiteClr.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? backgroundClr : whiteClr,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ] else if (iconLink != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(iconLink!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? backgroundClr : whiteClr,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
