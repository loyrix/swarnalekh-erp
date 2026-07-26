import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/stat_period.dart';

/// A compact gold pill that opens a period picker (presets + custom range).
/// Drives period-sensitive stats (mortgage collections, inventory sold).
class StatPeriodSelector extends StatelessWidget {
  const StatPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StatPeriod value;
  final ValueChanged<StatPeriod> onChanged;

  static String labelFor(BuildContext context, StatPeriod period) {
    final l10n = AppLocalizations.of(context)!;
    switch (period.kind) {
      case StatPeriodKind.today:
        return l10n.periodToday;
      case StatPeriodKind.yesterday:
        return l10n.periodYesterday;
      case StatPeriodKind.last7:
        return l10n.periodLast7;
      case StatPeriodKind.last30:
        return l10n.periodLast30;
      case StatPeriodKind.month:
        return l10n.periodMonth;
      case StatPeriodKind.lastMonth:
        return l10n.periodLastMonth;
      case StatPeriodKind.threeMonths:
        return l10n.period3Months;
      case StatPeriodKind.sixMonths:
        return l10n.period6Months;
      case StatPeriodKind.twelveMonths:
        return l10n.period12Months;
      case StatPeriodKind.financialYear:
        return l10n.periodFinancialYear;
      case StatPeriodKind.all:
        return l10n.periodAll;
      case StatPeriodKind.custom:
        final r = period.range;
        if (r == null) return l10n.periodCustom;
        final f = DateFormat('dd MMM');
        return '${f.format(r.start)} – ${f.format(r.end)}';
    }
  }

  Future<void> _onSelected(BuildContext context, StatPeriodKind kind) async {
    if (kind != StatPeriodKind.custom) {
      onChanged(StatPeriod(kind));
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: value.range,
    );
    if (picked != null) {
      onChanged(StatPeriod(StatPeriodKind.custom, range: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<StatPeriodKind>(
      tooltip: l10n.periodMonth,
      color: AppColors.surfL(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.brd(context)),
      ),
      onSelected: (kind) => _onSelected(context, kind),
      itemBuilder: (context) => [
        _item(l10n.periodToday, StatPeriodKind.today),
        _item(l10n.periodYesterday, StatPeriodKind.yesterday),
        _item(l10n.periodLast7, StatPeriodKind.last7),
        _item(l10n.periodLast30, StatPeriodKind.last30),
        _item(l10n.periodMonth, StatPeriodKind.month),
        _item(l10n.periodLastMonth, StatPeriodKind.lastMonth),
        _item(l10n.period3Months, StatPeriodKind.threeMonths),
        _item(l10n.period6Months, StatPeriodKind.sixMonths),
        _item(l10n.periodFinancialYear, StatPeriodKind.financialYear),
        _item(l10n.periodAll, StatPeriodKind.all),
        const PopupMenuDivider(),
        _item(l10n.periodCustom, StatPeriodKind.custom),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              labelFor(context, value),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<StatPeriodKind> _item(String label, StatPeriodKind kind) {
    return PopupMenuItem<StatPeriodKind>(value: kind, child: Text(label));
  }
}
