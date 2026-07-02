import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/customers/application/customers_providers.dart';
import 'package:swarnbook/features/customers/data/models/customer.dart';
import 'package:swarnbook/features/customers/presentation/screens/customer_form_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_export.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final ApiClient _api = ApiClient();
  final _searchController = TextEditingController();
  String _search = '';
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
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

  Future<void> _openForm({Customer? customer}) async {
    if (!_canManage) return;
    final changed = await CustomerFormPage.open(context, customer: customer);
    if (changed == true && mounted) ref.invalidate(customersProvider);
  }

  String _formatAmount(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(customersProvider);

    return AppStateView<List<Customer>>(
      value: async,
      onRetry: () => ref.invalidate(customersProvider),
      data: (customers) {
        final filtered = _search.isEmpty
            ? customers
            : customers.where((c) => c.matches(_search)).toList();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(customersProvider.future),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: l10n.customersSearchHint,
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    if (_canManage) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        tooltip: l10n.exportCsv,
                        onPressed: () => exportAndShareCsv(
                          context,
                          'customers',
                          query: _search.isEmpty ? null : {'search': _search},
                        ),
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        tooltip: l10n.customerAdd,
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? (_search.isNotEmpty
                          ? EmptyState.noResults(query: _search)
                          : EmptyState.customers(
                              onAction: _canManage ? () => _openForm() : null,
                            ))
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _row(l10n, filtered[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(AppLocalizations l10n, Customer c) {
    return CompactDataRow(
      leading: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          c.name.isEmpty ? 'U' : c.name[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      title: c.name,
      subtitle: [
        c.phone ?? l10n.customerNoPhone,
        c.city,
      ].where((p) => p != null && p.isNotEmpty).join(' • '),
      metrics: [
        ('₹', _formatAmount(c.totalPurchases)),
        (l10n.customerVisits, '${c.totalVisits}'),
      ],
      trailing: c.preferredKarat != null
          ? StatusBadge(label: c.preferredKarat!, color: AppColors.gold)
          : null,
      onTap: _canManage ? () => _openForm(customer: c) : null,
    );
  }
}
