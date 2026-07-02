import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/search/application/search_providers.dart';
import 'package:swarnbook/features/search/data/models/search_results.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

/// Global cross-entity search (customers, inventory, invoices). Results are
/// grouped by entity; tapping a hit jumps to that section.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  String _formatAmount(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surf(context),
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: l10n.searchGlobalHint,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? EmptyState(
              icon: Icons.travel_explore_rounded,
              title: l10n.searchStartTitle,
              subtitle: l10n.searchStartSubtitle,
              iconColor: AppColors.primary,
            )
          : AppStateView<SearchResults>(
              value: async,
              onRetry: () => ref.invalidate(searchResultsProvider(_query)),
              data: (results) {
                if (results.isEmpty) {
                  return EmptyState.noResults(query: _query);
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    if (results.customers.isNotEmpty)
                      _group(
                        l10n.navCustomers,
                        results.customers.length,
                        results.customers.map(_customerRow),
                      ),
                    if (results.inventory.isNotEmpty)
                      _group(
                        l10n.navInventory,
                        results.inventory.length,
                        results.inventory.map((h) => _inventoryRow(l10n, h)),
                      ),
                    if (results.invoices.isNotEmpty)
                      _group(
                        l10n.navBilling,
                        results.invoices.length,
                        results.invoices.map((h) => _invoiceRow(l10n, h)),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _group(String title, int count, Iterable<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.text3(context),
            ),
          ),
        ),
        ...rows,
      ],
    );
  }

  Widget _customerRow(CustomerHit c) {
    final l10n = AppLocalizations.of(context)!;
    return CompactDataRow(
      leading: _avatar(c.name),
      title: c.name,
      subtitle: [
        c.phone ?? l10n.customerNoPhone,
        c.city,
      ].where((p) => p != null && p.isNotEmpty).join(' • '),
      onTap: () => context.go('/customers'),
    );
  }

  Widget _inventoryRow(AppLocalizations l10n, InventoryHit item) {
    final title = (item.itemName?.isNotEmpty ?? false)
        ? item.itemName!
        : (item.tagNumber ?? item.metalType);
    return CompactDataRow(
      leading: _avatar(title),
      title: title,
      subtitle: [
        item.tagNumber,
        item.category,
        item.metalType,
      ].where((p) => p != null && p.isNotEmpty).join(' • '),
      metrics: item.sellingPrice != null
          ? [('₹', _formatAmount(item.sellingPrice!))]
          : const [],
      trailing: StatusBadge(label: item.status, color: AppColors.gold),
      onTap: () => context.go('/inventory'),
    );
  }

  Widget _invoiceRow(AppLocalizations l10n, InvoiceHit inv) {
    return CompactDataRow(
      leading: _avatar(inv.invoiceNumber),
      title: inv.invoiceNumber,
      subtitle: [
        inv.customerName,
        inv.invoiceDate,
      ].where((p) => p != null && p.isNotEmpty).join(' • '),
      metrics: [('₹', _formatAmount(inv.grandTotal))],
      trailing: inv.balanceDue > 0
          ? StatusBadge(label: l10n.billingBalance, color: AppColors.warning)
          : StatusBadge(label: l10n.billingPaid, color: AppColors.success),
      onTap: () => context.go('/billing'),
    );
  }

  Widget _avatar(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label.isEmpty ? '?' : label[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
