import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/reports/application/reports_providers.dart';
import 'package:swarnbook/features/reports/data/models/reports_data.dart';
import 'package:swarnbook/features/reports/data/reports_repository.dart';
import 'package:swarnbook/features/reports/presentation/report_format.dart';
import 'package:swarnbook/features/reports/presentation/widgets/report_section.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  ReportsQuery _query = const ReportsQuery();
  String _group = 'inventory';
  bool _roleLoaded = false;
  bool _canView = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (!mounted) return;
      setState(() {
        _canView = isAdminRole(role);
        _roleLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _roleLoaded = true);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = _query.copyWith(search: value));
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(reportsProvider(_query));
    await ref.read(reportsProvider(_query).future);
  }

  Future<void> _export(String reportType) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final payload = await ref
          .read(reportsRepositoryProvider)
          .exportReport(reportType, _query);
      await Printing.sharePdf(bytes: payload.bytes, filename: payload.fileName);
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.errorFailedLoadDashboard);
    }
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    final from = TextEditingController(text: _query.dateFrom);
    final to = TextEditingController(text: _query.dateTo);
    final category = TextEditingController(text: _query.category);
    final branch = TextEditingController(text: _query.branch);
    var status = _query.status;

    await AppFilterSheet.show(
      context,
      onApply: () => setState(() {
        _query = _query.copyWith(
          dateFrom: from.text,
          dateTo: to.text,
          category: category.text,
          branch: branch.text,
          status: status,
        );
      }),
      onClear: () {
        from.clear();
        to.clear();
        category.clear();
        branch.clear();
        status = 'all';
      },
      builder: (context, setSheetState) => [
        _sheetField(from, l10n.reportsFromDate, hint: l10n.reportsDateHint),
        _sheetField(to, l10n.reportsToDate, hint: l10n.reportsDateHint),
        _sheetField(category, l10n.reportsCategory),
        _sheetField(branch, l10n.reportsBranch),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: InputDecoration(
            labelText: l10n.reportsStatus,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          items: [
            DropdownMenuItem(value: 'all', child: Text(l10n.reportsAllStatus)),
            DropdownMenuItem(
              value: 'in_stock',
              child: Text(l10n.reportsInStock),
            ),
            DropdownMenuItem(
              value: 'reserved',
              child: Text(l10n.reportsReserved),
            ),
            DropdownMenuItem(value: 'sold', child: Text(l10n.reportsSold)),
            DropdownMenuItem(
              value: 'active',
              child: Text(l10n.reportsActiveLoan),
            ),
            DropdownMenuItem(
              value: 'closed',
              child: Text(l10n.reportsClosedLoan),
            ),
          ],
          onChanged: (v) => setSheetState(() => status = v ?? 'all'),
        ),
      ],
    );

    from.dispose();
    to.dispose();
    category.dispose();
    branch.dispose();
  }

  Widget _sheetField(TextEditingController c, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_roleLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_canView) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l10n.reportsAdminOnly,
        subtitle: l10n.reportsStaffSubtitle,
        iconColor: AppColors.warning,
      );
    }

    return AppSectionScaffold(
      header: _header(l10n),
      sections: [
        SectionItem(
          value: 'inventory',
          label: l10n.reportsInventoryReports,
          icon: Icons.inventory_2_outlined,
        ),
        SectionItem(
          value: 'billing',
          label: l10n.reportsBillingReports,
          icon: Icons.receipt_long_outlined,
        ),
        SectionItem(
          value: 'mortgage',
          label: l10n.reportsMortgageReports,
          icon: Icons.account_balance_outlined,
        ),
      ],
      activeSection: _group,
      onSectionChanged: (v) => setState(() => _group = v),
      onRefresh: _refresh,
      body: _body(),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.reportsSearchHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          tooltip: l10n.commonFilters,
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }

  Widget _body() {
    final async = ref.watch(reportsProvider(_query));
    return AppStateView<ReportsData>(
      value: async,
      onRetry: () => ref.invalidate(reportsProvider(_query)),
      data: (data) => ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: _sectionsFor(data)
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: s,
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _sectionsFor(ReportsData data) {
    final l10n = AppLocalizations.of(context)!;
    switch (_group) {
      case 'billing':
        final dailyTotal = data.dailySales.fold<double>(
          0,
          (s, i) => s + i.grandTotal,
        );
        final monthlyTotal = data.monthlySales.fold<double>(
          0,
          (s, i) => s + i.grandTotal,
        );
        final gstTotal = data.gst.fold<double>(0, (s, i) => s + i.totalTax);
        return [
          ReportSection(
            title: l10n.reportsDailySales,
            subtitle: _salesOn(l10n),
            emptyText: l10n.reportsNoSalesDay,
            rows: data.dailySales.map((i) => _salesRow(l10n, i)).toList(),
            metricValue: reportMoney(dailyTotal),
            metricColor: AppColors.success,
            onExport: () => _export('daily-sales'),
          ),
          ReportSection(
            title: l10n.reportsMonthlySales,
            subtitle: _salesIn(l10n),
            emptyText: l10n.reportsNoSalesMonth,
            rows: data.monthlySales.map((i) => _salesRow(l10n, i)).toList(),
            metricValue: reportMoney(monthlyTotal),
            metricColor: AppColors.primary,
            onExport: () => _export('monthly-sales'),
          ),
          ReportSection(
            title: l10n.reportsGst,
            subtitle: l10n.reportsGstSubtitle,
            emptyText: l10n.reportsNoGstData,
            rows: data.gst.map((i) => _gstRow(l10n, i)).toList(),
            metricValue: reportMoney(gstTotal),
            metricColor: AppColors.warning,
            onExport: () => _export('gst'),
          ),
        ];
      case 'mortgage':
        final interestTotal = data.interestCollection.fold<double>(
          0,
          (s, i) => s + i.amount,
        );
        return [
          ReportSection(
            title: l10n.reportsActiveLoans,
            subtitle: l10n.reportsActiveLoansSubtitle,
            emptyText: l10n.reportsNoActiveLoans,
            rows: data.activeLoans.map((i) => _activeLoanRow(l10n, i)).toList(),
            metricValue: '${data.activeLoans.length}',
            metricColor: AppColors.info,
            onExport: () => _export('active-loans'),
          ),
          ReportSection(
            title: l10n.reportsInterestCollection,
            subtitle: l10n.reportsInterestCollectionSubtitle,
            emptyText: l10n.reportsNoInterestCollections,
            rows: data.interestCollection
                .map((i) => _interestRow(l10n, i))
                .toList(),
            metricValue: reportMoney(interestTotal),
            metricColor: AppColors.success,
            onExport: () => _export('interest-collection'),
          ),
          ReportSection(
            title: l10n.reportsClosedLoans,
            subtitle: l10n.reportsClosedLoansSubtitle,
            emptyText: l10n.reportsNoClosedLoans,
            rows: data.closedLoans.map((i) => _closedLoanRow(l10n, i)).toList(),
            metricValue: '${data.closedLoans.length}',
            metricColor: AppColors.primary,
            onExport: () => _export('closed-loans'),
          ),
        ];
      default:
        return [
          ReportSection(
            title: l10n.reportsCurrentStock,
            subtitle: l10n.reportsCurrentStockSubtitle(
              reportWeight(data.totalGoldWeight),
              reportWeight(data.totalSilverWeight),
            ),
            emptyText: l10n.reportsNoCurrentStock,
            rows: data.currentStock.map((i) => _stockRow(l10n, i)).toList(),
            metricValue: '${data.currentStock.length}',
            metricColor: AppColors.info,
            onExport: () => _export('current-stock'),
          ),
          ReportSection(
            title: l10n.reportsSoldProducts,
            subtitle: l10n.reportsSoldProductsSubtitle,
            emptyText: l10n.reportsNoSoldProducts,
            rows: data.soldProducts.map((i) => _soldRow(l10n, i)).toList(),
            metricValue: '${data.soldProducts.length}',
            metricColor: AppColors.success,
            onExport: () => _export('sold-products'),
          ),
          ReportSection(
            title: l10n.reportsLowStock,
            subtitle: l10n.reportsLowStockSubtitle,
            emptyText: l10n.reportsNoLowStock,
            rows: data.lowStock.map((i) => _lowStockRow(l10n, i)).toList(),
            metricValue: '${data.lowStock.length}',
            metricColor: AppColors.warning,
            onExport: () => _export('low-stock'),
          ),
        ];
    }
  }

  // ---- typed model → ReportRow view-model mappers ------------------------

  ReportRow _stockRow(
    AppLocalizations l10n,
    InventoryReportItem i,
  ) => ReportRow(
    leadingIcon: Icons.diamond_outlined,
    title: reportFallback(i.itemName, l10n.reportsProduct),
    subtitle:
        '${reportFallback(i.categoryName, l10n.reportsUncategorised)} • ${reportFallback(i.designTag, l10n.reportsNoDesignNumber)}',
    statusLabel: reportReadableStatus(i.status),
    metrics: [
      (l10n.reportsPurity, reportFallback(i.karatOrPurity, '-')),
      (l10n.reportsNet, reportWeight(i.netWeight)),
      (l10n.reportsSellingPrice, reportMoney(i.sellingPrice)),
    ],
  );

  ReportRow _lowStockRow(
    AppLocalizations l10n,
    InventoryReportItem i,
  ) => ReportRow(
    leadingIcon: Icons.warning_amber_rounded,
    title: reportFallback(i.itemName, l10n.reportsProduct),
    subtitle:
        '${reportFallback(i.categoryName, l10n.reportsUncategorised)} • ${reportFallback(i.designTag, l10n.reportsNoDesignNumber)}',
    statusLabel: l10n.reportsLowStock,
    statusColor: AppColors.warning,
    metrics: [
      (l10n.reportsAvailableQty, '${i.quantity}'),
      (l10n.reportsPurity, reportFallback(i.karatOrPurity, '-')),
      (l10n.reportsBranch, reportFallback(i.location, l10n.reportsMain)),
    ],
  );

  ReportRow _soldRow(AppLocalizations l10n, SoldReportItem i) => ReportRow(
    leadingIcon: Icons.shopping_bag_outlined,
    title: reportFallback(i.productName, l10n.reportsProduct),
    subtitle:
        '${reportFallback(i.invoiceNumber, l10n.reportsInvoice)} • ${reportFallback(i.customerName, l10n.reportsCustomer)}',
    statusLabel: reportFallback(i.paymentMode, l10n.reportsPayment),
    metrics: [
      (l10n.reportsSoldDate, reportDate(i.soldDate)),
      (l10n.reportsSellingPrice, reportMoney(i.sellingPrice)),
    ],
  );

  ReportRow _salesRow(AppLocalizations l10n, InvoiceSalesReportItem i) =>
      ReportRow(
        leadingIcon: Icons.receipt_long_outlined,
        title: reportFallback(i.invoiceNumber, l10n.reportsInvoice),
        subtitle: reportFallback(i.customerName, l10n.customerWalkIn),
        statusLabel: reportFallback(i.paymentMode, '-'),
        metrics: [
          (l10n.reportsDate, reportDate(i.invoiceDate)),
          (l10n.reportsTotal, reportMoney(i.grandTotal)),
          (l10n.reportsItems, '${i.itemCount}'),
        ],
      );

  ReportRow _gstRow(AppLocalizations l10n, GstReportItem i) => ReportRow(
    leadingIcon: Icons.percent_rounded,
    title: reportFallback(i.invoiceNumber, l10n.reportsInvoice),
    subtitle: reportFallback(i.customerName, l10n.customerWalkIn),
    statusLabel: l10n.reportsGst,
    statusColor: AppColors.warning,
    metrics: [
      (l10n.reportsTaxable, reportMoney(i.taxableAmount)),
      (l10n.reportsCgst, reportMoney(i.cgstAmount)),
      (l10n.reportsSgst, reportMoney(i.sgstAmount)),
      (l10n.reportsTotalGst, reportMoney(i.totalTax)),
    ],
  );

  ReportRow _activeLoanRow(AppLocalizations l10n, ActiveLoanReportItem i) =>
      ReportRow(
        leadingIcon: Icons.account_balance_outlined,
        title: reportFallback(i.customerName, l10n.reportsCustomer),
        subtitle: reportFallback(i.loanNumber, l10n.reportsMortgageLoan),
        statusLabel: l10n.mortgageStatusActive,
        statusColor: AppColors.info,
        metrics: [
          (l10n.reportsLoanAmount, reportMoney(i.principalAmount)),
          (l10n.reportsPendingInterest, reportMoney(i.pendingInterestAmount)),
          (l10n.reportsNextDue, reportDate(i.nextDueDate)),
        ],
      );

  ReportRow _interestRow(
    AppLocalizations l10n,
    InterestCollectionReportItem i,
  ) => ReportRow(
    leadingIcon: Icons.payments_outlined,
    title: reportFallback(i.receiptNumber, l10n.reportsReceipt),
    subtitle:
        '${reportFallback(i.customerName, l10n.reportsCustomer)} • ${reportFallback(i.loanNumber, l10n.reportsMortgageLoan)}',
    statusLabel: reportReadableStatus(i.paymentType),
    statusColor: AppColors.success,
    metrics: [
      (l10n.reportsDate, reportDate(i.paymentDate)),
      (l10n.reportsAmount, reportMoney(i.amount)),
      (l10n.reportsMode, reportFallback(i.paymentMode, '-')),
    ],
  );

  ReportRow _closedLoanRow(AppLocalizations l10n, ClosedLoanReportItem i) =>
      ReportRow(
        leadingIcon: Icons.check_circle_outline_rounded,
        title: reportFallback(i.customerName, l10n.reportsCustomer),
        subtitle: reportFallback(i.loanNumber, l10n.reportsMortgageLoan),
        statusLabel: reportReadableStatus(i.status),
        statusColor: AppColors.success,
        metrics: [
          (l10n.reportsLoanAmount, reportMoney(i.principalAmount)),
          (l10n.reportsInterestPaid, reportMoney(i.totalInterestPaid)),
          (l10n.reportsClosingDate, reportDate(i.closedAt)),
        ],
      );

  String _salesOn(AppLocalizations l10n) {
    final date = DateTime.tryParse(_query.dateFrom) ?? DateTime.now();
    return l10n.reportsSalesGeneratedOn(DateFormat('dd MMM yyyy').format(date));
  }

  String _salesIn(AppLocalizations l10n) {
    final date = DateTime.tryParse(_query.dateFrom) ?? DateTime.now();
    return l10n.reportsSalesGeneratedIn(DateFormat('MMMM yyyy').format(date));
  }
}
