import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
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
  });

  final MortgageLoan loan;
  final bool canManage;
  final LoanAction onCollect;
  final LoanAction onTopUp;
  final LoanAction onClose;
  final LoanAction onReopen;
  final PaymentAction onReceipt;
  final PaymentAction onEditPayment;

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
        ),
      ),
    );
  }

  @override
  State<MortgageDetailPage> createState() => _MortgageDetailPageState();
}

class _MortgageDetailPageState extends State<MortgageDetailPage> {
  final _repo = MortgageRepository();
  late MortgageLoan _loan;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
  }

  Future<void> _refresh() async {
    try {
      final loan = await _repo.getLoan(_loan.id);
      if (mounted) setState(() => _loan = loan);
    } catch (_) {
      /* keep the last known state */
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
              _overview(context, l10n),
              const SizedBox(height: AppSpacing.md),
              _loanDetails(context, l10n),
              if (loan.topups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _topupHistory(context, l10n),
              ],
              if (loan.ornaments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _goldDetails(context, l10n),
              ],
              if (loan.payments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _payments(context, l10n),
              ],
              const SizedBox(height: 96),
            ],
          ),
        ),
        bottomNavigationBar: _actionBar(context, l10n),
      ),
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
      child: Row(
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
          if (phone != null) ...[
            _roundIcon(Icons.call_rounded, AppColors.success, () {
              _launch('tel', phone);
            }),
            const SizedBox(width: AppSpacing.sm),
            _roundIcon(Icons.chat_rounded, const Color(0xFF25D366), () {
              _launch('wa', phone);
            }),
          ],
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _overview(BuildContext context, AppLocalizations l10n) {
    final loan = _loan;
    return _section(
      context,
      l10n.mortgageLoanOverview,
      [
        _bigStat(
          context,
          l10n.mortgagePrincipalOutstanding,
          mortgageMoney(loan.outstandingPrincipal),
        ),
        _bigStat(
          context,
          l10n.mortgagePendingInterest,
          mortgageMoney(loan.pendingInterestAmount),
        ),
        _bigStat(
          context,
          l10n.mortgageTotalPayable,
          mortgageMoney(loan.totalPayableAmount),
          emphasize: true,
        ),
      ],
      extraRows: [
        (l10n.mortgageNextDue, mortgageDate(loan.nextDueDate)),
        (l10n.mortgageInterestRate, '${loan.interestRateMonthly}%'),
      ],
    );
  }

  Widget _loanDetails(BuildContext context, AppLocalizations l10n) {
    final loan = _loan;
    final rows = <(String, String)>[
      (l10n.reportsLoanAmount, mortgageMoney(loan.principalAmount)),
      (l10n.mortgageLoanDate, mortgageDate(loan.loanDate)),
      (l10n.mortgageTenure, mortgageTenure(loan.loanDate)),
      if (loan.totalTopups > 0)
        (l10n.mortgageTotalTopups, mortgageMoney(loan.totalTopups)),
      (l10n.mortgageInterestMonths, '${loan.interestMonths}'),
    ];
    return _kvSection(context, l10n.mortgageLoanDetails, rows);
  }

  Widget _topupHistory(BuildContext context, AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.mortgageTopupHistory,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                mortgageMoney(_loan.totalTopups),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final t in _loan.topups)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mortgageDate(t.topupDate),
                    style: TextStyle(color: AppColors.text2(context)),
                  ),
                  Text(
                    mortgageMoney(t.amount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _goldDetails(BuildContext context, AppLocalizations l10n) {
    final rows = <(String, String)>[];
    for (final o in _loan.ornaments) {
      rows.add((
        '${o.ornamentType ?? '-'} · ${o.purity ?? '-'}',
        '${o.netWeight ?? 0} g / ${o.grossWeight ?? 0} g',
      ));
    }
    return _kvSection(context, l10n.mortgageGoldDetails, rows);
  }

  String _paymentTypeLabel(AppLocalizations l10n, String? type) =>
      switch (type) {
        'principal' => l10n.mortgagePrincipal,
        'closure' => l10n.mortgageClosure,
        _ => l10n.mortgageInterest,
      };

  Widget _payments(BuildContext context, AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mortgagePaymentHistory,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          for (final p in _loan.payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
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

  // --- section builders ---------------------------------------------------

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> stats, {
    List<(String, String)> extraRows = const [],
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [for (final s in stats) Expanded(child: s)]),
          for (final r in extraRows) _kvRow(context, r.$1, r.$2),
        ],
      ),
    );
  }

  Widget _kvSection(
    BuildContext context,
    String title,
    List<(String, String)> rows,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final r in rows) _kvRow(context, r.$1, r.$2),
        ],
      ),
    );
  }

  Widget _kvRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: AppColors.text3(context), fontSize: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _bigStat(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.text3(context), fontSize: 11),
          maxLines: 2,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: emphasize ? AppColors.primary : AppColors.text1(context),
          ),
        ),
      ],
    );
  }

  Widget _actionBar(BuildContext context, AppLocalizations l10n) {
    final loan = _loan;
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (loan.isActive) ...[
            Expanded(
              child: GoldButton(
                label: l10n.mortgageCollect,
                icon: Icons.payments_outlined,
                onPressed: () => _run(widget.onCollect),
              ),
            ),
            if (widget.canManage) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GoldButton(
                  label: l10n.mortgageAddTopup,
                  icon: Icons.add_card_outlined,
                  isOutlined: true,
                  onPressed: () => _run(widget.onTopUp),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GoldButton(
                  label: l10n.mortgageClose,
                  isOutlined: true,
                  onPressed: () => _run(widget.onClose),
                ),
              ),
            ],
          ] else if (widget.canManage)
            Expanded(
              child: GoldButton(
                label: l10n.mortgageReopen,
                icon: Icons.lock_open_rounded,
                isOutlined: true,
                onPressed: () => _run(widget.onReopen),
              ),
            ),
        ],
      ),
    );
  }
}
