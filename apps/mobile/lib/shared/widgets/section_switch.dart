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
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      children: items.map((item) {
        final selected = activeValue == item.value;
        return ChoiceChip(
          selected: selected,
          avatar: Icon(
            item.icon,
            size: 18,
            color: selected
                ? AppColors.primary
                : item.enabled
                ? AppColors.text2(context)
                : AppColors.text3(context),
          ),
          label: Text(item.label),
          onSelected: item.enabled ? (_) => onChanged(item.value) : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.1),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected
                ? AppColors.primary
                : item.enabled
                ? AppColors.text1(context)
                : AppColors.text3(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : item.enabled
                ? AppColors.brd(context)
                : AppColors.brd(context).withValues(alpha: 0.5),
          ),
          backgroundColor: AppColors.surfL(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }).toList(),
    );
  }
}
