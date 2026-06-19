import 'package:flutter/material.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

typedef FilterBuilder = List<Widget> Function(BuildContext context);

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;
  final List<Widget>? filters;
  final FilterBuilder? filterBuilder;
  final VoidCallback? onRefresh;
  final String? searchHint;
  final String? clearSearchTooltip;
  final String? refreshTooltip;
  final bool isLoading;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.onClearSearch,
    this.filters,
    this.filterBuilder,
    this.onRefresh,
    this.searchHint,
    this.clearSearchTooltip,
    this.refreshTooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width > 768;

    final effectiveFilters = filterBuilder?.call(context) ?? filters ?? [];

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(context, l10n),
          if (effectiveFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: effectiveFilters),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        children: [
          SizedBox(width: 300, child: _buildSearchField(context, l10n)),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: effectiveFilters,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.brd(context))),
              ),
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                tooltip: refreshTooltip ?? l10n.reportsRefresh,
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: searchHint ?? l10n.searchHint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.text3(context),
          size: 20,
        ),
        suffixIcon: searchController.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: clearSearchTooltip ?? l10n.commonClearSearch,
                onPressed: onClearSearch,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        isDense: true,
      ),
    );
  }
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withValues(alpha: 0.15)
              : AppColors.surfL(context),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? effectiveColor.withValues(alpha: 0.4)
                : AppColors.brd(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? effectiveColor : AppColors.text3(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? effectiveColor : AppColors.text2(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String label;
  final double width;

  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
        style: TextStyle(color: AppColors.text1(context), fontSize: 13),
        iconEnabledColor: AppColors.text2(context),
      ),
    );
  }
}

class FilterDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final double width;

  const FilterDateField({
    super.key,
    required this.controller,
    required this.label,
    this.onTap,
    this.onClear,
    this.width = 170,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: l10n.reportsDateHint,
          prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.commonClearSearch,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          isDense: true,
        ),
      ),
    );
  }
}
