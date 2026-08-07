import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Default validation if isRequired is true and no custom validator provided
    final effectiveValidator = validator ?? (isRequired
        ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          }
        : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.charcoal,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: effectiveValidator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14, color: AppTheme.charcoal),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label...',
            prefixIcon: icon != null ? Icon(icon, size: 20, color: AppTheme.charcoal.withOpacity(0.7)) : null,
          ),
        ),
      ],
    );
  }
}
