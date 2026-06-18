import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/reports/application/report_export_payloads.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  Timer? _filterDebounce;

  bool _isLoading = true;
  bool _canViewReports = false;
  String _activeGroup = 'inventory';
  String _statusFilter = 'all';
  List<Map<String, dynamic>> _currentStockRows = [];
  List<Map<String, dynamic>> _soldProductsRows = [];
  List<Map<String, dynamic>> _lowStockRows = [];
  List<Map<String, dynamic>> _dailySalesRows = [];
  List<Map<String, dynamic>> _monthlySalesRows = [];
  List<Map<String, dynamic>> _gstRows = [];
  List<Map<String, dynamic>> _activeLoansRows = [];
  List<Map<String, dynamic>> _interestCollectionRows = [];
  List<Map<String, dynamic>> _closedLoansRows = [];
  Map<String, dynamic> _inventoryStats = {};

  @override
  void initState() {
    super.initState();
    _loadRoleAndReports();
  }

  @override
  void dispose() {
    _filterDebounce?.cancel();
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _categoryController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoleAndReports() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final role = await fetchCurrentUserRole(_api);
      if (!mounted) return;
      _canViewReports = isAdminRole(role);
      if (!_canViewReports) {
        setState(() => _isLoading = false);
        return;
      }
      await _loadReports();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, l10n.errorFailedLoadDashboard);
    }
  }

  Future<void> _loadReports() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canViewReports) return;
    try {
      final response = await _api.dio.get(
        '/reports/overview',
        queryParameters: _reportQueryParameters(),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final reports = payload['reports'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;
      setState(() {
        _currentStockRows = _mapList(reports['currentStock']);
        _soldProductsRows = _mapList(reports['soldProducts']);
        _lowStockRows = _mapList(reports['lowStock']);
        _dailySalesRows = _mapList(reports['dailySales']);
        _monthlySalesRows = _mapList(reports['monthlySales']);
        _gstRows = _mapList(reports['gst']);
        _activeLoansRows = _mapList(reports['activeLoans']);
        _interestCollectionRows = _mapList(reports['interestCollection']);
        _closedLoansRows = _mapList(reports['closedLoans']);
        _inventoryStats =
            payload['inventoryStats'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, l10n.errorFailedLoadDashboard);
    }
  }

  Map<String, dynamic>? _reportQueryParameters() {
    final params = <String, dynamic>{
      if (_searchController.text.trim().isNotEmpty)
        'search': _searchController.text.trim(),
      if (_dateFromController.text.trim().isNotEmpty)
        'dateFrom': _dateFromController.text.trim(),
      if (_dateToController.text.trim().isNotEmpty)
        'dateTo': _dateToController.text.trim(),
      if (_categoryController.text.trim().isNotEmpty)
        'categoryName': _categoryController.text.trim(),
      if (_branchController.text.trim().isNotEmpty)
        'branch': _branchController.text.trim(),
      if (_statusFilter != 'all') 'status': _statusFilter,
    };
    return params.isEmpty ? null : params;
  }

  void _onFilterChanged(String _) {
    setState(() {});
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 350), _loadReports);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    return (value as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  List<Map<String, dynamic>> get _currentStockReport {
    return _currentStockRows;
  }

  List<Map<String, dynamic>> get _lowStockReport {
    return _lowStockRows;
  }

  List<Map<String, dynamic>> get _soldProductsReport {
    return _soldProductsRows;
  }

  List<Map<String, dynamic>> get _dailySalesReport {
    return _dailySalesRows;
  }

  List<Map<String, dynamic>> get _monthlySalesReport {
    return _monthlySalesRows;
  }

  List<Map<String, dynamic>> get _gstReport => _gstRows;

  List<Map<String, dynamic>> get _activeLoansReport {
    return _activeLoansRows;
  }

  List<Map<String, dynamic>> get _closedLoansReport {
    return _closedLoansRows;
  }

  List<Map<String, dynamic>> get _interestCollectionReport {
    return _interestCollectionRows;
  }

  Future<void> _exportReport(String reportType) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await _api.dio.get(
        '/reports/export/$reportType',
        queryParameters: _reportQueryParameters(),
      );
      final payload = decodeReportPdfPayload(
        Map<String, dynamic>.from(response.data as Map),
        fallbackFileName: '$reportType-report.pdf',
      );
      await Printing.sharePdf(bytes: payload.bytes, filename: payload.fileName);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.errorFailedLoadDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width > 768;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canViewReports) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l10n.reportsAdminOnly,
        subtitle: l10n.reportsStaffSubtitle,
        iconColor: AppColors.warning,
      );
    }

    return KeyboardDismissRegion(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadReports,
        child: KeyboardAwareScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isWide),
              const SizedBox(height: AppSpacing.lg),
              _buildFilters(isWide),
              const SizedBox(height: AppSpacing.md),
              _buildGroupSwitch(),
              const SizedBox(height: AppSpacing.lg),
              _buildActiveSummary(isWide),
              const SizedBox(height: AppSpacing.lg),
              _buildActiveReport(isWide),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportsTitle,
          style: isWide
              ? Theme.of(context).textTheme.displaySmall
              : Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (isWide) ...[
          const SizedBox(height: 6),
          Text(
            l10n.reportsSubtitle,
            style: TextStyle(color: AppColors.text3(context)),
          ),
        ],
      ],
    );
  }

  Widget _buildFilters(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    return SearchFilterBar(
      searchController: _searchController,
      onSearchChanged: _onFilterChanged,
      searchHint: l10n.reportsSearchHint,
      onRefresh: _loadReports,
      isLoading: _isLoading,
      filterBuilder: (_) => [
        SizedBox(
          width: 170,
          child: TextField(
            controller: _dateFromController,
            onChanged: _onFilterChanged,
            decoration: InputDecoration(
              labelText: l10n.reportsFromDate,
              hintText: l10n.reportsDateHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: TextField(
            controller: _dateToController,
            onChanged: _onFilterChanged,
            decoration: InputDecoration(
              labelText: l10n.reportsToDate,
              hintText: l10n.reportsDateHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: TextField(
            controller: _categoryController,
            onChanged: _onFilterChanged,
            decoration: InputDecoration(
              labelText: l10n.reportsCategory,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: TextField(
            controller: _branchController,
            onChanged: _onFilterChanged,
            decoration: InputDecoration(
              labelText: l10n.reportsBranch,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              isDense: true,
            ),
          ),
        ),
        FilterDropdown<String>(
          value: _statusFilter,
          label: l10n.reportsStatus,
          width: 180,
          onChanged: (value) {
            setState(() => _statusFilter = value ?? 'all');
            _loadReports();
          },
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
        ),
      ],
    );
  }

  Widget _buildGroupSwitch() {
    final l10n = AppLocalizations.of(context)!;
    return SectionSwitch(
      activeValue: _activeGroup,
      onChanged: (value) => setState(() => _activeGroup = value),
      items: [
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
    );
  }

  Widget _buildActiveSummary(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    switch (_activeGroup) {
      case 'billing':
        return _buildSummaryGrid([
          _ReportMetric(
            icon: Icons.today_outlined,
            label: l10n.reportsDailySales,
            value: _money(_dailySalesTotal),
            color: AppColors.success,
          ),
          _ReportMetric(
            icon: Icons.calendar_month_outlined,
            label: l10n.reportsMonthlySales,
            value: _money(_monthlySalesTotal),
            color: AppColors.primary,
          ),
          _ReportMetric(
            icon: Icons.percent_rounded,
            label: l10n.reportsGst,
            value: _money(_gstTotal),
            color: AppColors.warning,
          ),
        ]);
      case 'mortgage':
        return _buildSummaryGrid([
          _ReportMetric(
            icon: Icons.pending_actions_rounded,
            label: l10n.reportsActiveLoans,
            value: _activeLoansReport.length.toString(),
            color: AppColors.info,
          ),
          _ReportMetric(
            icon: Icons.payments_outlined,
            label: l10n.reportsInterestCollection,
            value: _money(_interestCollectionTotal),
            color: AppColors.success,
          ),
          _ReportMetric(
            icon: Icons.check_circle_outline_rounded,
            label: l10n.reportsClosedLoans,
            value: _closedLoansReport.length.toString(),
            color: AppColors.primary,
          ),
        ]);
      default:
        return _buildSummaryGrid([
          _ReportMetric(
            icon: Icons.inventory_2_outlined,
            label: l10n.reportsCurrentStock,
            value: _currentStockReport.length.toString(),
            color: AppColors.info,
          ),
          _ReportMetric(
            icon: Icons.shopping_bag_outlined,
            label: l10n.reportsSoldProducts,
            value: _soldProductsReport.length.toString(),
            color: AppColors.success,
          ),
          _ReportMetric(
            icon: Icons.warning_amber_rounded,
            label: l10n.reportsLowStock,
            value: _lowStockReport.length.toString(),
            color: AppColors.warning,
          ),
        ]);
    }
  }

  Widget _buildSummaryGrid(List<_ReportMetric> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 620 ? 2 : 1);
        final width =
            (constraints.maxWidth - ((count - 1) * AppSpacing.md)) / count;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: StatCard(
                  icon: metric.icon,
                  label: metric.label,
                  value: metric.value,
                  accentColor: metric.color,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActiveReport(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    switch (_activeGroup) {
      case 'billing':
        return Column(
          children: [
            _ReportSection(
              title: l10n.reportsDailySales,
              subtitle: _dailySalesSubtitle,
              emptyText: l10n.reportsNoSalesDay,
              rows: _dailySalesReport.map(_dailySalesRow).toList(),
              onExport: () => _exportReport('daily-sales'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: l10n.reportsMonthlySales,
              subtitle: _monthlySalesSubtitle,
              emptyText: l10n.reportsNoSalesMonth,
              rows: _monthlySalesReport.map(_monthlySalesRow).toList(),
              onExport: () => _exportReport('monthly-sales'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: l10n.reportsGst,
              subtitle: l10n.reportsGstSubtitle,
              emptyText: l10n.reportsNoGstData,
              rows: _gstReport.map(_gstRow).toList(),
              onExport: () => _exportReport('gst'),
            ),
          ],
        );
      case 'mortgage':
        return Column(
          children: [
            _ReportSection(
              title: l10n.reportsActiveLoans,
              subtitle: l10n.reportsActiveLoansSubtitle,
              emptyText: l10n.reportsNoActiveLoans,
              rows: _activeLoansReport.map(_activeLoanRow).toList(),
              onExport: () => _exportReport('active-loans'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: l10n.reportsInterestCollection,
              subtitle: l10n.reportsInterestCollectionSubtitle,
              emptyText: l10n.reportsNoInterestCollections,
              rows: _interestCollectionReport
                  .map(_interestCollectionRow)
                  .toList(),
              onExport: () => _exportReport('interest-collection'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: l10n.reportsClosedLoans,
              subtitle: l10n.reportsClosedLoansSubtitle,
              emptyText: l10n.reportsNoClosedLoans,
              rows: _closedLoansReport.map(_closedLoanRow).toList(),
              onExport: () => _exportReport('closed-loans'),
            ),
          ],
        );
      default:
        return Column(
          children: [
            _ReportSection(
              title: l10n.reportsCurrentStock,
              subtitle: l10n.reportsCurrentStockSubtitle(
                _weight(_inventoryStats['totalGoldWeight']),
                _weight(_inventoryStats['totalSilverWeight']),
              ),
              emptyText: l10n.reportsNoCurrentStock,
              rows: _currentStockReport.map(_currentStockRow).toList(),
              onExport: () => _exportReport('current-stock'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: l10n.reportsSoldProducts,
              subtitle: l10n.reportsSoldProductsSubtitle,
              emptyText: l10n.reportsNoSoldProducts,
              rows: _soldProductsReport.map(_soldProductRow).toList(),
              onExport: () => _exportReport('sold-products'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: l10n.reportsLowStock,
              subtitle: l10n.reportsLowStockSubtitle,
              emptyText: l10n.reportsNoLowStock,
              rows: _lowStockReport.map(_lowStockRow).toList(),
              onExport: () => _exportReport('low-stock'),
            ),
          ],
        );
    }
  }

  _ReportRow _currentStockRow(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final productName = _fallback(item['itemName'], l10n.reportsProduct);
    return _ReportRow(
      leadingIcon: Icons.diamond_outlined,
      title: productName,
      subtitle:
          '${_fallback(item['categoryName'], l10n.reportsUncategorised)} • ${_fallback(item['tagNumber'] ?? item['barcode'], l10n.reportsNoDesignNumber)}',
      statusLabel: _readableStatus(item['status']),
      metrics: [
        _ReportCell(
          l10n.reportsPurity,
          _fallback(item['karat'] ?? item['purity'], '-'),
        ),
        _ReportCell(l10n.reportsGross, _weight(item['grossWeight'])),
        _ReportCell(l10n.reportsNet, _weight(item['netWeight'])),
        _ReportCell(
          l10n.reportsSellingPrice,
          _money(item['estimatedSellingPrice']),
        ),
        _ReportCell(
          l10n.reportsBranch,
          _fallback(item['location'], l10n.reportsMain),
        ),
      ],
    );
  }

  _ReportRow _soldProductRow(Map<String, dynamic> row) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportRow(
      leadingIcon: Icons.shopping_bag_outlined,
      title: _fallback(row['productName'], l10n.reportsProduct),
      subtitle:
          '${_fallback(row['invoiceNumber'], l10n.reportsInvoice)} • ${_fallback(row['customerName'], l10n.reportsCustomer)}',
      statusLabel: _fallback(row['paymentMode'], l10n.reportsPayment),
      metrics: [
        _ReportCell(l10n.reportsSoldDate, _formatDate(row['soldDate'])),
        _ReportCell(l10n.reportsSellingPrice, _money(row['sellingPrice'])),
        _ReportCell(l10n.reportsMobile, _fallback(row['customerPhone'], '-')),
      ],
    );
  }

  _ReportRow _lowStockRow(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportRow(
      leadingIcon: Icons.warning_amber_rounded,
      title: _fallback(item['itemName'], l10n.reportsProduct),
      subtitle:
          '${_fallback(item['categoryName'], l10n.reportsUncategorised)} • ${_fallback(item['tagNumber'] ?? item['barcode'], l10n.reportsNoDesignNumber)}',
      statusLabel: l10n.reportsLowStock,
      statusColor: AppColors.warning,
      metrics: [
        _ReportCell(
          l10n.reportsAvailableQty,
          _asInt(item['quantity']).toString(),
        ),
        _ReportCell(
          l10n.reportsPurity,
          _fallback(item['karat'] ?? item['purity'], '-'),
        ),
        _ReportCell(
          l10n.reportsBranch,
          _fallback(item['location'], l10n.reportsMain),
        ),
      ],
    );
  }

  _ReportRow _dailySalesRow(Map<String, dynamic> invoice) {
    return _invoiceSalesRow(invoice, 'Daily Sale');
  }

  _ReportRow _monthlySalesRow(Map<String, dynamic> invoice) {
    return _invoiceSalesRow(invoice, 'Monthly Sale');
  }

  _ReportRow _invoiceSalesRow(Map<String, dynamic> invoice, String label) {
    final l10n = AppLocalizations.of(context)!;
    final items = _mapList(invoice['items']);
    return _ReportRow(
      leadingIcon: Icons.receipt_long_outlined,
      title: _fallback(invoice['invoiceNumber'], l10n.reportsInvoice),
      subtitle: _fallback(invoice['customerName'], l10n.customerWalkIn),
      statusLabel: label,
      metrics: [
        _ReportCell(l10n.reportsDate, _formatDate(invoice['invoiceDate'])),
        _ReportCell(l10n.reportsTotal, _money(invoice['grandTotal'])),
        _ReportCell(
          l10n.reportsPayment,
          _fallback(invoice['paymentMode'], '-'),
        ),
        _ReportCell(l10n.reportsItems, items.length.toString()),
      ],
    );
  }

  _ReportRow _gstRow(Map<String, dynamic> invoice) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportRow(
      leadingIcon: Icons.percent_rounded,
      title: _fallback(invoice['invoiceNumber'], l10n.reportsInvoice),
      subtitle: _fallback(invoice['customerName'], l10n.customerWalkIn),
      statusLabel: l10n.reportsGst,
      statusColor: AppColors.warning,
      metrics: [
        _ReportCell(l10n.reportsTaxable, _money(invoice['taxableAmount'])),
        _ReportCell(l10n.reportsCgst, _money(invoice['cgstAmount'])),
        _ReportCell(l10n.reportsSgst, _money(invoice['sgstAmount'])),
        _ReportCell(l10n.reportsTotalGst, _money(invoice['totalTax'])),
      ],
    );
  }

  _ReportRow _activeLoanRow(Map<String, dynamic> loan) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportRow(
      leadingIcon: Icons.account_balance_outlined,
      title: _fallback(loan['customerName'], l10n.reportsCustomer),
      subtitle: _fallback(loan['loanNumber'], l10n.reportsMortgageLoan),
      statusLabel: l10n.mortgageStatusActive,
      statusColor: AppColors.info,
      metrics: [
        _ReportCell(l10n.reportsLoanAmount, _money(loan['principalAmount'])),
        _ReportCell(
          l10n.reportsPendingInterest,
          _money(loan['pendingInterestAmount']),
        ),
        _ReportCell(l10n.reportsPayable, _money(loan['totalPayableAmount'])),
        _ReportCell(l10n.reportsNextDue, _formatDate(loan['nextDueDate'])),
      ],
    );
  }

  _ReportRow _interestCollectionRow(Map<String, dynamic> row) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportRow(
      leadingIcon: Icons.payments_outlined,
      title: _fallback(row['receiptNumber'], l10n.reportsReceipt),
      subtitle:
          '${_fallback(row['customerName'], l10n.reportsCustomer)} • ${_fallback(row['loanNumber'], l10n.reportsMortgageLoan)}',
      statusLabel: _readableStatus(row['paymentType']),
      statusColor: AppColors.success,
      metrics: [
        _ReportCell(l10n.reportsDate, _formatDate(row['paymentDate'])),
        _ReportCell(l10n.reportsAmount, _money(row['amount'])),
        _ReportCell(l10n.reportsMode, _fallback(row['paymentMode'], '-')),
        _ReportCell(l10n.reportsMobile, _fallback(row['customerPhone'], '-')),
      ],
    );
  }

  _ReportRow _closedLoanRow(Map<String, dynamic> loan) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportRow(
      leadingIcon: Icons.check_circle_outline_rounded,
      title: _fallback(loan['customerName'], l10n.reportsCustomer),
      subtitle: _fallback(loan['loanNumber'], l10n.reportsMortgageLoan),
      statusLabel: _readableStatus(loan['status']),
      statusColor: AppColors.success,
      metrics: [
        _ReportCell(l10n.reportsLoanAmount, _money(loan['principalAmount'])),
        _ReportCell(
          l10n.reportsInterestPaid,
          _money(loan['totalInterestPaid']),
        ),
        _ReportCell(l10n.reportsClosingDate, _formatDate(loan['closedAt'])),
        _ReportCell(l10n.reportsLoanStatus, _readableStatus(loan['status'])),
      ],
    );
  }

  double get _dailySalesTotal => _dailySalesReport.fold(
    0,
    (sum, invoice) => sum + _asDouble(invoice['grandTotal']),
  );

  double get _monthlySalesTotal => _monthlySalesReport.fold(
    0,
    (sum, invoice) => sum + _asDouble(invoice['grandTotal']),
  );

  double get _gstTotal => _gstReport.fold(
    0,
    (sum, invoice) => sum + _asDouble(invoice['totalTax']),
  );

  double get _interestCollectionTotal => _interestCollectionReport.fold(
    0,
    (sum, payment) => sum + _asDouble(payment['amount']),
  );

  String get _dailySalesSubtitle {
    final l10n = AppLocalizations.of(context)!;
    final date = _parseDate(_dateFromController.text) ?? DateTime.now();
    return l10n.reportsSalesGeneratedOn(DateFormat('dd MMM yyyy').format(date));
  }

  String get _monthlySalesSubtitle {
    final l10n = AppLocalizations.of(context)!;
    final date = _parseDate(_dateFromController.text) ?? DateTime.now();
    return l10n.reportsSalesGeneratedIn(DateFormat('MMMM yyyy').format(date));
  }

  DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return _currency.format(_asDouble(value));
  }

  String _weight(dynamic value) {
    final weight = _asDouble(value);
    if (weight == 0) return '0g';
    return '${weight.toStringAsFixed(3)}g';
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _fallback(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  String _readableStatus(dynamic value) {
    final text = _fallback(value, '-');
    return text
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _ReportMetric {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReportMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ReportCell {
  final String label;
  final String value;

  const _ReportCell(this.label, this.value);
}

class _ReportRow {
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color? statusColor;
  final List<_ReportCell> metrics;

  const _ReportRow({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.statusColor,
    required this.metrics,
  });
}

class _ReportSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyText;
  final List<_ReportRow> rows;
  final VoidCallback? onExport;

  const _ReportSection({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.rows,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  ],
                ),
              ),
              Text(
                rows.length.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExportMenu(onExportPdf: onExport),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfL(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.brd(context)),
              ),
              child: Text(
                emptyText,
                style: TextStyle(color: AppColors.text3(context)),
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _ReportRowTile(row: rows[index]),
            ),
        ],
      ),
    );
  }
}

class _ReportRowTile extends StatelessWidget {
  final _ReportRow row;

  const _ReportRowTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  row.leadingIcon,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.text1(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      row.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.text3(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: row.statusLabel, color: row.statusColor),
            ],
          ),
          if (row.metrics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final metric in row.metrics)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${metric.label}: ',
                        style: TextStyle(
                          color: AppColors.text3(context),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        metric.value,
                        style: TextStyle(
                          color: AppColors.text1(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
