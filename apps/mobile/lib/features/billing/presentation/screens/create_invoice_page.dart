import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_image.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen "Create Invoice" form. Pricing is computed by the server via
/// `POST /invoices/preview` (the shown total equals the charged total), and
/// creation sends a stable idempotency key so a double-tap or retry cannot
/// create two invoices. Returns `true` when an invoice was created.
class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  static Future<bool?> open(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const CreateInvoicePage(),
      ),
    );
  }

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

/// Which customer the bill is for. Walk-in always bills as "Walk-in Customer"
/// (the API rejects a nameless bill); Existing picks a saved customer;
/// New snapshots typed details onto the invoice.
enum _CustomerMode { walkIn, existing, newCustomer }

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _repo = InvoiceRepository();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerAddress = TextEditingController();
  final _inventorySearch = TextEditingController();
  final _goldRate = TextEditingController();
  final _makingPerGram = TextEditingController();
  final _gstPercent = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _amountPaid = TextEditingController(text: '0');
  final _notes = TextEditingController();

  late final String _idempotencyKey;
  late final DateTime _openedAt;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;

  List<BillingCustomerOption> _customers = const [];
  List<BillingInventoryItem> _items = const [];
  _CustomerMode _customerMode = _CustomerMode.walkIn;
  String? _selectedCustomerId;
  final Set<String> _selectedItemIds = {};
  final Map<String, int> _selectedQuantities = {};
  String _paymentMode = 'cash';

  Timer? _previewDebounce;
  InvoicePreview? _preview;
  bool _isPreviewing = false;
  bool _previewFailed = false;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = _generateIdempotencyKey();
    _openedAt = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _customerName.dispose();
    _customerPhone.dispose();
    _customerAddress.dispose();
    _inventorySearch.dispose();
    _goldRate.dispose();
    _makingPerGram.dispose();
    _gstPercent.dispose();
    _discount.dispose();
    _amountPaid.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _generateIdempotencyKey() {
    final r = Random();
    final rand = List.generate(
      16,
      (_) => r.nextInt(16).toRadixString(16),
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-$rand';
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getFormData();
      if (!mounted) return;
      setState(() {
        _customers = data.customers;
        _items = data.items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Derived selection state
  // ---------------------------------------------------------------------------

  List<BillingInventoryItem> get _filteredItems {
    final q = _inventorySearch.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.matches(q)).toList();
  }

  List<BillingInventoryItem> get _selectedItems =>
      _items.where((i) => _selectedItemIds.contains(i.id)).toList();

  int _qtyOf(BillingInventoryItem item) =>
      item.isBulk ? (_selectedQuantities[item.id] ?? 1) : 1;

  int get _totalUnits => _selectedItems.fold(0, (sum, i) => sum + _qtyOf(i));

  double get _totalWeight =>
      _selectedItems.fold(0.0, (sum, i) => sum + i.netWeight * _qtyOf(i));

  BillingCustomerOption? get _selectedCustomer {
    if (_selectedCustomerId == null) return null;
    for (final c in _customers) {
      if (c.id == _selectedCustomerId) return c;
    }
    return null;
  }

  double? _parse(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  /// Metal rate to show on the Gold Rate card: the typed override, else the
  /// effective rate the server used for the first rate-priced line.
  double? get _effectiveRate {
    final typed = _parse(_goldRate);
    if (typed != null && typed > 0) return typed;
    for (final line in _preview?.items ?? const <InvoicePreviewLine>[]) {
      if (line.ratePerGram > 0) return line.ratePerGram;
    }
    return null;
  }

  double? get _effectiveGstPercent {
    final typed = _parse(_gstPercent);
    if (typed != null) return typed;
    final p = _preview;
    if (p != null && p.taxableAmount > 0) {
      return p.totalTax / p.taxableAmount * 100;
    }
    return null;
  }

  List<InvoiceDraftItem> _selectedDraftItems() {
    final rows = <InvoiceDraftItem>[];
    for (final item in _selectedItems) {
      rows.add(
        InvoiceDraftItem(inventoryItemId: item.id, quantity: _qtyOf(item)),
      );
    }
    return rows;
  }

  InvoiceDraft _buildDraft({required bool forPreview}) {
    final typedName = _customerName.text.trim();
    final address = _customerAddress.text.trim();
    final isExisting =
        _customerMode == _CustomerMode.existing && _selectedCustomerId != null;

    String? name;
    if (isExisting) {
      name = null; // Server pulls the saved customer's snapshot.
    } else if (_customerMode == _CustomerMode.walkIn) {
      name = 'Walk-in Customer';
    } else {
      // New customer: a name is required to save, but preview still needs one.
      name = typedName.isEmpty && forPreview ? 'Walk-in Customer' : typedName;
    }

    return InvoiceDraft(
      customerId: isExisting ? _selectedCustomerId : null,
      customerName: name,
      customerPhone: isExisting || _customerMode == _CustomerMode.walkIn
          ? null
          : _customerPhone.text.trim(),
      customerAddress: isExisting || _customerMode == _CustomerMode.walkIn
          ? null
          : (address.isEmpty ? null : address),
      items: _selectedDraftItems(),
      discountAmount: double.tryParse(_discount.text.trim()) ?? 0,
      amountPaid: double.tryParse(_amountPaid.text.trim()) ?? 0,
      paymentMode: _paymentMode,
      notes: _notes.text.trim(),
      ratePerGramOverride: _parse(_goldRate),
      makingPerGramOverride: _parse(_makingPerGram),
      gstPercentOverride: _parse(_gstPercent),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  void _schedulePreview() {
    _previewDebounce?.cancel();
    if (_selectedItemIds.isEmpty) {
      setState(() {
        _preview = null;
        _isPreviewing = false;
        _previewFailed = false;
        _previewError = null;
      });
      return;
    }
    setState(() => _isPreviewing = true);
    _previewDebounce = Timer(
      const Duration(milliseconds: 400),
      _refreshPreview,
    );
  }

  Future<void> _refreshPreview() async {
    final draft = _buildDraft(forPreview: true);
    try {
      final preview = await _repo.preview(draft);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isPreviewing = false;
        _previewFailed = false;
        _previewError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreviewing = false;
        _previewFailed = true;
        // Surface the server's reason (e.g. "No rate set for gold 22K…").
        _previewError = e is DioException ? e.message : null;
      });
    }
  }

  double get _amountPaidValue => double.tryParse(_amountPaid.text.trim()) ?? 0;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_customerMode == _CustomerMode.existing &&
        _selectedCustomerId == null) {
      AppToast.error(context, l10n.billingSearchCustomer);
      return;
    }
    if (_customerMode == _CustomerMode.newCustomer &&
        _customerName.text.trim().isEmpty) {
      AppToast.error(context, l10n.validationCustomerNameRequired);
      return;
    }
    if (_selectedItemIds.isEmpty) {
      AppToast.error(context, l10n.errorSelectInventoryItem);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repo.create(
        _buildDraft(forPreview: false),
        idempotencyKey: _idempotencyKey,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, l10n.errorFailedCreateInvoice);
      }
    }
  }

  void _setMode(_CustomerMode mode) {
    setState(() {
      _customerMode = mode;
      if (mode != _CustomerMode.existing) _selectedCustomerId = null;
      if (mode != _CustomerMode.newCustomer) {
        _customerName.clear();
        _customerPhone.clear();
        _customerAddress.clear();
      }
    });
    _schedulePreview();
  }

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<BillingCustomerOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _CustomerPickerSheet(customers: _customers),
    );
    if (picked == null) return;
    setState(() => _selectedCustomerId = picked.id);
    _schedulePreview();
  }

  void _clearSelection() {
    setState(() {
      _selectedItemIds.clear();
      _selectedQuantities.clear();
    });
    _schedulePreview();
  }

  void _toggleItem(BillingInventoryItem item, bool selected) {
    setState(() {
      if (selected) {
        _selectedItemIds.add(item.id);
        _selectedQuantities.putIfAbsent(item.id, () => 1);
      } else {
        _selectedItemIds.remove(item.id);
        _selectedQuantities.remove(item.id);
      }
    });
    _schedulePreview();
  }

  void _setQuantity(BillingInventoryItem item, int qty) {
    setState(() => _selectedQuantities[item.id] = qty);
    _schedulePreview();
  }

  Future<void> _editPricing({
    required TextEditingController controller,
    required String title,
    required String prefix,
    required String suffix,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final field = TextEditingController(text: controller.text);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.text1(ctx),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: field,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.billingEditValue,
                prefixText: prefix.isEmpty ? null : prefix,
                suffixText: suffix.isEmpty ? null : suffix,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: AppSpacing.md),
            GoldButton(
              label: l10n.commonSave,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      controller.text = field.text.trim();
      _schedulePreview();
    }
    field.dispose();
  }

  void _showFullPreview() {
    final p = _preview;
    if (p == null || p.items.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brd(ctx),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              SectionHeader(title: l10n.billingBillPreview),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: SingleChildScrollView(child: _BillBreakdown(preview: p)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_isLoading) {
      body = const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_loadFailed) {
      body = Padding(
        padding: const EdgeInsets.only(top: 80),
        child: AppErrorView(
          message: l10n.errorFailedLoadBillingData,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _loadFailed = false;
            });
            _load();
          },
        ),
      );
    } else {
      body = KeyboardDismissRegion(
        child: KeyboardAwareScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _customerSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              _inventorySection(l10n),
              if (_selectedItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _selectedSection(l10n),
              ],
              const SizedBox(height: AppSpacing.lg),
              _pricingSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              _paymentSection(l10n),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.commonClose,
          icon: const Icon(Icons.close_rounded),
          onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.billingCreateInvoice),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _secureBadge(l10n),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: _isLoading || _loadFailed ? null : _bottomBar(l10n),
    );
  }

  Widget _secureBadge(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_rounded, size: 16, color: AppColors.success),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.billingSecure,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text2(context),
              ),
            ),
            Text(
              l10n.billingDataSafe,
              style: TextStyle(fontSize: 9, color: AppColors.text3(context)),
            ),
          ],
        ),
      ],
    );
  }

  // ------- Customer -------

  Widget _customerSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.billingCustomerDetails),
        const SizedBox(height: AppSpacing.sm),
        SectionSwitch(
          activeValue: _customerMode.name,
          onChanged: (v) =>
              _setMode(_CustomerMode.values.firstWhere((m) => m.name == v)),
          items: [
            SectionItem(
              value: _CustomerMode.walkIn.name,
              label: l10n.billingCustomerWalkIn,
              icon: Icons.directions_walk_rounded,
            ),
            SectionItem(
              value: _CustomerMode.existing.name,
              label: l10n.billingCustomerExisting,
              icon: Icons.people_alt_rounded,
            ),
            SectionItem(
              value: _CustomerMode.newCustomer.name,
              label: l10n.billingCustomerNew,
              icon: Icons.person_add_alt_1_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        switch (_customerMode) {
          _CustomerMode.walkIn => _walkInNote(l10n),
          _CustomerMode.existing => _existingCustomer(l10n),
          _CustomerMode.newCustomer => _newCustomerFields(l10n),
        },
      ],
    );
  }

  Widget _walkInNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_walk_rounded,
            size: 18,
            color: AppColors.text3(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.billingWalkInNote,
              style: TextStyle(color: AppColors.text2(context), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _existingCustomer(AppLocalizations l10n) {
    final customer = _selectedCustomer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _customers.isEmpty ? null : _pickCustomer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfL(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.brd(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.text3(context)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    customer?.name ??
                        (_customers.isEmpty
                            ? l10n.billingNoSavedCustomers
                            : l10n.billingSearchCustomer),
                    style: TextStyle(
                      color: customer != null
                          ? AppColors.text1(context)
                          : AppColors.text3(context),
                      fontWeight: customer != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.text3(context),
                ),
              ],
            ),
          ),
        ),
        if (customer != null) ...[
          const SizedBox(height: AppSpacing.md),
          _customerCard(l10n, customer),
        ],
      ],
    );
  }

  Widget _customerCard(AppLocalizations l10n, BillingCustomerOption c) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name ?? l10n.billingCustomerFallback,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.text1(context),
                      ),
                    ),
                    if (c.phone != null) ...[
                      const SizedBox(height: 3),
                      _iconLine(Icons.phone_rounded, c.phone!),
                    ],
                    if (c.location != null) ...[
                      const SizedBox(height: 2),
                      _iconLine(Icons.location_on_outlined, c.location!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (c.totalVisits > 0 || c.totalPurchases > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: AppColors.div(context)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    l10n.billingTotalPurchases,
                    '${c.totalVisits} ${l10n.billingBillsUnit}',
                    null,
                  ),
                ),
                Expanded(
                  child: _miniStat(
                    l10n.billingTotalSpent,
                    billingMoneyGrouped(c.totalPurchases),
                    c.lastVisitAt != null
                        ? '${l10n.billingLastVisit} ${billingDate(c.lastVisitAt)}'
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.text3(context)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: AppColors.text2(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, String? sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.text3(context)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text1(context),
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10.5, color: AppColors.text3(context)),
          ),
        ],
      ],
    );
  }

  Widget _newCustomerFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _customerName,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _schedulePreview(),
          decoration: InputDecoration(
            labelText: l10n.billingCustomerName,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _customerPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.billingMobileNumber,
            prefixIcon: const Icon(Icons.phone_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _customerAddress,
          textCapitalization: TextCapitalization.words,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            labelText: l10n.billingCustomerAddress,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ------- Inventory -------

  Widget _inventorySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.billingSelectInventoryItems),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _inventorySearch,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: l10n.billingSearchInventory,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brd(context)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: _filteredItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l10n.billingNoProductsFound,
                    style: TextStyle(color: AppColors.text3(context)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.div(context)),
                  itemBuilder: (context, index) =>
                      _itemRow(l10n, _filteredItems[index]),
                ),
        ),
      ],
    );
  }

  Widget _itemRow(AppLocalizations l10n, BillingInventoryItem item) {
    final selected = _selectedItemIds.contains(item.id);
    return InkWell(
      onTap: () => _toggleItem(item, !selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: selected,
                onChanged: (v) => _toggleItem(item, v == true),
              ),
            ),
            _thumb(item.firstPhoto, 44),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _itemTitle(l10n, item),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text1(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(label: item.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _itemMetaLine(l10n, item),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text3(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.billingWeight}: ${billingWeight(item.netWeight)}'
                    '  ·  ${l10n.billingPcs}: ${item.availableQuantity}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text3(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _itemTitle(AppLocalizations l10n, BillingInventoryItem item) {
    final name = item.itemName ?? l10n.billingItemFallback;
    return item.karat != null ? '$name (${item.karat})' : name;
  }

  String _itemMetaLine(AppLocalizations l10n, BillingInventoryItem item) {
    final parts = <String>[
      '${l10n.billingTagLabel}: ${item.tagNumber ?? l10n.billingNoTag}',
    ];
    if (item.huid != null) parts.add('${l10n.billingHuid}: ${item.huid}');
    return parts.join('  ·  ');
  }

  // ------- Selected items -------

  Widget _selectedSection(AppLocalizations l10n) {
    final items = _selectedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '${l10n.billingSelectedItems} (${items.length})',
          actionLabel: l10n.billingClearAll,
          onAction: _clearSelection,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brd(context)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.div(context)),
                _selectedRow(l10n, items[i]),
              ],
              Divider(height: 1, color: AppColors.brd(context)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.billingTotalItems}: $_totalUnits',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2(context),
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${l10n.billingTotalWeight}: ${billingWeight(_totalWeight)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text1(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectedRow(AppLocalizations l10n, BillingInventoryItem item) {
    final qty = _qtyOf(item);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _thumb(item.firstPhoto, 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemTitle(l10n, item),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${billingWeight(item.netWeight)}  ·  '
                  '${item.tagNumber ?? l10n.billingNoTag}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.text3(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (item.isBulk)
            _qtyStepper(item, qty)
          else
            Text(
              '${l10n.billingQty}: 1',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text2(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyStepper(BillingInventoryItem item, int qty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(
          Icons.remove_rounded,
          qty > 1 ? () => _setQuantity(item, qty - 1) : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          alignment: Alignment.center,
          child: Text(
            '$qty',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        _stepBtn(
          Icons.add_rounded,
          qty < item.availableQuantity
              ? () => _setQuantity(item, qty + 1)
              : null,
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? AppColors.brd(context) : AppColors.div(context),
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.text1(context) : AppColors.text3(context),
        ),
      ),
    );
  }

  // ------- Pricing -------

  Widget _pricingSection(AppLocalizations l10n) {
    final rate = _effectiveRate;
    final making = _parse(_makingPerGram);
    final gst = _effectiveGstPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.billingBillPricing),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _priceCard(
                label: l10n.billingGoldRate,
                value: rate != null
                    ? '₹${rate.toStringAsFixed(0)}${l10n.billingPerGram}'
                    : l10n.billingTapToSet,
                muted: rate == null,
                onTap: () => _editPricing(
                  controller: _goldRate,
                  title: l10n.billingGoldRatePerGram,
                  prefix: '₹ ',
                  suffix: '',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _priceCard(
                label: l10n.billingMakingCharges,
                value: making != null
                    ? '₹${making.toStringAsFixed(0)}${l10n.billingPerGram}'
                    : l10n.billingAutoRate,
                muted: making == null,
                onTap: () => _editPricing(
                  controller: _makingPerGram,
                  title: l10n.billingMakingPerGram,
                  prefix: '₹ ',
                  suffix: '',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _priceCard(
                label: l10n.billingGst,
                value: gst != null
                    ? '${gst.toStringAsFixed(gst.truncateToDouble() == gst ? 0 : 1)}%'
                    : l10n.billingTapToSet,
                muted: gst == null,
                onTap: () => _editPricing(
                  controller: _gstPercent,
                  title: l10n.billingGstPercent,
                  prefix: '',
                  suffix: '%',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_previewFailed)
          _pricingError(l10n)
        else if (_preview != null && _preview!.items.isNotEmpty)
          _totalsBlock(l10n, _preview!)
        else
          Text(
            l10n.billingBillPricingHint,
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
      ],
    );
  }

  Widget _priceCard({
    required String label,
    required String value,
    required bool muted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfL(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.brd(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.text3(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  size: 12,
                  color: AppColors.text3(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: muted
                      ? AppColors.text3(context)
                      : AppColors.text1(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pricingError(AppLocalizations l10n) {
    final message = (_previewError != null && _previewError!.trim().isNotEmpty)
        ? _previewError!.trim()
        : l10n.errorFailedLoadBillingData;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsBlock(AppLocalizations l10n, InvoicePreview p) {
    final gstPercent = p.taxableAmount > 0
        ? (p.totalTax / p.taxableAmount * 100)
        : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          _totalRow(
            l10n.billingMetalValue,
            billingMoneyGrouped(p.productValue),
          ),
          _totalRow(
            l10n.billingMakingCharges,
            billingMoneyGrouped(p.totalMakingCharges),
          ),
          if (p.totalStoneValue > 0)
            _totalRow(
              l10n.billingStoneValue,
              billingMoneyGrouped(p.totalStoneValue),
            ),
          if (p.discountAmount > 0)
            _totalRow(
              l10n.billingDiscount,
              '− ${billingMoneyGrouped(p.discountAmount)}',
            ),
          _totalRow(
            '${l10n.billingGst} (${gstPercent.toStringAsFixed(gstPercent.truncateToDouble() == gstPercent ? 0 : 1)}%)',
            billingMoneyGrouped(p.totalTax),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: AppColors.brd(context)),
          const SizedBox(height: 6),
          _totalRow(
            l10n.billingGrandTotal,
            billingMoneyGrouped(p.grandTotal),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 15 : 12.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize
                  ? AppColors.text1(context)
                  : AppColors.text3(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 18 : 12.5,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? AppColors.primary : AppColors.text2(context),
            ),
          ),
        ],
      ),
    );
  }

  // ------- Payment -------

  Widget _paymentSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.billingPaymentDetails),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _amountPaid,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.billingAmountPaid,
                  prefixText: '₹ ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<String>(
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
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _discountField(l10n),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _notes,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.commonNotes,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _readonlyField(
                label: l10n.billingInvoiceNumber,
                value: l10n.billingAutoGenerated,
                icon: Icons.tag_rounded,
                muted: true,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _readonlyField(
                label: l10n.billingInvoiceDate,
                value: _formattedOpenedAt(),
                icon: Icons.calendar_today_rounded,
                muted: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.billingRatesHint,
          style: TextStyle(color: AppColors.text3(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _discountField(AppLocalizations l10n) {
    return TextFormField(
      controller: _discount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.billingDiscountAmount,
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => _schedulePreview(),
    );
  }

  Widget _readonlyField({
    required String label,
    required String value,
    required IconData icon,
    required bool muted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.text3(context)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.text3(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: muted
                        ? AppColors.text3(context)
                        : AppColors.text1(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formattedOpenedAt() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = _openedAt;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour12:$min $ampm';
  }

  // ------- Bottom bar & thumbnails -------

  Widget _bottomBar(AppLocalizations l10n) {
    final canPreview = _preview != null && _preview!.items.isNotEmpty;
    final balance = _preview == null
        ? null
        : (_preview!.grandTotal - _amountPaidValue).clamp(0, double.infinity);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          border: Border(top: BorderSide(color: AppColors.brd(context))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_preview != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.billingBalance}: ${billingMoneyGrouped((balance ?? 0).toDouble())}',
                    style: TextStyle(
                      color: AppColors.text3(context),
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isPreviewing) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        '${l10n.billingGrandTotal}: ',
                        style: TextStyle(
                          color: AppColors.text2(context),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        billingMoneyGrouped(_preview!.grandTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: GoldButton(
                    label: l10n.billingPreview,
                    icon: Icons.receipt_long_rounded,
                    isOutlined: true,
                    onPressed: canPreview ? _showFullPreview : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GoldButton(
                    label: l10n.billingCreateInvoice,
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(String? src, double size) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.10),
      child: Icon(
        Icons.diamond_outlined,
        color: AppColors.primary,
        size: size * 0.5,
      ),
    );
    Widget child = fallback;
    if (src != null && src.isNotEmpty) {
      if (isDataImage(src)) {
        try {
          child = Image.memory(
            decodeDataImage(src),
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        } catch (_) {
          child = fallback;
        }
      } else {
        child = Image.network(
          src,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

/// Searchable saved-customer picker (Existing Customer mode).
class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.customers});

  final List<BillingCustomerOption> customers;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BillingCustomerOption> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.customers;
    return widget.customers.where((c) {
      return (c.name ?? '').toLowerCase().contains(q) ||
          (c.phone ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.brd(context),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.billingSearchCustomer,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.billingNoSavedCustomers,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.div(context)),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(c.name ?? l10n.billingCustomerFallback),
                        subtitle: c.phone != null ? Text(c.phone!) : null,
                        trailing: c.totalVisits > 0
                            ? Text(
                                '${c.totalVisits} ${l10n.billingBillsUnit}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.text3(context),
                                ),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Per-item pricing breakdown for the current selection, straight from the
/// server preview: item · karat · qty, net weight @ rate/g, making, line
/// totals, then the Rate / Making / GST summary. Shown in the Preview sheet.
class _BillBreakdown extends StatelessWidget {
  const _BillBreakdown({required this.preview});

  final InvoicePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = preview;
    final gstPercent = p.taxableAmount > 0
        ? (p.totalTax / p.taxableAmount * 100)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < p.items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.div(context)),
            _lineRow(context, l10n, p.items[i]),
          ],
          Divider(height: 1, color: AppColors.brd(context)),
          const SizedBox(height: AppSpacing.sm),
          _totalRow(
            context,
            '${l10n.billingItems} ×${p.items.length} · ${l10n.billingQty} ${p.totalUnits}',
            null,
          ),
          _totalRow(
            context,
            l10n.billingMetalValue,
            billingMoneyGrouped(p.productValue),
          ),
          _totalRow(
            context,
            l10n.billingMakingCharges,
            billingMoneyGrouped(p.totalMakingCharges),
          ),
          if (p.totalStoneValue > 0)
            _totalRow(
              context,
              l10n.billingStoneValue,
              billingMoneyGrouped(p.totalStoneValue),
            ),
          if (p.discountAmount > 0)
            _totalRow(
              context,
              l10n.billingDiscount,
              '− ${billingMoneyGrouped(p.discountAmount)}',
            ),
          _totalRow(
            context,
            '${l10n.billingGst} ${gstPercent.toStringAsFixed(gstPercent.truncateToDouble() == gstPercent ? 0 : 1)}%',
            billingMoneyGrouped(p.totalTax),
          ),
          _totalRow(
            context,
            l10n.billingGrandTotal,
            billingMoneyGrouped(p.grandTotal),
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _lineRow(
    BuildContext context,
    AppLocalizations l10n,
    InvoicePreviewLine line,
  ) {
    final title = [
      line.itemName ?? l10n.billingItemFallback,
      if (line.karat != null) line.karat!,
      if (line.quantity > 1) '×${line.quantity}',
    ].join(' · ');
    final meta = [
      '${line.netWeight.toStringAsFixed(3)} g',
      if (line.ratePerGram > 0) '@ ${billingMoney(line.ratePerGram)}/g',
      if (line.makingCharges > 0)
        '${l10n.billingMakingCharges} ${billingMoney(line.makingCharges)}',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.text3(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            billingMoneyGrouped(line.itemTotal),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.text1(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    String? value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 13.5 : 12.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize
                  ? AppColors.text1(context)
                  : AppColors.text3(context),
            ),
          ),
          if (value != null)
            Text(
              value,
              style: TextStyle(
                fontSize: emphasize ? 15 : 12.5,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? AppColors.primary : AppColors.text2(context),
              ),
            ),
        ],
      ),
    );
  }
}
