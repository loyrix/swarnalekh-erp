import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_statement.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_ledger_page.dart';
import 'package:swarnbook/features/reports/presentation/report_pdf.dart';
import 'package:swarnbook/features/tenant/data/models/tenant_profile.dart';
import 'package:swarnbook/features/tenant/data/repositories/tenant_repository.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_image.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Callbacks the detail page delegates to (the screen owns the action flows).
/// Each returns whether the loan changed, so the page can refresh itself.
typedef LoanAction = Future<bool> Function(MortgageLoan loan);
typedef PaymentAction =
    Future<bool> Function(MortgageLoan loan, MortgagePayment payment);

/// Full-screen mortgage loan detail: overview, loan details, top-up history,
/// gold details and the primary actions. Replaces the old bottom sheet.
class MortgageDetailPage extends StatefulWidget {
  const MortgageDetailPage({
    super.key,
    required this.loan,
    required this.canManage,
    required this.onCollect,
    required this.onTopUp,
    required this.onClose,
    required this.onReopen,
    required this.onReceipt,
    required this.onEditPayment,
    required this.onEdit,
  });

  final MortgageLoan loan;
  final bool canManage;
  final LoanAction onCollect;
  final LoanAction onTopUp;
  final LoanAction onClose;
  final LoanAction onReopen;
  final PaymentAction onReceipt;
  final PaymentAction onEditPayment;
  final LoanAction onEdit;

  static Future<bool?> open(
    BuildContext context, {
    required MortgageLoan loan,
    required bool canManage,
    required LoanAction onCollect,
    required LoanAction onTopUp,
    required LoanAction onClose,
    required LoanAction onReopen,
    required PaymentAction onReceipt,
    required PaymentAction onEditPayment,
    required LoanAction onEdit,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MortgageDetailPage(
          loan: loan,
          canManage: canManage,
          onCollect: onCollect,
          onTopUp: onTopUp,
          onClose: onClose,
          onReopen: onReopen,
          onReceipt: onReceipt,
          onEditPayment: onEditPayment,
          onEdit: onEdit,
        ),
      ),
    );
  }

  @override
  State<MortgageDetailPage> createState() => _MortgageDetailPageState();
}

class _MortgageDetailPageState extends State<MortgageDetailPage> {
  final _repo = MortgageRepository();
  final _tenantRepo = TenantRepository();
  late MortgageLoan _loan;
  List<MortgageLedgerEvent> _ledger = const [];
  bool _changed = false;
  bool _busyPdf = false;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    try {
      final ledger = await _repo.getLedger(_loan.id);
      if (mounted) setState(() => _ledger = ledger);
    } catch (_) {
      /* ledger stays empty */
    }
  }

  Future<void> _refresh() async {
    try {
      final loan = await _repo.getLoan(_loan.id);
      if (mounted) setState(() => _loan = loan);
      await _loadLedger();
    } catch (_) {
      /* keep the last known state */
    }
  }

  /// Builds the loan-statement PDF, then prints or shares it.
  Future<void> _statement({required bool share}) async {
    if (_busyPdf) return;
    setState(() => _busyPdf = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final events = _ledger.isNotEmpty
          ? _ledger
          : await _repo.getLedger(_loan.id);
      ReportPdfShop shop = const ReportPdfShop();
      try {
        final TenantProfile p = await _tenantRepo.getProfile();
        final address = [
          p.address,
          p.city,
          p.state,
          p.pincode,
        ].where((s) => s != null && s.trim().isNotEmpty).join(', ');
        shop = ReportPdfShop(
          name: p.shopName.isEmpty ? null : p.shopName,
          address: address.isEmpty ? null : address,
          phone: p.phone,
          gstin: p.gstin,
          pan: p.pan,
          logoUrl: p.logoUrl,
        );
      } catch (_) {
        /* fall back to the app-name letterhead */
      }
      final bytes = await buildReportPdf(
        shop: shop,
        table: mortgageStatementTable(_loan, events),
        fonts: await _statementFonts(),
      );
      final name = 'statement-${_loan.loanNumber ?? _loan.id}.pdf';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: name);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      }
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.mortgageStatementFailed);
    } finally {
      if (mounted) setState(() => _busyPdf = false);
    }
  }

  Future<ReportPdfFonts> _statementFonts() async {
    try {
      return ReportPdfFonts(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
        fallback: [
          await PdfGoogleFonts.notoSansDevanagariRegular(),
          await PdfGoogleFonts.notoSansGujaratiRegular(),
        ],
      );
    } catch (_) {
      return const ReportPdfFonts();
    }
  }

  Future<void> _run(LoanAction action) async {
    final didChange = await action(_loan);
    if (didChange && mounted) {
      _changed = true;
      await _refresh();
    }
  }

  Future<void> _launch(String scheme, String value) async {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = scheme == 'wa'
        ? Uri.parse('https://wa.me/$digits')
        : Uri.parse('tel:$digits');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          AppLocalizations.of(context)!.mortgageContactFailed,
        );
      }
    }
  }

  int? get _daysToDue {
    final due = DateTime.tryParse(_loan.nextDueDate ?? '');
    if (due == null || !_loan.isActive) return null;
    final now = DateTime.now();
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Most recent real collection (ignores the synthetic closure entry).
  String? get _lastCollection {
    for (final p in _loan.payments) {
      if (p.paymentType != 'closure') return p.paymentDate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loan = _loan;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loan.loanNumber ?? l10n.mortgageLoanFallback),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          actions: [
            if (widget.canManage && loan.isActive)
              IconButton(
                tooltip: l10n.mortgageEditLoan,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _run(widget.onEdit),
              ),
            IconButton(
              tooltip: l10n.mortgageShareStatement,
              icon: _busyPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              onPressed: _busyPdf ? null : () => _statement(share: true),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _statusRow(context, l10n),
              const SizedBox(height: AppSpacing.md),
              _customerCard(context, l10n),
              const SizedBox(height: AppSpacing.md),
              _overviewCard(context, l10n),
              const SizedBox(height: AppSpacing.md),
              _twoCol(
                context,
                _loanDetailsCard(context, l10n),
                loan.topups.isNotEmpty
                    ? _topupHistoryCard(context, l10n)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _twoCol(
                context,
                loan.ornaments.isNotEmpty ? _goldCard(context, l10n) : null,
                _ledger.isNotEmpty ? _ledgerCard(context, l10n) : null,
              ),
              if (loan.payments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _payments(context, l10n),
              ],
              const SizedBox(height: AppSpacing.md),
              _footer(context, l10n),
              const SizedBox(height: 90),
            ],
          ),
        ),
        bottomNavigationBar: _actionBar(context, l10n),
      ),
    );
  }

  /// Lays two section cards side by side on wider screens, stacked on narrow.
  Widget _twoCol(BuildContext context, Widget? left, Widget? right) {
    if (left == null && right == null) return const SizedBox.shrink();
    if (left == null) return right!;
    if (right == null) return left;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 380) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: AppSpacing.md),
            right,
          ],
        );
      },
    );
  }

  Widget _statusRow(BuildContext context, AppLocalizations l10n) {
    final days = _daysToDue;
    return Row(
      children: [
        StatusBadge(label: _loan.status),
        if (days != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (days < 0 ? AppColors.error : AppColors.warning)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              days < 0
                  ? l10n.mortgageOverdueByDays(-days)
                  : l10n.mortgageDueInDays(days),
              style: TextStyle(
                color: days < 0 ? AppColors.error : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _customerCard(BuildContext context, AppLocalizations l10n) {
    final name = _loan.customerName ?? l10n.mortgageCustomerFallback;
    final phone = _loan.customerPhone;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (phone != null)
                      Text(
                        phone,
                        style: TextStyle(
                          color: AppColors.text3(context),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (phone != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _contactPill(
                    Icons.call_rounded,
                    l10n.mortgageCall,
                    AppColors.success,
                    () => _launch('tel', phone),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _contactPill(
                    Icons.chat_rounded,
                    l10n.mortgageWhatsapp,
                    const Color(0xFF25D366),
                    () => _launch('wa', phone),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactPill(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- cards --------------------------------------------------------------

  Widget _card(BuildContext context, String title, Widget child) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.text3(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _overviewCard(BuildContext context, AppLocalizations l10n) {
    final loan = _loan;
    return _card(
      context,
      l10n.mortgageLoanOverview,
      Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _stat(
                  context,
                  l10n.mortgagePrincipalOutstanding,
                  mortgageMoney(loan.outstandingPrincipal),
                ),
              ),
              Expanded(
                child: _stat(
                  context,
                  l10n.mortgagePendingInterest,
                  mortgageMoney(loan.pendingInterestAmount),
                ),
              ),
              Expanded(
                child: _stat(
                  context,
                  l10n.mortgageTotalPayable,
                  mortgageMoney(loan.totalPayableAmount),
                  emphasize: true,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.brd(context), height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _stat(
                  context,
                  l10n.mortgageLastCollection,
                  mortgageDate(_lastCollection),
                  small: true,
                ),
              ),
              Expanded(
                child: _stat(
                  context,
                  l10n.mortgageNextDue,
                  mortgageDate(loan.nextDueDate),
                  small: true,
                ),
              ),
              Expanded(
                child: _stat(
                  context,
                  l10n.mortgageInterestRate,
                  '${loan.interestRateMonthly}% ${l10n.mortgagePerMonth}',
                  small: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    bool small = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.text3(context), fontSize: 10.5),
          maxLines: 2,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: small ? FontWeight.w600 : FontWeight.w800,
            fontSize: small ? 12.5 : 15,
            color: emphasize ? AppColors.primary : AppColors.text1(context),
          ),
        ),
      ],
    );
  }

  Widget _loanDetailsCard(BuildContext context, AppLocalizations l10n) {
    final loan = _loan;
    final rows = <(String, String)>[
      (l10n.reportsLoanAmount, mortgageMoney(loan.principalAmount)),
      (l10n.mortgageLoanDate, mortgageDate(loan.loanDate)),
      (l10n.mortgageTenure, mortgageTenure(loan.loanDate)),
      if (loan.totalTopups > 0)
        (l10n.mortgageTotalTopups, mortgageMoney(loan.totalTopups)),
      (l10n.mortgageInterestMonths, '${loan.interestMonths}'),
    ];
    return _card(
      context,
      l10n.mortgageLoanDetails,
      Column(children: [for (final r in rows) _kvRow(context, r.$1, r.$2)]),
    );
  }

  Widget _topupHistoryCard(BuildContext context, AppLocalizations l10n) {
    final topups = _loan.topups;
    return _card(
      context,
      l10n.mortgageTopupHistory,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kvRow(
            context,
            l10n.mortgageTotalTopups,
            mortgageMoney(_loan.totalTopups),
          ),
          const SizedBox(height: 2),
          for (final t in topups.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      mortgageMoney(t.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mortgageDate(t.topupDate),
                    style: TextStyle(
                      color: AppColors.text3(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _goldCard(BuildContext context, AppLocalizations l10n) {
    String? photo;
    for (final o in _loan.ornaments) {
      if (o.firstPhoto != null && isDataImage(o.firstPhoto!)) {
        photo = o.firstPhoto;
        break;
      }
    }
    return _card(
      context,
      l10n.mortgageGoldDetails,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            GestureDetector(
              onTap: () => _viewPhoto(photo!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(
                  decodeDataImage(photo),
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (final o in _loan.ornaments) ...[
            _kvRow(
              context,
              o.ornamentType ?? l10n.mortgageGoldDetails,
              o.purity ?? '-',
            ),
            _kvRow(context, l10n.mortgageNetWeight, '${o.netWeight ?? 0} g'),
          ],
        ],
      ),
    );
  }

  void _viewPhoto(String dataUri) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.memory(decodeDataImage(dataUri)),
          ),
        ),
      ),
    );
  }

  Widget _ledgerCard(BuildContext context, AppLocalizations l10n) {
    final recent = _ledger.reversed.take(4).toList();
    return _card(
      context,
      l10n.mortgageLoanLedger,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in recent) ledgerTile(context, l10n, e),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => MortgageLedgerPage.open(
                context,
                loanId: _loan.id,
                loanNumber: _loan.loanNumber,
              ),
              child: Text(l10n.mortgageViewFullLedger),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentTypeLabel(AppLocalizations l10n, String? type) =>
      switch (type) {
        'principal' => l10n.mortgagePrincipal,
        'closure' => l10n.mortgageClosure,
        _ => l10n.mortgageInterest,
      };

  Widget _payments(BuildContext context, AppLocalizations l10n) {
    return _card(
      context,
      l10n.mortgagePaymentHistory,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in _loan.payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_paymentTypeLabel(l10n, p.paymentType)}'
                          ' · ${mortgageMoney(p.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          mortgageDate(p.paymentDate),
                          style: TextStyle(
                            color: AppColors.text3(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.mortgageReceipt,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.receipt_long_outlined, size: 20),
                    onPressed: () => widget.onReceipt(_loan, p),
                  ),
                  if (_loan.isActive &&
                      widget.canManage &&
                      p.paymentType != 'closure')
                    IconButton(
                      tooltip: l10n.mortgageEditPayment,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          _run((loan) async => widget.onEditPayment(loan, p)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: AppColors.text3(context),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.mortgageSecureNote,
            style: TextStyle(color: AppColors.text3(context), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: AppColors.text3(context), fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _actionBar(BuildContext context, AppLocalizations l10n) {
    final loan = _loan;
    final buttons = <Widget>[];
    if (loan.isActive) {
      buttons.add(
        _actBtn(
          l10n.mortgageCollect,
          Icons.payments_outlined,
          AppColors.success,
          () => _run(widget.onCollect),
        ),
      );
      if (widget.canManage) {
        buttons.add(
          _actBtn(
            l10n.mortgageTopupShort,
            Icons.add_card_outlined,
            AppColors.primary,
            () => _run(widget.onTopUp),
          ),
        );
        buttons.add(
          _actBtn(
            l10n.mortgagePrintShort,
            Icons.print_outlined,
            AppColors.info,
            () => _statement(share: false),
          ),
        );
        buttons.add(
          _actBtn(
            l10n.mortgageClose,
            Icons.lock_outline_rounded,
            AppColors.error,
            () => _run(widget.onClose),
          ),
        );
      }
    } else if (widget.canManage) {
      buttons.add(
        _actBtn(
          l10n.mortgageReopen,
          Icons.lock_open_rounded,
          AppColors.primary,
          () => _run(widget.onReopen),
        ),
      );
      buttons.add(
        _actBtn(
          l10n.mortgagePrintShort,
          Icons.print_outlined,
          AppColors.info,
          () => _statement(share: false),
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: buttons[i]),
          ],
        ],
      ),
    );
  }

  Widget _actBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
