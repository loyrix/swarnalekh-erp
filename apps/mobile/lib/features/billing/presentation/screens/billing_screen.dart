import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/billing/application/invoice_providers.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';
import 'package:swarnbook/features/billing/presentation/invoice_pdf.dart';
import 'package:swarnbook/features/billing/presentation/screens/collect_invoice_payment_page.dart';
import 'package:swarnbook/features/billing/presentation/screens/create_invoice_page.dart';
import 'package:swarnbook/features/billing/presentation/widgets/invoice_detail_sheet.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_export.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  InvoiceQuery _query = const InvoiceQuery();
  String _section = 'dashboard';
  bool _busy = false;
  bool _canManage = false;
  InvoicePdfFonts? _cachedFonts;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(ApiClient());
      if (mounted) setState(() => _canManage = isAdminRole(role));
    } catch (_) {
      if (mounted) setState(() => _canManage = false);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  InvoiceRepository get _repo => ref.read(invoiceRepositoryProvider);

  void _selectSection(String value) => setState(() => _section = value);

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = _query.copyWith(search: value));
    });
  }

  Future<void> _refresh() async {
    if (_section == 'dashboard') {
      ref.invalidate(billingDashboardProvider);
      await ref.read(billingDashboardProvider.future);
    } else {
      ref.invalidate(invoicesProvider(_query));
      await ref.read(invoicesProvider(_query).future);
    }
  }

  void _invalidateAll() {
    ref.invalidate(billingDashboardProvider);
    ref.invalidate(invoicesProvider(_query));
  }

  Future<void> _openCreate() async {
    final created = await CreateInvoicePage.open(context);
    if (created == true && mounted) {
      AppToast.success(
        context,
        AppLocalizations.of(context)!.billingInvoiceCreated,
      );
      _invalidateAll();
    }
  }

  Future<void> _openDetails(Invoice invoice) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    if (invoice.id.isEmpty) {
      AppToast.error(context, l10n.errorInvoiceIdMissing);
      return;
    }
    setState(() => _busy = true);
    try {
      final printable = await _repo.getPrintable(invoice.id);
      if (!mounted) return;
      await showInvoiceDetail(
        context,
        printable,
        onPrint: () => _print(invoice),
        onDownload: () => _download(invoice),
        onShare: () => _share(invoice),
        onCollect: () => _collect(
          invoice,
          printable.invoice.invoiceNumber,
          printable.invoice.balanceDue,
        ),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.errorFailedLoadInvoiceDetails);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _collect(
    Invoice invoice,
    String? invoiceNumber,
    double balanceDue,
  ) async {
    final recorded = await CollectInvoicePaymentPage.open(
      context,
      invoiceId: invoice.id,
      invoiceNumber: invoiceNumber ?? invoice.invoiceNumber,
      balanceDue: balanceDue,
    );
    if (recorded == true && mounted) {
      AppToast.success(
        context,
        AppLocalizations.of(context)!.billingPaymentRecorded,
      );
      _invalidateAll();
    }
  }

  /// Renders the invoice PDF on-device from the server's printable payload.
  Future<({Uint8List bytes, String fileName})> _renderPdf(
    Invoice invoice,
  ) async {
    final printable = await _repo.getPrintable(invoice.id);
    final bytes = await buildInvoicePdf(printable, fonts: await _pdfFonts());
    final number =
        printable.invoice.invoiceNumber ?? invoice.invoiceNumber ?? invoice.id;
    final safe = number.replaceAll(RegExp(r'[^A-Za-z0-9-]+'), '-');
    return (bytes: bytes, fileName: '$safe.pdf');
  }

  Future<InvoicePdfFonts> _pdfFonts() async {
    if (_cachedFonts != null) return _cachedFonts!;
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
      final gujarati = await PdfGoogleFonts.notoSansGujaratiRegular();
      _cachedFonts = InvoicePdfFonts(
        base: base,
        bold: bold,
        fallback: [devanagari, gujarati],
      );
    } catch (_) {
      // Offline / fetch failed → fall back to the built-in PDF fonts.
      _cachedFonts = const InvoicePdfFonts();
    }
    return _cachedFonts!;
  }

  Future<void> _print(Invoice invoice) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final pdf = await _renderPdf(invoice);
      await Printing.layoutPdf(
        name: pdf.fileName,
        onLayout: (_) async => pdf.bytes,
      );
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.errorFailedGenerateInvoicePdf);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(Invoice invoice) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final pdf = await _renderPdf(invoice);
      await Printing.sharePdf(bytes: pdf.bytes, filename: pdf.fileName);
      if (mounted) AppToast.success(context, l10n.billingInvoicePdfReady);
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.errorFailedGenerateInvoicePdf);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(Invoice invoice) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final uri = await _repo.getShareUri(invoice.id);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (mounted) {
        if (launched) {
          AppToast.success(context, l10n.billingWhatsAppOpened);
        } else {
          AppToast.error(context, l10n.errorCouldNotOpenWhatsApp);
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, l10n.errorFailedPrepareWhatsAppInvoice);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSectionScaffold(
      header: _header(l10n),
      sections: [
        SectionItem(
          value: 'dashboard',
          label: l10n.billingSectionDashboard,
          icon: Icons.dashboard_outlined,
        ),
        SectionItem(
          value: 'history',
          label: l10n.billingSectionHistory,
          icon: Icons.receipt_long_outlined,
        ),
      ],
      activeSection: _section,
      onSectionChanged: _selectSection,
      onRefresh: _refresh,
      body: _section == 'dashboard' ? _dashboardBody() : _historyBody(),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoldButton(
          label: l10n.billingCreateInvoice,
          icon: Icons.add_rounded,
          onPressed: _openCreate,
        ),
        if (_section == 'history') ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.billingSearchHint,
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
                icon: Badge(
                  isLabelVisible:
                      _query.dateFrom != null || _query.dateTo != null,
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
              if (_canManage) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: l10n.exportCsv,
                  onPressed: () => exportAndShareCsv(
                    context,
                    'invoices',
                    query: {
                      if (_query.search.trim().isNotEmpty)
                        'search': _query.search.trim(),
                      if (_query.dateFrom != null) 'dateFrom': _query.dateFrom,
                      if (_query.dateTo != null) 'dateTo': _query.dateTo,
                    },
                  ),
                  icon: const Icon(Icons.file_download_outlined),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    String? from = _query.dateFrom;
    String? to = _query.dateTo;

    Future<String?> pickDate(String? current) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(current ?? '') ?? now,
        firstDate: DateTime(now.year - 10),
        lastDate: DateTime(now.year + 1, 12, 31),
      );
      if (picked == null) return current;
      return '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }

    await AppFilterSheet.show(
      context,
      title: l10n.commonFilters,
      onApply: () => setState(
        () => _query = InvoiceQuery(
          search: _query.search,
          dateFrom: from,
          dateTo: to,
        ),
      ),
      onClear: () {
        from = null;
        to = null;
      },
      builder: (context, setSheetState) => [
        _dateField(
          label: l10n.billingFromDate,
          value: from,
          onPick: () async {
            final v = await pickDate(from);
            setSheetState(() => from = v);
          },
          onClear: () => setSheetState(() => from = null),
        ),
        _dateField(
          label: l10n.billingToDate,
          value: to,
          onPick: () async {
            final v = await pickDate(to);
            setSheetState(() => to = v);
          },
          onClear: () => setSheetState(() => to = null),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          suffixIcon: value == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(value ?? '—'),
      ),
    );
  }

  Widget _dashboardBody() {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(billingDashboardProvider);
    return AppStateView<BillingDashboard>(
      value: async,
      onRetry: () => ref.invalidate(billingDashboardProvider),
      data: (dashboard) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            CompactStatStrip(
              stats: [
                (
                  icon: Icons.today_outlined,
                  label: l10n.billingTodayRevenue,
                  value: billingCompactMoney(dashboard.todaysRevenue),
                  color: AppColors.success,
                ),
                (
                  icon: Icons.calendar_month_outlined,
                  label: l10n.billingMonthlyRevenue,
                  value: billingCompactMoney(dashboard.monthlyRevenue),
                  color: AppColors.primary,
                ),
                (
                  icon: Icons.receipt_long_outlined,
                  label: l10n.billingTotalBills,
                  value: '${dashboard.totalBills}',
                  color: AppColors.info,
                ),
                (
                  icon: Icons.trending_up_rounded,
                  label: l10n.billingAverageBill,
                  value: billingCompactMoney(dashboard.averageBillValue),
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: l10n.billingTopSellingProducts),
                  const SizedBox(height: AppSpacing.md),
                  if (dashboard.topSellingProducts.isEmpty)
                    Text('—', style: TextStyle(color: AppColors.text3(context)))
                  else
                    ...dashboard.topSellingProducts.map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.diamond_outlined),
                        title: Text(p.itemName),
                        trailing: Text('${p.quantity}'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyBody() {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(invoicesProvider(_query));
    return AppStateView<List<Invoice>>(
      value: async,
      onRetry: () => ref.invalidate(invoicesProvider(_query)),
      data: (invoices) {
        if (invoices.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 60),
              EmptyState.billing(onAction: _openCreate),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: invoices.length,
          itemBuilder: (context, index) => _invoiceRow(l10n, invoices[index]),
        );
      },
    );
  }

  Widget _invoiceRow(AppLocalizations l10n, Invoice invoice) {
    final pending = !invoice.isPaid;
    return CompactDataRow(
      title: invoice.invoiceNumber ?? l10n.billingInvoiceFallback,
      subtitle: invoice.customerName ?? l10n.customerWalkIn,
      metrics: [
        (l10n.billingTotal, billingMoney(invoice.grandTotal)),
        (l10n.billingPaid, billingMoney(invoice.amountPaid)),
        (l10n.billingBalance, billingMoney(invoice.balanceDue)),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(
            label: pending
                ? l10n.billingStatusPending
                : l10n.billingStatusCompleted,
            color: pending ? AppColors.warning : AppColors.success,
          ),
          PopupMenuButton<String>(
            tooltip: l10n.billingViewInvoiceDetails,
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _openDetails(invoice);
                case 'print':
                  _print(invoice);
                case 'download':
                  _download(invoice);
                case 'share':
                  _share(invoice);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: _menuRow(
                  Icons.visibility_outlined,
                  l10n.billingViewInvoiceDetails,
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: _menuRow(
                  Icons.print_outlined,
                  l10n.billingReprintInvoice,
                ),
              ),
              PopupMenuItem(
                value: 'download',
                child: _menuRow(
                  Icons.download_outlined,
                  l10n.billingDownloadPdf,
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: _menuRow(
                  Icons.share_outlined,
                  l10n.billingShareWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _openDetails(invoice),
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}
