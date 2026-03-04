import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

// ─── App Text ─────────────────────────────────────────────────────────────────

class AppText extends StatelessWidget {
  final String text;
  final double? size;
  final FontWeight? weight;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final double? top, bottom, left, right;

  const AppText(
    this.text, {
    super.key,
    this.size,
    this.weight,
    this.color,
    this.align,
    this.maxLines,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    Widget text_ = Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: size ?? 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.white,
      ),
    );

    if (top != null || bottom != null || left != null || right != null) {
      return Padding(
        padding: EdgeInsets.only(
          top: top ?? 0,
          bottom: bottom ?? 0,
          left: left ?? 0,
          right: right ?? 0,
        ),
        child: text_,
      );
    }

    return text_;
  }
}

// ─── App Button ───────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
        ),
        child: _child(),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: _child(),
    );
  }

  Widget _child() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
      );
    }
    return Text(label);
  }
}

// ─── App Text Field ───────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final Widget? prefixIcon;

  const AppTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.grey,
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Amount Card ──────────────────────────────────────────────────────────────

class AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const AmountCard({
    super.key,
    required this.label,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label, size: 12, color: AppColors.grey),
          const SizedBox(height: 6),
          AppText(
            '\$${amount.toStringAsFixed(2)}',
            size: 20,
            weight: FontWeight.w700,
            color: color ?? AppColors.white,
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(title, size: 16, weight: FontWeight.w600),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: AppText(actionLabel!, size: 13, color: AppColors.primary),
          ),
      ],
    );
  }
}

// ─── Loading Shimmer ──────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
