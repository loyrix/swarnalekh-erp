import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/reports/application/report_export_payloads.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

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
      AppToast.error(context, 'Failed to load reports');
    }
  }

  Future<void> _loadReports() async {
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
      AppToast.error(context, 'Failed to load reports');
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
      AppToast.error(context, 'Failed to export report');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canViewReports) {
      return const EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Reports are for Admin users',
        subtitle:
            'Staff can continue using Billing, Inventory View, and Mortgage collections.',
        iconColor: AppColors.warning,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(),
            const SizedBox(height: AppSpacing.md),
            _buildGroupSwitch(),
            const SizedBox(height: AppSpacing.lg),
            _buildActiveSummary(),
            const SizedBox(height: AppSpacing.lg),
            _buildActiveReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reports', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Inventory, billing, GST, and mortgage reports from the Jewellery ERP flow.',
          style: TextStyle(color: AppColors.text3(context)),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              onChanged: _onFilterChanged,
              decoration: InputDecoration(
                hintText:
                    'Search product, design, customer, invoice, or mobile',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.text3(context),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: TextField(
              controller: _dateFromController,
              onChanged: _onFilterChanged,
              decoration: const InputDecoration(
                labelText: 'From date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: TextField(
              controller: _dateToController,
              onChanged: _onFilterChanged,
              decoration: const InputDecoration(
                labelText: 'To date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: TextField(
              controller: _categoryController,
              onChanged: _onFilterChanged,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: TextField(
              controller: _branchController,
              onChanged: _onFilterChanged,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'in_stock', child: Text('In Stock')),
                DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                DropdownMenuItem(value: 'sold', child: Text('Sold')),
                DropdownMenuItem(value: 'active', child: Text('Active Loan')),
                DropdownMenuItem(value: 'closed', child: Text('Closed Loan')),
              ],
              onChanged: (value) {
                setState(() => _statusFilter = value ?? 'all');
                _loadReports();
              },
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Refresh reports',
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSwitch() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _groupChip(
          'inventory',
          'Inventory Reports',
          Icons.inventory_2_outlined,
        ),
        _groupChip('billing', 'Billing Reports', Icons.receipt_long_outlined),
        _groupChip(
          'mortgage',
          'Mortgage Reports',
          Icons.account_balance_outlined,
        ),
      ],
    );
  }

  Widget _groupChip(String value, String label, IconData icon) {
    final selected = _activeGroup == value;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.primary : AppColors.text2(context),
      ),
      label: Text(label),
      onSelected: (_) => setState(() => _activeGroup = value),
    );
  }

  Widget _buildActiveSummary() {
    switch (_activeGroup) {
      case 'billing':
        return _buildSummaryGrid([
          _ReportMetric(
            icon: Icons.today_outlined,
            label: 'Daily Sales Report',
            value: _money(_dailySalesTotal),
            color: AppColors.success,
          ),
          _ReportMetric(
            icon: Icons.calendar_month_outlined,
            label: 'Monthly Sales Report',
            value: _money(_monthlySalesTotal),
            color: AppColors.primary,
          ),
          _ReportMetric(
            icon: Icons.percent_rounded,
            label: 'GST Report',
            value: _money(_gstTotal),
            color: AppColors.warning,
          ),
        ]);
      case 'mortgage':
        return _buildSummaryGrid([
          _ReportMetric(
            icon: Icons.pending_actions_rounded,
            label: 'Active Loans Report',
            value: _activeLoansReport.length.toString(),
            color: AppColors.info,
          ),
          _ReportMetric(
            icon: Icons.payments_outlined,
            label: 'Interest Collection Report',
            value: _money(_interestCollectionTotal),
            color: AppColors.success,
          ),
          _ReportMetric(
            icon: Icons.check_circle_outline_rounded,
            label: 'Closed Loans Report',
            value: _closedLoansReport.length.toString(),
            color: AppColors.primary,
          ),
        ]);
      default:
        return _buildSummaryGrid([
          _ReportMetric(
            icon: Icons.inventory_2_outlined,
            label: 'Current Stock Report',
            value: _currentStockReport.length.toString(),
            color: AppColors.info,
          ),
          _ReportMetric(
            icon: Icons.shopping_bag_outlined,
            label: 'Sold Products Report',
            value: _soldProductsReport.length.toString(),
            color: AppColors.success,
          ),
          _ReportMetric(
            icon: Icons.warning_amber_rounded,
            label: 'Low Stock Report',
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

  Widget _buildActiveReport() {
    switch (_activeGroup) {
      case 'billing':
        return Column(
          children: [
            _ReportSection(
              title: 'Daily Sales Report',
              subtitle: _dailySalesSubtitle,
              emptyText: 'No sales found for this day.',
              rows: _dailySalesReport.map(_dailySalesRow).toList(),
              onExport: () => _exportReport('daily-sales'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: 'Monthly Sales Report',
              subtitle: _monthlySalesSubtitle,
              emptyText: 'No sales found for this month.',
              rows: _monthlySalesReport.map(_monthlySalesRow).toList(),
              onExport: () => _exportReport('monthly-sales'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: 'GST Report',
              subtitle: 'Tax collected from filtered invoice history.',
              emptyText: 'No GST data found.',
              rows: _gstReport.map(_gstRow).toList(),
              onExport: () => _exportReport('gst'),
            ),
          ],
        );
      case 'mortgage':
        return Column(
          children: [
            _ReportSection(
              title: 'Active Loans Report',
              subtitle: 'Open gold loans with pending balances and due dates.',
              emptyText: 'No active loans found.',
              rows: _activeLoansReport.map(_activeLoanRow).toList(),
              onExport: () => _exportReport('active-loans'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: 'Interest Collection Report',
              subtitle:
                  'Receipts generated for interest and settlement payments.',
              emptyText: 'No interest collections found.',
              rows: _interestCollectionReport
                  .map(_interestCollectionRow)
                  .toList(),
              onExport: () => _exportReport('interest-collection'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: 'Closed Loans Report',
              subtitle: 'Settled loans moved out of active mortgage tracking.',
              emptyText: 'No closed loans found.',
              rows: _closedLoansReport.map(_closedLoanRow).toList(),
              onExport: () => _exportReport('closed-loans'),
            ),
          ],
        );
      default:
        return Column(
          children: [
            _ReportSection(
              title: 'Current Stock Report',
              subtitle:
                  '${_weight(_inventoryStats['totalGoldWeight'])} gold, ${_weight(_inventoryStats['totalSilverWeight'])} silver in stock.',
              emptyText: 'No current stock found.',
              rows: _currentStockReport.map(_currentStockRow).toList(),
              onExport: () => _exportReport('current-stock'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: 'Sold Products Report',
              subtitle: 'Sold products linked to invoice history.',
              emptyText: 'No sold products found.',
              rows: _soldProductsReport.map(_soldProductRow).toList(),
              onExport: () => _exportReport('sold-products'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportSection(
              title: 'Low Stock Report',
              subtitle: 'Bulk products with two or fewer units available.',
              emptyText: 'No low stock products found.',
              rows: _lowStockReport.map(_lowStockRow).toList(),
              onExport: () => _exportReport('low-stock'),
            ),
          ],
        );
    }
  }

  _ReportRow _currentStockRow(Map<String, dynamic> item) {
    final productName = _fallback(item['itemName'], 'Product');
    return _ReportRow(
      leadingIcon: Icons.diamond_outlined,
      title: productName,
      subtitle:
          '${_fallback(item['categoryName'], 'Uncategorised')} • ${_fallback(item['tagNumber'] ?? item['barcode'], 'No design number')}',
      statusLabel: _readableStatus(item['status']),
      metrics: [
        _ReportCell('Purity', _fallback(item['karat'] ?? item['purity'], '-')),
        _ReportCell('Gross', _weight(item['grossWeight'])),
        _ReportCell('Net', _weight(item['netWeight'])),
        _ReportCell('Selling Price', _money(item['estimatedSellingPrice'])),
        _ReportCell('Branch', _fallback(item['location'], 'Main')),
      ],
    );
  }

  _ReportRow _soldProductRow(Map<String, dynamic> row) {
    return _ReportRow(
      leadingIcon: Icons.shopping_bag_outlined,
      title: _fallback(row['productName'], 'Product'),
      subtitle:
          '${_fallback(row['invoiceNumber'], 'Invoice')} • ${_fallback(row['customerName'], 'Customer')}',
      statusLabel: _fallback(row['paymentMode'], 'Payment'),
      metrics: [
        _ReportCell('Sold Date', _formatDate(row['soldDate'])),
        _ReportCell('Selling Price', _money(row['sellingPrice'])),
        _ReportCell('Mobile', _fallback(row['customerPhone'], '-')),
      ],
    );
  }

  _ReportRow _lowStockRow(Map<String, dynamic> item) {
    return _ReportRow(
      leadingIcon: Icons.warning_amber_rounded,
      title: _fallback(item['itemName'], 'Product'),
      subtitle:
          '${_fallback(item['categoryName'], 'Uncategorised')} • ${_fallback(item['tagNumber'] ?? item['barcode'], 'No design number')}',
      statusLabel: 'Low Stock',
      statusColor: AppColors.warning,
      metrics: [
        _ReportCell('Available Qty', _asInt(item['quantity']).toString()),
        _ReportCell('Purity', _fallback(item['karat'] ?? item['purity'], '-')),
        _ReportCell('Branch', _fallback(item['location'], 'Main')),
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
    final items = _mapList(invoice['items']);
    return _ReportRow(
      leadingIcon: Icons.receipt_long_outlined,
      title: _fallback(invoice['invoiceNumber'], 'Invoice'),
      subtitle: _fallback(invoice['customerName'], 'Walk-in Customer'),
      statusLabel: label,
      metrics: [
        _ReportCell('Date', _formatDate(invoice['invoiceDate'])),
        _ReportCell('Total', _money(invoice['grandTotal'])),
        _ReportCell('Payment', _fallback(invoice['paymentMode'], '-')),
        _ReportCell('Items', items.length.toString()),
      ],
    );
  }

  _ReportRow _gstRow(Map<String, dynamic> invoice) {
    return _ReportRow(
      leadingIcon: Icons.percent_rounded,
      title: _fallback(invoice['invoiceNumber'], 'Invoice'),
      subtitle: _fallback(invoice['customerName'], 'Walk-in Customer'),
      statusLabel: 'GST',
      statusColor: AppColors.warning,
      metrics: [
        _ReportCell('Taxable', _money(invoice['taxableAmount'])),
        _ReportCell('CGST', _money(invoice['cgstAmount'])),
        _ReportCell('SGST', _money(invoice['sgstAmount'])),
        _ReportCell('Total GST', _money(invoice['totalTax'])),
      ],
    );
  }

  _ReportRow _activeLoanRow(Map<String, dynamic> loan) {
    return _ReportRow(
      leadingIcon: Icons.account_balance_outlined,
      title: _fallback(loan['customerName'], 'Customer'),
      subtitle: _fallback(loan['loanNumber'], 'Mortgage Loan'),
      statusLabel: 'Active',
      statusColor: AppColors.info,
      metrics: [
        _ReportCell('Loan Amount', _money(loan['principalAmount'])),
        _ReportCell('Pending Interest', _money(loan['pendingInterestAmount'])),
        _ReportCell('Payable', _money(loan['totalPayableAmount'])),
        _ReportCell('Next Due', _formatDate(loan['nextDueDate'])),
      ],
    );
  }

  _ReportRow _interestCollectionRow(Map<String, dynamic> row) {
    return _ReportRow(
      leadingIcon: Icons.payments_outlined,
      title: _fallback(row['receiptNumber'], 'Receipt'),
      subtitle:
          '${_fallback(row['customerName'], 'Customer')} • ${_fallback(row['loanNumber'], 'Loan')}',
      statusLabel: _readableStatus(row['paymentType']),
      statusColor: AppColors.success,
      metrics: [
        _ReportCell('Date', _formatDate(row['paymentDate'])),
        _ReportCell('Amount', _money(row['amount'])),
        _ReportCell('Mode', _fallback(row['paymentMode'], '-')),
        _ReportCell('Mobile', _fallback(row['customerPhone'], '-')),
      ],
    );
  }

  _ReportRow _closedLoanRow(Map<String, dynamic> loan) {
    return _ReportRow(
      leadingIcon: Icons.check_circle_outline_rounded,
      title: _fallback(loan['customerName'], 'Customer'),
      subtitle: _fallback(loan['loanNumber'], 'Mortgage Loan'),
      statusLabel: _readableStatus(loan['status']),
      statusColor: AppColors.success,
      metrics: [
        _ReportCell('Loan Amount', _money(loan['principalAmount'])),
        _ReportCell('Interest Paid', _money(loan['totalInterestPaid'])),
        _ReportCell('Closing Date', _formatDate(loan['closedAt'])),
        _ReportCell('Loan Status', _readableStatus(loan['status'])),
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
    final date = _parseDate(_dateFromController.text) ?? DateTime.now();
    return 'Sales generated on ${DateFormat('dd MMM yyyy').format(date)}.';
  }

  String get _monthlySalesSubtitle {
    final date = _parseDate(_dateFromController.text) ?? DateTime.now();
    return 'Sales generated in ${DateFormat('MMMM yyyy').format(date)}.';
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
              IconButton.filledTonal(
                tooltip: 'Export report PDF',
                onPressed: onExport,
                icon: const Icon(Icons.download_outlined),
              ),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(row.leadingIcon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.subtitle,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: row.statusLabel, color: row.statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final metric in row.metrics)
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        style: TextStyle(
                          color: AppColors.text3(context),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text1(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
