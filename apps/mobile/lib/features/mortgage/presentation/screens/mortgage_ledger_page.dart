import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

/// Full transaction ledger for a loan (disbursal, top-ups, collections, close).
class MortgageLedgerPage extends StatefulWidget {
  const MortgageLedgerPage({
    super.key,
    required this.loanId,
    required this.loanNumber,
  });

  final String loanId;
  final String? loanNumber;

  static Future<void> open(
    BuildContext context, {
    required String loanId,
    required String? loanNumber,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            MortgageLedgerPage(loanId: loanId, loanNumber: loanNumber),
      ),
    );
  }

  @override
  State<MortgageLedgerPage> createState() => _MortgageLedgerPageState();
}

class _MortgageLedgerPageState extends State<MortgageLedgerPage> {
  final _repo = MortgageRepository();
  late Future<List<MortgageLedgerEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getLedger(widget.loanId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.mortgageLoanLedger} · ${widget.loanNumber ?? ''}'),
      ),
      body: FutureBuilder<List<MortgageLedgerEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data ?? const [];
          if (events.isEmpty) {
            return Center(
              child: Text(
                l10n.mortgageNoLedger,
                style: TextStyle(color: AppColors.text3(context)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: events.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.div(context), height: 1),
            itemBuilder: (context, i) => ledgerTile(context, l10n, events[i]),
          );
        },
      ),
    );
  }
}

String mortgageLedgerLabel(AppLocalizations l10n, String type) =>
    switch (type) {
      'loan_created' => l10n.mortgageLedgerLoanCreated,
      'topup_added' => l10n.mortgageLedgerTopupAdded,
      'interest_collected' => l10n.mortgageLedgerInterestCollected,
      'principal_collected' => l10n.mortgageLedgerPrincipalCollected,
      'closed' => l10n.mortgageLedgerClosed,
      _ => type,
    };

Widget ledgerTile(
  BuildContext context,
  AppLocalizations l10n,
  MortgageLedgerEvent e,
) {
  final credit = e.isCredit;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(
          credit ? Icons.south_west_rounded : Icons.north_east_rounded,
          size: 18,
          color: credit ? AppColors.success : AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mortgageLedgerLabel(l10n, e.type),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                mortgageDate(e.date),
                style: TextStyle(color: AppColors.text3(context), fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          '${credit ? '+' : '−'} ${mortgageMoney(e.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: credit ? AppColors.success : AppColors.text1(context),
          ),
        ),
      ],
    ),
  );
}
