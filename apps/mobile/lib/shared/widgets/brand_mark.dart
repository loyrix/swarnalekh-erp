import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final double padding;
  final bool elevated;

  const BrandMark({
    super.key,
    this.size = 60,
    this.padding = 5,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
        boxShadow: elevated ? AppShadows.goldGlow : null,
      ),
      child: Image.asset(
        'assets/brand/swarnalekh-mark-transparent.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
