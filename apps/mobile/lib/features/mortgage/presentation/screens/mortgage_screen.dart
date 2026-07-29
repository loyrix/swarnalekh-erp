import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/mortgage/application/mortgage_providers.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/close_loan_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/collect_payment_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/edit_payment_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_detail_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_form_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/topup_loan_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/stat_period.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/stat_period_selector.dart';

class MortgageScreen extends ConsumerStatefulWidget {
  const MortgageScreen({super.key});

  @override
  ConsumerState<MortgageScreen> createState() => _MortgageScreenState();
}

class _MortgageScreenState extends ConsumerState<MortgageScreen> {
  final ApiClient _api = ApiClient();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  MortgageQuery _query = const MortgageQuery();
  String _section = 'active';
  bool _canManage = false;
  StatPeriod _collectionsPeriod = StatPeriod.today;

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
      if (mounted) setState(() => _canManage = isAdminRole(role));
    } catch (_) {
      if (mounted) setState(() => _canManage = false);
    }
  }

  void _selectSection(String value) {
    setState(() {
      _section = value;
      _query = _query.copyWith(status: value);
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = _query.copyWith(search: value));
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(mortgageDashboardProvider(_collectionsPeriod));
    ref.invalidate(mortgageLoansProvider(_query));
    await ref.read(mortgageLoansProvider(_query).future);
  }

  void _invalidate() {
    ref.invalidate(mortgageDashboardProvider(_collectionsPeriod));
    ref.invalidate(mortgageLoansProvider(_query));
  }

  Future<void> _openCreate() async {
    if (!_canManage) return;
    final created = await MortgageFormPage.open(context);
    if (created == true && mounted) {
      AppToast.success(context, AppLocalizations.of(context)!.mortgageCreated);
      _invalidate();
    }
  }

  Future<bool> _openCollect(MortgageLoan loan) async {
    final done = await CollectPaymentPage.open(context, loanId: loan.id);
    if (done == true && mounted) {
      AppToast.success(
        context,
        AppLocalizations.of(context)!.mortgagePaymentSaved,
      );
      _invalidate();
      return true;
    }
    return false;
  }

  Future<bool> _openClose(MortgageLoan loan) async {
    if (!_canManage) return false;
    final done = await CloseLoanPage.open(
      context,
      loanId: loan.id,
      settlementAmount: loan.totalPayableAmount,
    );
    if (done == true && mounted) {
      AppToast.success(
        context,
        AppLocalizations.of(context)!.mortgageLoanClosed,
      );
      _invalidate();
      return true;
    }
    return false;
  }

  Future<bool> _openReceipt(MortgageLoan loan, MortgagePayment payment) async {
    final l10n = AppLocalizations.of(context)!;
    if (loan.id.isEmpty || payment.id.isEmpty) {
      AppToast.error(context, l10n.mortgagePaymentReceiptMissing);
      return false;
    }
    try {
      final payload = await ref
          .read(mortgageRepositoryProvider)
          .getReceipt(loan.id, payment.id);
      await Printing.sharePdf(bytes: payload.bytes, filename: payload.fileName);
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.mortgageFailedGenerateReceipt);
    }
    return false;
  }

  Future<void> _openDetail(MortgageLoan loan) async {
    final changed = await MortgageDetailPage.open(
      context,
      loan: loan,
      canManage: _canManage,
      onCollect: _openCollect,
      onTopUp: _openTopUp,
      onClose: _openClose,
      onReopen: _openReopen,
      onReceipt: _openReceipt,
      onEditPayment: _openEditPayment,
    );
    if (changed == true && mounted) _invalidate();
  }

  Future<bool> _openTopUp(MortgageLoan loan) async {
    final done = await TopUpLoanPage.open(context, loanId: loan.id);
    if (done == true && mounted) {
      AppToast.success(
        context,
        AppLocalizations.of(context)!.mortgageTopupAdded,
      );
      _invalidate();
      return true;
    }
    return false;
  }

  Future<bool> _openReopen(MortgageLoan loan) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mortgageReopen),
        content: Text(l10n.mortgageReopenConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mortgageReopen),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    try {
      await ref.read(mortgageRepositoryProvider).reopenLoan(loan.id);
      if (!mounted) return false;
      AppToast.success(context, l10n.mortgageLoanReopened);
      _invalidate();
      return true;
    } catch (e) {
      if (!mounted) return false;
      final message = e is DioException ? e.message?.trim() : null;
      AppToast.error(
        context,
        (message == null || message.isEmpty)
            ? l10n.mortgageFailedReopen
            : message,
      );
      return false;
    }
  }

  Future<bool> _openEditPayment(
    MortgageLoan loan,
    MortgagePayment payment,
  ) async {
    final done = await EditPaymentPage.open(
      context,
      loanId: loan.id,
      payment: payment,
    );
    if (done == true && mounted) {
      AppToast.success(
        context,
        AppLocalizations.of(context)!.mortgagePaymentSaved,
      );
      _invalidate();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboard = ref
        .watch(mortgageDashboardProvider(_collectionsPeriod))
        .valueOrNull;

    return AppSectionScaffold(
      header: _Header(
        dashboard: dashboard,
        canManage: _canManage,
        searchController: _searchController,
        onSearch: _onSearchChanged,
        onAdd: _openCreate,
        collectionsPeriod: _collectionsPeriod,
        onCollectionsPeriodChanged: (p) =>
            setState(() => _collectionsPeriod = p),
      ),
      sections: [
        SectionItem(
          value: 'active',
          label: l10n.mortgageStatusActive,
          icon: Icons.pending_actions_rounded,
        ),
        SectionItem(
          value: 'closed',
          label: l10n.mortgageStatusClosed,
          icon: Icons.check_circle_outline_rounded,
        ),
        SectionItem(
          value: 'all',
          label: l10n.mortgageStatusAll,
          icon: Icons.list_alt_rounded,
        ),
      ],
      activeSection: _section,
      onSectionChanged: _selectSection,
      onRefresh: _refresh,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final async = ref.watch(mortgageLoansProvider(_query));
    final l10n = AppLocalizations.of(context)!;
    return AppStateView<List<MortgageLoan>>(
      value: async,
      onRetry: () => ref.invalidate(mortgageLoansProvider(_query)),
      data: (loans) {
        if (loans.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 80),
              EmptyState(
                icon: Icons.account_balance_outlined,
                title: l10n.mortgageNoLoansFound,
                subtitle: l10n.mortgageNoLoansSubtitle,
                actionLabel: _canManage ? l10n.mortgageAddMortgage : null,
                onAction: _canManage ? _openCreate : null,
                iconColor: AppColors.primary,
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: loans.length,
          itemBuilder: (context, index) => _loanRow(loans[index]),
        );
      },
    );
  }

  Widget _loanRow(MortgageLoan loan) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = loan.isActive
        ? [
            (l10n.reportsLoanAmount, mortgageMoney(loan.principalAmount)),
            (
              l10n.mortgageOutstanding,
              mortgageMoney(loan.outstandingPrincipal),
            ),
            (
              l10n.mortgagePendingInterest,
              mortgageMoney(loan.pendingInterestAmount),
            ),
          ]
        : [
            (l10n.reportsLoanAmount, mortgageMoney(loan.principalAmount)),
            (l10n.mortgageInterestPaid, mortgageMoney(loan.totalInterestPaid)),
          ];

    return CompactDataRow(
      title: loan.loanNumber ?? l10n.mortgageLoanFallback,
      subtitle: [
        loan.customerName,
        loan.customerPhone,
      ].where((p) => p != null && p.isNotEmpty).join(' • '),
      metrics: metrics,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(label: loan.status),
          ItemActionsMenu(
            actions: [
              ItemAction(
                type: ItemActionType.view,
                customLabel: l10n.mortgageViewDetails,
                onPressed: () => _openDetail(loan),
              ),
              if (loan.isActive)
                ItemAction(
                  type: ItemActionType.collect,
                  customLabel: l10n.mortgageCollect,
                  onPressed: () => _openCollect(loan),
                ),
              if (loan.isActive && _canManage)
                ItemAction(
                  type: ItemActionType.payment,
                  customLabel: l10n.mortgageAddTopup,
                  onPressed: () => _openTopUp(loan),
                ),
              if (loan.isActive && _canManage)
                ItemAction(
                  type: ItemActionType.close,
                  customLabel: l10n.mortgageClose,
                  onPressed: () => _openClose(loan),
                ),
              if (!loan.isActive && _canManage)
                ItemAction(
                  type: ItemActionType.edit,
                  customLabel: l10n.mortgageReopen,
                  onPressed: () => _openReopen(loan),
                ),
            ],
          ),
        ],
      ),
      onTap: () => _openDetail(loan),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.dashboard,
    required this.canManage,
    required this.searchController,
    required this.onSearch,
    required this.onAdd,
    required this.collectionsPeriod,
    required this.onCollectionsPeriodChanged,
  });

  final MortgageDashboard? dashboard;
  final bool canManage;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  final StatPeriod collectionsPeriod;
  final ValueChanged<StatPeriod> onCollectionsPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = dashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.mortgageCollections} · ${StatPeriodSelector.labelFor(context, collectionsPeriod)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text3(context),
                  ),
                ),
                StatPeriodSelector(
                  value: collectionsPeriod,
                  onChanged: onCollectionsPeriodChanged,
                ),
              ],
            ),
          ),
          CompactStatStrip(
            stats: [
              (
                icon: Icons.account_balance_rounded,
                label: l10n.mortgageActive,
                value: '${d.activeLoans}',
                color: AppColors.primary,
              ),
              (
                icon: Icons.check_circle_outline_rounded,
                label: l10n.mortgageClosed,
                value: '${d.closedLoans}',
                color: AppColors.primary,
              ),
              (
                icon: Icons.lock_clock_rounded,
                label: l10n.mortgagePendingInterest,
                value: mortgageMoney(d.pendingInterest),
                // Amber: genuine "needs attention" (interest owed).
                color: AppColors.warning,
              ),
              (
                icon: Icons.currency_rupee_rounded,
                label: l10n.mortgageCollections,
                value: mortgageMoney(d.todaysCollections),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: l10n.mortgageSearchHint,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            if (canManage) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: l10n.mortgageAddMortgage,
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
