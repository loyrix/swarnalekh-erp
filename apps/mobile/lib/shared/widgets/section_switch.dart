import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

class SectionItem {
  final String value;
  final String label;
  final IconData icon;
  final bool enabled;

  const SectionItem({
    required this.value,
    required this.label,
    required this.icon,
    this.enabled = true,
  });
}

class SectionSwitch extends StatelessWidget {
  final String activeValue;
  final List<SectionItem> items;
  final ValueChanged<String> onChanged;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  const SectionSwitch({
    super.key,
    required this.activeValue,
    required this.items,
    required this.onChanged,
    this.alignment = WrapAlignment.start,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        children: items
            .map((e) => Expanded(child: _buildSegment(context, e)))
            .toList(),
      ),
    );
  }

  Widget _buildSegment(BuildContext context, SectionItem item) {
    final selected = activeValue == item.value;

    return GestureDetector(
      onTap: item.enabled ? () => onChanged(item.value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: selected
              ? Border.all(color: AppColors.brd(context).withValues(alpha: 0.8))
              : Border.all(color: Colors.transparent),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 16,
                color: selected
                    ? AppColors.primary
                    : item.enabled
                    ? AppColors.text2(context)
                    : AppColors.text3(context).withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : item.enabled
                      ? AppColors.text2(context)
                      : AppColors.text3(context).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
