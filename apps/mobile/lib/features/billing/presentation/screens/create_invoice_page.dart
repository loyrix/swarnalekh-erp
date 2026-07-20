import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen "New Bill" form. Pricing is computed by the server via
/// `POST /invoices/preview` (the shown total equals the charged total), and
/// creation sends a stable idempotency key so a double-tap or retry cannot
/// create two invoices. Returns `true` when an invoice was created.
class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  static Future<bool?> open(BuildContext context) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => const CreateInvoicePage(),
    );
  }

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _repo = InvoiceRepository();
  final _formKey = GlobalKey<FormState>();
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
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;

  List<BillingCustomerOption> _customers = const [];
  List<BillingInventoryItem> _items = const [];
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

  List<BillingInventoryItem> get _filteredItems {
    final q = _inventorySearch.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.matches(q)).toList();
  }

  List<InvoiceDraftItem> _selectedDraftItems() {
    final rows = <InvoiceDraftItem>[];
    for (final item in _items) {
      if (!_selectedItemIds.contains(item.id)) continue;
      final qty = item.isBulk ? (_selectedQuantities[item.id] ?? 1) : 1;
      rows.add(InvoiceDraftItem(inventoryItemId: item.id, quantity: qty));
    }
    return rows;
  }

  InvoiceDraft _buildDraft({required bool forPreview}) {
    final typedName = _customerName.text.trim();
    final address = _customerAddress.text.trim();
    return InvoiceDraft(
      customerId: _selectedCustomerId,
      // Preview needs a non-empty name for a walk-in so pricing can compute.
      customerName: _selectedCustomerId != null
          ? null
          : (typedName.isEmpty && forPreview ? 'Walk-in Customer' : typedName),
      customerPhone: _selectedCustomerId != null
          ? null
          : _customerPhone.text.trim(),
      // A typed address overrides the saved customer's address; blank falls
      // back to the saved one server-side.
      customerAddress: address.isEmpty ? null : address,
      items: _selectedDraftItems(),
      discountAmount: double.tryParse(_discount.text.trim()) ?? 0,
      amountPaid: double.tryParse(_amountPaid.text.trim()) ?? 0,
      paymentMode: _paymentMode,
      notes: _notes.text.trim(),
      ratePerGramOverride: double.tryParse(_goldRate.text.trim()),
      makingPerGramOverride: double.tryParse(_makingPerGram.text.trim()),
      gstPercentOverride: double.tryParse(_gstPercent.text.trim()),
    );
  }

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
        // Surface the server's reason (e.g. "No rate set for gold 22K…") so the
        // owner knows what to fix, instead of a generic failure.
        _previewError = e is DioException ? e.message : null;
      });
    }
  }

  double get _amountPaidValue => double.tryParse(_amountPaid.text.trim()) ?? 0;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCustomerId == null && _customerName.text.trim().isEmpty) {
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

  BillingCustomerOption? _findCustomer(String? id) {
    if (id == null) return null;
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _onCustomerChanged(String? value) {
    final customer = _findCustomer(value);
    setState(() {
      _selectedCustomerId = value;
      if (customer != null) {
        _customerName.text = customer.name ?? '';
        _customerPhone.text = customer.phone ?? '';
        _customerAddress.text = customer.address ?? '';
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return AppFormScaffold(
        title: l10n.billingCreateInvoice,
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_loadFailed) {
      return AppFormScaffold(
        title: l10n.billingCreateInvoice,
        children: [
          const SizedBox(height: 80),
          AppErrorView(
            message: l10n.errorFailedLoadBillingData,
            onRetry: () {
              setState(() {
                _isLoading = true;
                _loadFailed = false;
              });
              _load();
            },
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.billingCreateInvoice,
        isSaving: _isSaving,
        saveLabel: l10n.commonCreate,
        onSave: _save,
        footer: _PreviewSummary(
          preview: _preview,
          isPreviewing: _isPreviewing,
          previewFailed: _previewFailed,
          previewError: _previewError,
          amountPaid: _amountPaidValue,
        ),
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
                (c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name ?? l10n.billingCustomerFallback),
                ),
              ),
            ],
            onChanged: _onCustomerChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          // Full-width stacked fields — no truncated floating labels.
          TextFormField(
            controller: _customerName,
            textCapitalization: TextCapitalization.words,
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
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.billingSelectInventoryItems),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _inventorySearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText: l10n.billingSearchInventory,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
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
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) =>
                        _itemRow(l10n, _filteredItems[index]),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.billingBillPricing),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _goldRate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.billingGoldRatePerGram,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _schedulePreview(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _makingPerGram,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.billingMakingPerGram,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _schedulePreview(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 96,
                child: TextFormField(
                  controller: _gstPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.billingGstPercent,
                    suffixText: '%',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _schedulePreview(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.billingBillPricingHint,
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
          // Live per-item breakdown of the selection: karat, weight @ rate,
          // making, line totals, and the Rate / Making / GST 3% summary.
          if (_preview != null && _preview!.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.billingBillPreview),
            const SizedBox(height: AppSpacing.sm),
            _BillBreakdown(preview: _preview!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _discount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.billingDiscountAmount,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _schedulePreview(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.commonNotes,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.billingRatesHint,
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(AppLocalizations l10n, BillingInventoryItem item) {
    final selected = _selectedItemIds.contains(item.id);
    final selectedQty = _selectedQuantities[item.id] ?? 1;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brd(context))),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (checked) => _toggleItem(item, checked == true),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName ?? l10n.billingItemFallback),
                const SizedBox(height: 4),
                Text(
                  '${item.metalType ?? ''} ${item.karat ?? ''} | '
                  '${item.tagNumber ?? l10n.billingNoTag} | '
                  '${item.isBulk ? l10n.billingBulk : l10n.billingUnique}',
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (item.isBulk)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: selected && selectedQty > 1
                      ? () => _setQuantity(item, selectedQty - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Container(
                  width: 96,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.brd(context)),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '$selectedQty / ${item.availableQuantity}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: selected && selectedQty < item.availableQuantity
                      ? () => _setQuantity(item, selectedQty + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfL(context),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text('${l10n.billingQty} 1'),
            ),
        ],
      ),
    );
  }
}

/// The server-computed totals shown just above the save bar.
class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({
    required this.preview,
    required this.isPreviewing,
    required this.previewFailed,
    required this.previewError,
    required this.amountPaid,
  });

  final InvoicePreview? preview;
  final bool isPreviewing;
  final bool previewFailed;
  final String? previewError;
  final double amountPaid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = preview;

    if (previewFailed) {
      final message = (previewError != null && previewError!.trim().isNotEmpty)
          ? previewError!.trim()
          : l10n.errorFailedLoadBillingData;
      return _shell(
        context,
        borderColor: AppColors.error,
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

    if (p == null) {
      return _shell(
        context,
        child: Row(
          children: [
            if (isPreviewing) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (!isPreviewing)
              Text(
                l10n.billingSelectInventoryItems,
                style: TextStyle(color: AppColors.text3(context), fontSize: 12),
              ),
          ],
        ),
      );
    }

    final balance = (p.grandTotal - amountPaid).clamp(0, double.infinity);
    return _shell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: 4,
            children: [
              _metric(context, l10n.billingSelectedUnits, '${p.totalUnits}'),
              _metric(
                context,
                l10n.billingProductValue,
                billingMoney(p.productValue),
              ),
              _metric(
                context,
                l10n.billingMakingCharges,
                billingMoney(p.totalMakingCharges),
              ),
              _metric(context, l10n.billingGst, billingMoney(p.totalTax)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.billingBalance}: ${billingMoney(balance.toDouble())}',
                style: TextStyle(color: AppColors.text2(context), fontSize: 12),
              ),
              Row(
                children: [
                  if (isPreviewing) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    '${l10n.billingFinalTotal}: ${billingMoney(p.grandTotal)}',
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
        ],
      ),
    );
  }

  Widget _shell(
    BuildContext context, {
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: borderColor != null
            ? borderColor.withValues(alpha: 0.06)
            : AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor ?? AppColors.brd(context)),
      ),
      child: child,
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppColors.text1(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-item pricing breakdown for the current selection, straight from the
/// server preview: item · karat · qty, net weight @ rate/g, making, line
/// totals, then the Rate / Making / GST (3%) summary.
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
          _totalRow(context, l10n.billingRate, billingMoney(p.productValue)),
          _totalRow(
            context,
            l10n.billingMakingCharges,
            billingMoney(p.totalMakingCharges),
          ),
          if (p.totalStoneValue > 0)
            _totalRow(
              context,
              l10n.billingStoneValue,
              billingMoney(p.totalStoneValue),
            ),
          if (p.discountAmount > 0)
            _totalRow(
              context,
              l10n.billingDiscount,
              '− ${billingMoney(p.discountAmount)}',
            ),
          _totalRow(
            context,
            '${l10n.billingGst} ${gstPercent.toStringAsFixed(gstPercent.truncateToDouble() == gstPercent ? 0 : 1)}%',
            billingMoney(p.totalTax),
          ),
          _totalRow(
            context,
            l10n.billingFinalTotal,
            billingMoney(p.grandTotal),
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
            billingMoney(line.itemTotal),
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
