import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/application/billing_pricing_calculations.dart';
import 'package:swarnbook/features/billing/application/invoice_action_payloads.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_image.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  Timer? _searchDebounce;
  List<dynamic> _invoices = [];
  Map<String, dynamic> _dashboard = const {};
  bool _isLoading = true;
  bool _isInvoicesLoading = false;
  String _activeSection = 'dashboard';

  @override
  void initState() {
    super.initState();
    _loadBillingData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  Future<void> _loadBillingData() async {
    try {
      final responses = await Future.wait([
        _api.dio.get('/invoices/dashboard'),
        _api.dio.get('/invoices', queryParameters: _invoiceQueryParameters()),
      ]);
      if (mounted) {
        setState(() {
          _dashboard = responses[0].data as Map<String, dynamic>? ?? {};
          _invoices = responses[1].data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        AppToast.error(context, l10n.errorFailedLoadInvoices);
      }
    }
  }

  Future<void> _loadInvoices() async {
    setState(() => _isInvoicesLoading = true);
    try {
      final response = await _api.dio.get(
        '/invoices',
        queryParameters: _invoiceQueryParameters(),
      );
      if (mounted) {
        setState(() {
          _invoices = response.data as List<dynamic>;
          _isInvoicesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isInvoicesLoading = false);
        AppToast.error(context, l10n.errorFailedLoadInvoices);
      }
    }
  }

  Map<String, dynamic>? _invoiceQueryParameters() {
    final params = <String, dynamic>{
      if (_searchController.text.trim().isNotEmpty)
        'search': _searchController.text.trim(),
      if (_dateFromController.text.trim().isNotEmpty)
        'dateFrom': _dateFromController.text.trim(),
      if (_dateToController.text.trim().isNotEmpty)
        'dateTo': _dateToController.text.trim(),
    };
    return params.isEmpty ? null : params;
  }

  void _onHistoryFilterChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadInvoices);
  }

  bool get _hasHistoryFilters {
    return _searchController.text.trim().isNotEmpty ||
        _dateFromController.text.trim().isNotEmpty ||
        _dateToController.text.trim().isNotEmpty;
  }

  void _clearHistoryFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _dateFromController.clear();
    _dateToController.clear();
    setState(() {});
    _loadInvoices();
  }

  Future<void> _pickHistoryDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initialDate =
        DateTime.tryParse(controller.text.trim()) ??
        DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;

    controller.text = _isoDate(picked);
    setState(() {});
    await _loadInvoices();
  }

  String _isoDate(DateTime value) {
    return [
      value.year.toString().padLeft(4, '0'),
      value.month.toString().padLeft(2, '0'),
      value.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  Future<void> _openCreateInvoice() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateInvoiceDialog(api: _api),
    );

    if (created == true && mounted) {
      _loadBillingData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.billingInvoiceHistory,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              GoldButton(
                label: l10n.billingCreateInvoice,
                icon: Icons.add_rounded,
                onPressed: _openCreateInvoice,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.billingCreateSalesSubtitle,
            style: TextStyle(color: AppColors.text3(context)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionSwitch(),
          const SizedBox(height: AppSpacing.lg),
          if (_activeSection == 'dashboard')
            Expanded(child: _buildDashboard())
          else ...[
            _buildSearch(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildInvoiceHistory()),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionSwitch() {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _sectionChip(
          'dashboard',
          l10n.billingSectionDashboard,
          Icons.dashboard_outlined,
        ),
        _sectionChip(
          'history',
          l10n.billingSectionHistory,
          Icons.receipt_long_outlined,
        ),
      ],
    );
  }

  Widget _sectionChip(String value, String label, IconData icon) {
    final selected = _activeSection == value;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.primary : AppColors.text2(context),
      ),
      label: Text(label),
      onSelected: (_) => setState(() => _activeSection = value),
    );
  }

  Widget _buildDashboard() {
    final l10n = AppLocalizations.of(context)!;
    final topSelling =
        (_dashboard['topSellingProducts'] as List<dynamic>? ?? const []);
    final cards = [
      (
        icon: Icons.today_outlined,
        label: l10n.billingTodayRevenue,
        value: _currency(_dashboard['todaysRevenue']),
        color: AppColors.success,
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: l10n.billingMonthlyRevenue,
        value: _currency(_dashboard['monthlyRevenue']),
        color: AppColors.primary,
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: l10n.billingTotalBills,
        value: '${_dashboard['totalBills'] ?? 0}',
        color: AppColors.info,
      ),
      (
        icon: Icons.trending_up_rounded,
        label: l10n.billingAverageBill,
        value: _currency(_dashboard['averageBillValue']),
        color: AppColors.warning,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 920 ? 4 : 2;
              final width =
                  (constraints.maxWidth -
                      (crossAxisCount - 1) * AppSpacing.md) /
                  crossAxisCount;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: card.icon,
                        label: card.label,
                        value: card.value,
                        accentColor: card.color,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: l10n.billingTopSellingProducts),
                const SizedBox(height: AppSpacing.md),
                if (topSelling.isEmpty)
                  Text('—', style: TextStyle(color: AppColors.text3(context)))
                else
                  ...topSelling.map((entry) {
                    final item = entry as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.diamond_outlined),
                      title: Text(
                        item['itemName']?.toString() ??
                            l10n.billingItemFallback,
                      ),
                      trailing: Text('${item['quantity'] ?? 0}'),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final search = TextField(
            controller: _searchController,
            onChanged: _onHistoryFilterChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.billingSearchHint,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.text3(context),
              ),
              border: const OutlineInputBorder(),
            ),
          );
          final fromDate = _dateField(
            l10n: l10n,
            controller: _dateFromController,
            label: l10n.billingFromDate,
          );
          final toDate = _dateField(
            l10n: l10n,
            controller: _dateToController,
            label: l10n.billingToDate,
          );
          final actions = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              IconButton.filledTonal(
                tooltip: l10n.billingRefresh,
                onPressed: _isInvoicesLoading ? null : _loadInvoices,
                icon: _isInvoicesLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton.filledTonal(
                tooltip: l10n.billingClearFilters,
                onPressed: _hasHistoryFilters ? _clearHistoryFilters : null,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          );

          if (!isWide) {
            return Column(
              children: [
                search,
                const SizedBox(height: AppSpacing.sm),
                fromDate,
                const SizedBox(height: AppSpacing.sm),
                toDate,
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: search),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: fromDate),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: toDate),
              const SizedBox(width: AppSpacing.sm),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _dateField({
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickHistoryDate(controller),
      decoration: InputDecoration(
        labelText: label,
        hintText: l10n.billingDateHint,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: l10n.billingClearFilters,
                onPressed: () {
                  controller.clear();
                  setState(() {});
                  _loadInvoices();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildInvoiceHistory() {
    if (_isInvoicesLoading && _invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _invoices.isEmpty
            ? EmptyState.billing(onAction: _openCreateInvoice)
            : RefreshIndicator(
                onRefresh: _loadInvoices,
                child: ListView.separated(
                  itemCount: _invoices.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _InvoiceCard(
                    api: _api,
                    invoice: _invoices[index] as Map<String, dynamic>,
                  ),
                ),
              ),
        if (_isInvoicesLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  String _currency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }
}

enum _InvoiceAction { view, print, download, share }

class _InvoiceCard extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> invoice;

  const _InvoiceCard({required this.api, required this.invoice});

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  _InvoiceAction? _activeAction;

  String get _invoiceId => widget.invoice['id']?.toString() ?? '';

  Future<void> _runAction(
    _InvoiceAction action,
    Future<void> Function() task,
  ) async {
    if (_activeAction != null) return;

    setState(() => _activeAction = action);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchPrintable(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (_invoiceId.isEmpty) {
      AppToast.error(context, l10n.errorInvoiceIdMissing);
      return null;
    }

    try {
      final response = await widget.api.dio.get('/invoices/$_invoiceId/print');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, l10n.errorFailedLoadInvoiceDetails);
      }
      return null;
    }
  }

  Future<InvoicePdfPayload?> _fetchPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (_invoiceId.isEmpty) {
      AppToast.error(context, l10n.errorInvoiceIdMissing);
      return null;
    }

    try {
      final response = await widget.api.dio.get('/invoices/$_invoiceId/pdf');
      final payload = Map<String, dynamic>.from(response.data as Map);
      return decodeInvoicePdfPayload(
        payload,
        fallbackFileName: 'invoice-$_invoiceId.pdf',
      );
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, l10n.errorFailedGenerateInvoicePdf);
      }
      return null;
    }
  }

  Future<void> _openDetails(BuildContext context) async {
    await _runAction(_InvoiceAction.view, () async {
      final printable = await _fetchPrintable(context);
      if (printable == null || !context.mounted || !mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _InvoiceDetailDialog(
          printable: printable,
          onPrint: () => _printInvoice(dialogContext),
          onDownload: () => _downloadPdf(dialogContext),
          onWhatsApp: () => _shareWhatsApp(dialogContext),
        ),
      );
    });
  }

  Future<void> _printInvoice(BuildContext context) async {
    await _runAction(_InvoiceAction.print, () async {
      final payload = await _fetchPdf(context);
      if (payload == null) return;
      await Printing.layoutPdf(
        name: payload.fileName,
        onLayout: (_) async => payload.bytes,
      );
    });
  }

  Future<void> _downloadPdf(BuildContext context) async {
    await _runAction(_InvoiceAction.download, () async {
      final l10n = AppLocalizations.of(context)!;
      final payload = await _fetchPdf(context);
      if (payload == null) return;
      await Printing.sharePdf(bytes: payload.bytes, filename: payload.fileName);
      if (context.mounted) {
        AppToast.success(context, l10n.billingInvoicePdfReady);
      }
    });
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    await _runAction(_InvoiceAction.share, () async {
      final l10n = AppLocalizations.of(context)!;
      if (_invoiceId.isEmpty) {
        AppToast.error(context, l10n.errorInvoiceIdMissing);
        return;
      }

      try {
        final response = await widget.api.dio.get(
          '/invoices/$_invoiceId/share',
        );
        final payload = Map<String, dynamic>.from(response.data as Map);
        final uri = invoiceWhatsAppUri(payload);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          AppToast.error(context, l10n.errorCouldNotOpenWhatsApp);
        } else if (context.mounted) {
          AppToast.success(context, l10n.billingWhatsAppOpened);
        }
      } catch (_) {
        if (context.mounted) {
          AppToast.error(context, l10n.errorFailedPrepareWhatsAppInvoice);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grandTotal =
        double.tryParse(widget.invoice['grandTotal']?.toString() ?? '0') ?? 0;
    final amountPaid =
        double.tryParse(widget.invoice['amountPaid']?.toString() ?? '0') ?? 0;
    final balance =
        double.tryParse(widget.invoice['balanceDue']?.toString() ?? '0') ?? 0;
    final items = (widget.invoice['items'] as List?) ?? const [];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invoice['invoiceNumber']?.toString() ??
                          l10n.billingInvoiceFallback,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.invoice['customerName']?.toString().isNotEmpty ==
                              true
                          ? widget.invoice['customerName'].toString()
                          : l10n.customerWalkIn,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: balance > 0
                    ? l10n.billingStatusPending
                    : l10n.billingStatusCompleted,
                color: balance > 0 ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _metric(
                context,
                l10n.billingTotal,
                '₹${grandTotal.toStringAsFixed(0)}',
              ),
              _metric(
                context,
                l10n.billingPaid,
                '₹${amountPaid.toStringAsFixed(0)}',
              ),
              _metric(
                context,
                l10n.billingBalance,
                '₹${balance.toStringAsFixed(0)}',
              ),
              _metric(context, l10n.billingItems, '${items.length}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _historyAction(
                context,
                action: _InvoiceAction.view,
                icon: Icons.visibility_outlined,
                tooltip: l10n.billingViewInvoiceDetails,
                onPressed: () => _openDetails(context),
              ),
              _historyAction(
                context,
                action: _InvoiceAction.print,
                icon: Icons.print_outlined,
                tooltip: l10n.billingReprintInvoice,
                onPressed: () => _printInvoice(context),
              ),
              _historyAction(
                context,
                action: _InvoiceAction.download,
                icon: Icons.download_outlined,
                tooltip: l10n.billingDownloadPdf,
                onPressed: () => _downloadPdf(context),
              ),
              _historyAction(
                context,
                action: _InvoiceAction.share,
                icon: Icons.share_outlined,
                tooltip: l10n.billingShareWhatsApp,
                onPressed: () => _shareWhatsApp(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyAction(
    BuildContext context, {
    required _InvoiceAction action,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final isActive = _activeAction == action;
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: _activeAction == null ? onPressed : null,
      icon: isActive
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text1(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailDialog extends StatelessWidget {
  final Map<String, dynamic> printable;
  final VoidCallback onPrint;
  final VoidCallback onDownload;
  final VoidCallback onWhatsApp;

  const _InvoiceDetailDialog({
    required this.printable,
    required this.onPrint,
    required this.onDownload,
    required this.onWhatsApp,
  });

  Map<String, dynamic> get _shop =>
      Map<String, dynamic>.from(printable['shop'] as Map? ?? const {});

  Map<String, dynamic> get _invoice =>
      Map<String, dynamic>.from(printable['invoice'] as Map? ?? const {});

  List<Map<String, dynamic>> get _items {
    return (_invoice['items'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoiceNumber = _text(
      _invoice['invoiceNumber'],
      l10n.billingInvoiceFallback,
    );
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Expanded(child: Text(invoiceNumber)),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 860,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShopHeader(context),
              const SizedBox(height: AppSpacing.lg),
              _buildCustomerAndInvoice(context),
              const SizedBox(height: AppSpacing.lg),
              _buildItemsTable(context),
              const SizedBox(height: AppSpacing.lg),
              _buildTotals(context),
              const SizedBox(height: AppSpacing.lg),
              _buildProtection(context),
            ],
          ),
        ),
      ),
      actions: [
        IconButton.filledTonal(
          tooltip: l10n.billingReprintInvoice,
          onPressed: onPrint,
          icon: const Icon(Icons.print_outlined),
        ),
        IconButton.filledTonal(
          tooltip: l10n.billingDownloadPdf,
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined),
        ),
        IconButton.filledTonal(
          tooltip: l10n.billingShareWhatsApp,
          onPressed: onWhatsApp,
          icon: const Icon(Icons.share_outlined),
        ),
      ],
    );
  }

  Widget _buildShopHeader(BuildContext context) {
    final logoUrl = _shop['logoUrl']?.toString();
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final address = [
      _shop['address'],
      _shop['city'],
      _shop['state'],
      _shop['pincode'],
    ].where((part) => part?.toString().trim().isNotEmpty == true).join(', ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: hasLogo ? null : AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: hasLogo ? AppColors.surf(context) : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildInvoiceLogo(logoUrl),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(_shop['name'], 'SwarnaLekh'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                if (address.isNotEmpty)
                  Text(
                    address,
                    style: TextStyle(color: AppColors.text3(context)),
                  ),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 4,
                  children: [
                    if (_hasText(_shop['phone']))
                      Text(
                        'Phone: ${_shop['phone']}',
                        style: TextStyle(color: AppColors.text2(context)),
                      ),
                    if (_hasText(_shop['gstin']))
                      Text(
                        'GSTIN: ${_shop['gstin']}',
                        style: TextStyle(color: AppColors.text2(context)),
                      ),
                    if (_hasText(_shop['pan']))
                      Text(
                        'PAN: ${_shop['pan']}',
                        style: TextStyle(color: AppColors.text2(context)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceLogo(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return const Center(
        child: Text(
          'SL',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (isDataImage(logoUrl)) {
      try {
        return Image.memory(decodeDataImage(logoUrl), fit: BoxFit.cover);
      } catch (_) {
        return const Icon(
          Icons.broken_image_outlined,
          color: AppColors.primary,
        );
      }
    }

    return Image.network(
      logoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined, color: AppColors.primary),
    );
  }

  Widget _buildCustomerAndInvoice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _infoPanel(
          context,
          title: l10n.billingCustomerDetails,
          rows: [
            (
              l10n.billingCustomerName,
              _text(_invoice['customerName'], l10n.customerWalkIn),
            ),
            (l10n.billingMobile, _text(_invoice['customerPhone'], '-')),
            (l10n.billingGstin, _text(_invoice['customerGstin'], '-')),
          ],
        ),
        _infoPanel(
          context,
          title: l10n.billingInvoiceDetails,
          rows: [
            (l10n.billingInvoiceNumber, _text(_invoice['invoiceNumber'], '-')),
            (l10n.billingInvoiceDate, _formatDate(_invoice['invoiceDate'])),
            (l10n.billingPaymentMethod, _text(_invoice['paymentMode'], '-')),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_items.isEmpty) {
      return Text(
        l10n.billingNoProductsFound,
        style: TextStyle(color: AppColors.text3(context)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.billingProduct)),
          DataColumn(label: Text(l10n.billingPurity)),
          DataColumn(label: Text(l10n.billingGross)),
          DataColumn(label: Text(l10n.billingNet)),
          DataColumn(label: Text(l10n.billingRate)),
          DataColumn(label: Text(l10n.billingMakingCharges)),
          DataColumn(label: Text(l10n.billingGstBase)),
          DataColumn(label: Text(l10n.billingTotal)),
        ],
        rows: _items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(_text(item['itemName'], l10n.billingItemFallback))),
              DataCell(Text(_text(item['karat'], '-'))),
              DataCell(Text(_weight(item['grossWeight']))),
              DataCell(Text(_weight(item['netWeight']))),
              DataCell(Text(_money(item['ratePerGram']))),
              DataCell(Text(_money(item['makingCharges']))),
              DataCell(Text(_money(item['itemTotal']))),
              DataCell(Text(_money(item['itemTotal']))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotals(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _summaryPanel(
          context,
          title: l10n.billingGstBreakdown,
          rows: [
            (l10n.billingTaxableAmount, _money(_invoice['taxableAmount'])),
            (
              'CGST ${_percent(_invoice['cgstPercent'])}',
              _money(_invoice['cgstAmount']),
            ),
            (
              'SGST ${_percent(_invoice['sgstPercent'])}',
              _money(_invoice['sgstAmount']),
            ),
            (
              'IGST ${_percent(_invoice['igstPercent'])}',
              _money(_invoice['igstAmount']),
            ),
            (l10n.billingTotalGst, _money(_invoice['totalTax'])),
          ],
        ),
        _summaryPanel(
          context,
          title: l10n.billingBillCalculation,
          rows: [
            (l10n.billingGoldValue, _money(_invoice['subtotal'])),
            (l10n.billingMakingCharges, _money(_invoice['totalMakingCharges'])),
            (l10n.billingStoneValue, _money(_invoice['totalStoneValue'])),
            (l10n.billingDiscount, _money(_invoice['discountAmount'])),
            (l10n.billingOldGold, _money(_invoice['oldGoldValue'])),
            (l10n.billingFinalTotal, _money(_invoice['grandTotal'])),
            (l10n.billingPaid, _money(_invoice['amountPaid'])),
            (l10n.billingBalance, _money(_invoice['balanceDue'])),
          ],
        ),
      ],
    );
  }

  Widget _buildProtection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _protectionMetric(
            context,
            l10n.billingVerification,
            _text(printable['verificationCode'], '-'),
          ),
          _protectionMetric(
            context,
            l10n.billingQrPayload,
            _text(printable['qrPayload'], '-'),
          ),
          _protectionMetric(
            context,
            l10n.billingGenerated,
            _formatDate(printable['generatedAt']),
          ),
        ],
      ),
    );
  }

  Widget _infoPanel(
    BuildContext context, {
    required String title,
    required List<(String, String)> rows,
  }) {
    return SizedBox(
      width: 300,
      child: _summaryPanel(context, title: title, rows: rows),
    );
  }

  Widget _summaryPanel(
    BuildContext context, {
    required String title,
    required List<(String, String)> rows,
  }) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  ),
                  Text(
                    row.$2,
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
    );
  }

  Widget _protectionMetric(BuildContext context, String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text1(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasText(dynamic value) {
    return value?.toString().trim().isNotEmpty == true;
  }

  String _text(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) => '₹${_asDouble(value).toStringAsFixed(0)}';

  String _weight(dynamic value) => '${_asDouble(value).toStringAsFixed(3)} g';

  String _percent(dynamic value) => '${_asDouble(value).toStringAsFixed(1)}%';

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _CreateInvoiceDialog extends StatefulWidget {
  final ApiClient api;

  const _CreateInvoiceDialog({required this.api});

  @override
  State<_CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<_CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _inventorySearchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _amountPaidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _customers = [];
  List<dynamic> _items = [];
  String? _selectedCustomerId;
  final Set<String> _selectedItemIds = {};
  final Map<String, int> _selectedQuantities = {};
  String _paymentMode = 'cash';

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _selectedUnits() {
    var total = 0;
    for (final item in _items.cast<Map<String, dynamic>>()) {
      final itemId = item['id']?.toString() ?? '';
      if (!_selectedItemIds.contains(itemId)) continue;
      final stockType = item['stockType']?.toString() ?? 'unique';
      total += stockType == 'bulk' ? (_selectedQuantities[itemId] ?? 1) : 1;
    }
    return total;
  }

  BillingLineBreakdown _lineBreakdown(Map<String, dynamic> item, int quantity) {
    return calculateBillingLineBreakdown(
      quantity: quantity,
      sellingPrice: _asDouble(item['sellingPrice']),
      currentRatePerGram: _asDouble(item['currentRatePerGram']),
      grossWeight: _asDouble(item['grossWeight']),
      netWeight: _asDouble(item['netWeight']),
      makingChargesFixed: _asDouble(item['makingChargesFixed']),
      makingChargesPerGram: _asDouble(item['makingChargesPerGram']),
      makingChargesPercent: _asDouble(item['makingChargesPercent']),
      stoneValue: _asDouble(item['stoneValue']),
      wastagePercent: _asDouble(item['wastagePercent']),
    );
  }

  double _estimatedSubtotal() {
    var total = 0.0;
    for (final item in _items.cast<Map<String, dynamic>>()) {
      final itemId = item['id']?.toString() ?? '';
      if (!_selectedItemIds.contains(itemId)) continue;
      final stockType = item['stockType']?.toString() ?? 'unique';
      final quantity = stockType == 'bulk'
          ? (_selectedQuantities[itemId] ?? 1)
          : 1;
      total += _lineBreakdown(item, quantity).lineTotal;
    }
    return total;
  }

  double _selectedProductValue() => _selectedItems.fold(
    0.0,
    (sum, item) => sum + _lineBreakdown(item.item, item.quantity).productValue,
  );

  double _selectedMakingCharges() => _selectedItems.fold(
    0.0,
    (sum, item) => sum + _lineBreakdown(item.item, item.quantity).makingCharges,
  );

  double _selectedGst() {
    final taxable = (_estimatedSubtotal() - _discountAmount())
        .clamp(0, double.infinity)
        .toDouble();
    return taxable * 0.03;
  }

  double _discountAmount() =>
      double.tryParse(_discountController.text.trim()) ?? 0;

  double _estimatedFinalTotal() {
    final taxable = (_estimatedSubtotal() - _discountAmount())
        .clamp(0, double.infinity)
        .toDouble();
    return (taxable + _selectedGst()).roundToDouble();
  }

  List<({Map<String, dynamic> item, int quantity})> get _selectedItems {
    final rows = <({Map<String, dynamic> item, int quantity})>[];
    for (final item in _items.cast<Map<String, dynamic>>()) {
      final itemId = item['id']?.toString() ?? '';
      if (!_selectedItemIds.contains(itemId)) continue;
      final stockType = item['stockType']?.toString() ?? 'unique';
      final quantity = stockType == 'bulk'
          ? (_selectedQuantities[itemId] ?? 1)
          : 1;
      rows.add((item: item, quantity: quantity));
    }
    return rows;
  }

  List<Map<String, dynamic>> get _filteredInventoryItems {
    final search = _inventorySearchController.text.trim().toLowerCase();
    if (search.isEmpty) return _items.cast<Map<String, dynamic>>();
    return _items.cast<Map<String, dynamic>>().where((item) {
      final haystack = [
        item['itemName'],
        item['tagNumber'],
        item['barcode'],
        item['designNumber'],
        item['categoryName'],
        item['metalType'],
        item['karat'],
      ].whereType<Object>().map((value) => value.toString().toLowerCase());
      return haystack.any((value) => value.contains(search));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _inventorySearchController.dispose();
    _discountController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDependencies() async {
    try {
      final responses = await Future.wait([
        widget.api.dio.get('/customers', queryParameters: {'limit': 100}),
        widget.api.dio.get(
          '/inventory/overview',
          queryParameters: {'status': 'in_stock'},
        ),
      ]);

      if (mounted) {
        setState(() {
          _customers = responses[0].data as List<dynamic>;
          _items = (responses[1].data['items'] as List<dynamic>?) ?? const [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop(false);
        AppToast.error(context, l10n.errorFailedLoadBillingData);
      }
    }
  }

  Future<void> _createInvoice() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCustomerId == null &&
        _customerNameController.text.trim().isEmpty) {
      AppToast.error(context, l10n.validationCustomerNameRequired);
      return;
    }
    if (_selectedItemIds.isEmpty) {
      AppToast.error(context, l10n.errorSelectInventoryItem);
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'customerId': _selectedCustomerId,
      if (_selectedCustomerId == null)
        'customerName': _customerNameController.text.trim(),
      if (_selectedCustomerId == null &&
          _customerPhoneController.text.trim().isNotEmpty)
        'customerPhone': _customerPhoneController.text.trim(),
      'items': _selectedItemIds.map((id) {
        final item = _items.cast<Map<String, dynamic>>().firstWhere(
          (entry) => entry['id']?.toString() == id,
        );
        final stockType = item['stockType']?.toString() ?? 'unique';
        final quantity = stockType == 'bulk'
            ? (_selectedQuantities[id] ?? 1)
            : 1;
        return {'inventoryItemId': id, 'quantity': quantity};
      }).toList(),
      'discountAmount': double.tryParse(_discountController.text.trim()) ?? 0,
      'amountPaid': double.tryParse(_amountPaidController.text.trim()) ?? 0,
      'paymentMode': _paymentMode,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      await widget.api.dio.post('/invoices', data: payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, l10n.errorFailedCreateInvoice);
      }
    }
  }

  Map<String, dynamic>? _findCustomer(String? customerId) {
    if (customerId == null) return null;
    for (final customer in _customers.cast<Map<String, dynamic>>()) {
      if (customer['id']?.toString() == customerId) return customer;
    }
    return null;
  }

  Widget _buildBillTable(AppLocalizations l10n) {
    final rows = _selectedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.billingBillTable),
        const SizedBox(height: AppSpacing.sm),
        if (rows.isEmpty)
          Text('—', style: TextStyle(color: AppColors.text3(context)))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.billingProduct)),
                DataColumn(label: Text(l10n.billingWeight)),
                DataColumn(label: Text(l10n.billingPrice)),
                DataColumn(label: Text(l10n.billingQty)),
                DataColumn(label: Text(l10n.billingTotal)),
              ],
              rows: rows.map((entry) {
                final item = entry.item;
                final breakdown = _lineBreakdown(item, entry.quantity);
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        item['itemName']?.toString() ??
                            l10n.billingItemFallback,
                      ),
                    ),
                    DataCell(Text('${item['netWeight'] ?? 0} g')),
                    DataCell(
                      Text('₹${breakdown.lineTotal.toStringAsFixed(0)}'),
                    ),
                    DataCell(Text('${entry.quantity}')),
                    DataCell(
                      Text('₹${breakdown.lineTotal.toStringAsFixed(0)}'),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.billingCreateInvoice),
      content: SizedBox(
        width: 720,
        child: _isLoading
            ? const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SectionHeader(title: l10n.billingCustomerDetails),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCustomerId,
                        decoration: InputDecoration(
                          labelText: l10n.billingSavedCustomer,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(l10n.customerWalkIn),
                          ),
                          ..._customers.map(
                            (customer) => DropdownMenuItem<String>(
                              value: customer['id']?.toString(),
                              child: Text(
                                customer['name']?.toString() ??
                                    l10n.billingCustomerFallback,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          final customer = _findCustomer(value);
                          setState(() {
                            _selectedCustomerId = value;
                            if (customer != null) {
                              _customerNameController.text =
                                  customer['name']?.toString() ?? '';
                              _customerPhoneController.text =
                                  customer['phone']?.toString() ?? '';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerNameController,
                              decoration: InputDecoration(
                                labelText: l10n.billingCustomerName,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _customerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l10n.billingMobileNumber,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(title: l10n.billingSelectInventoryItems),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _inventorySearchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          labelText: l10n.billingSearchInventory,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.brd(context)),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredInventoryItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredInventoryItems[index];
                            final itemId = item['id']?.toString() ?? '';
                            final selected = _selectedItemIds.contains(itemId);
                            final stockType =
                                item['stockType']?.toString() ?? 'unique';
                            final availableQuantity =
                                (item['quantity'] as num?)?.toInt() ?? 1;
                            final selectedQuantity =
                                _selectedQuantities[itemId] ?? 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.brd(context),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: selected,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedItemIds.add(itemId);
                                          _selectedQuantities.putIfAbsent(
                                            itemId,
                                            () => 1,
                                          );
                                        } else {
                                          _selectedItemIds.remove(itemId);
                                          _selectedQuantities.remove(itemId);
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['itemName']?.toString() ??
                                              l10n.billingItemFallback,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item['metalType'] ?? ''} ${item['karat'] ?? ''} | ${item['tagNumber'] ?? l10n.billingNoTag} | ${stockType == 'bulk' ? l10n.billingBulk : l10n.billingUnique}',
                                          style: TextStyle(
                                            color: AppColors.text3(context),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (stockType == 'bulk')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed:
                                              selected && selectedQuantity > 1
                                              ? () => setState(() {
                                                  _selectedQuantities[itemId] =
                                                      selectedQuantity - 1;
                                                })
                                              : null,
                                          icon: const Icon(
                                            Icons.remove_circle_outline_rounded,
                                          ),
                                        ),
                                        Container(
                                          width: 96,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.brd(context),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.md,
                                            ),
                                          ),
                                          child: Text(
                                            '$selectedQuantity / $availableQuantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              selected &&
                                                  selectedQuantity <
                                                      availableQuantity
                                              ? () => setState(() {
                                                  _selectedQuantities[itemId] =
                                                      selectedQuantity + 1;
                                                })
                                              : null,
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfL(context),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                      ),
                                      child: Text('${l10n.billingQty} 1'),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildBillTable(l10n),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfL(context),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.brd(context)),
                        ),
                        child: Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.sm,
                          children: [
                            Text(
                              '${l10n.billingSelectedUnits}: ${_selectedUnits()}',
                              style: TextStyle(
                                color: AppColors.text2(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${l10n.billingProductValue}: ₹${_selectedProductValue().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.text2(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${l10n.billingMakingCharges}: ₹${_selectedMakingCharges().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.text2(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${l10n.billingGst}: ₹${_selectedGst().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.text2(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${l10n.billingFinalTotal}: ₹${_estimatedFinalTotal().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.text1(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.billingDiscountAmount,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _amountPaidController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.billingAmountPaid,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMode,
                        decoration: InputDecoration(
                          labelText: l10n.billingPaymentMode,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text(l10n.billingPaymentCash),
                          ),
                          DropdownMenuItem(
                            value: 'upi',
                            child: Text(l10n.billingPaymentUpi),
                          ),
                          DropdownMenuItem(
                            value: 'card',
                            child: Text(l10n.billingPaymentCard),
                          ),
                          DropdownMenuItem(
                            value: 'debit_card',
                            child: Text(l10n.billingPaymentDebitCard),
                          ),
                          DropdownMenuItem(
                            value: 'credit_card',
                            child: Text(l10n.billingPaymentCreditCard),
                          ),
                          DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Text(l10n.billingPaymentBankTransfer),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _paymentMode = value ?? 'cash'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.commonNotes,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.billingRatesHint,
                        style: TextStyle(
                          color: AppColors.text3(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        GoldButton(
          label: l10n.commonCreate,
          isLoading: _isSaving,
          onPressed: _createInvoice,
        ),
      ],
    );
  }
}
