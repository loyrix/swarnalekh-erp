import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/shimmer_loading.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/staggered_animation.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _customers = [];
  bool _isLoading = true;
  bool _canManageCustomers = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadCustomers();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (mounted) setState(() => _canManageCustomers = isAdminRole(role));
    } catch (_) {
      if (mounted) setState(() => _canManageCustomers = false);
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final res = await _api.dio.get('/customers');
      if (!mounted) return;
      setState(() {
        _customers = res.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        AppToast.error(context, l10n.errorFailedLoadCustomers);
      }
    }
  }

  Future<void> _openCustomerForm({Map<String, dynamic>? customer}) async {
    if (!_canManageCustomers) return;
    final changed = await showResponsiveDialog<bool>(
      context: context,
      builder: (context) => _CustomerFormDialog(api: _api, customer: customer),
    );

    if (changed == true && mounted) {
      _loadCustomers();
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerState();
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.md),
            _buildSearchBar(),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildCustomerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerBox(width: 120, height: 14),
              ShimmerBox(width: 130, height: 38, borderRadius: AppRadius.md),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Search shimmer
          ShimmerBox(
            width: double.infinity,
            height: 44,
            borderRadius: AppRadius.md,
          ),
          const SizedBox(height: AppSpacing.md),
          // List shimmer
          Expanded(
            child: ListView.separated(
              itemCount: 8,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (_, __) => const ShimmerListTile(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_customers.length} ${l10n.navCustomers}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.text3(context)),
            ),
          ],
        ),
        if (_canManageCustomers)
          PrimaryActionButton.goldButton(
            label: l10n.customerAdd,
            icon: Icons.add_rounded,
            onPressed: () => _openCustomerForm(),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: AppColors.text1(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.customersSearchHint,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.text3(context),
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    final list = _filtered;
    if (list.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyState.noResults(query: _searchQuery);
    }
    if (list.isEmpty) {
      return EmptyState.customers(
        onAction: _canManageCustomers ? () => _openCustomerForm() : null,
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final c = list[index];
        return StaggeredFadeSlide(
          index: index,
          child: _CustomerTile(
            customer: c,
            onTap: _canManageCustomers
                ? () => _openCustomerForm(customer: c)
                : null,
          ),
        );
      },
    );
  }
}

class _CustomerTile extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback? onTap;
  const _CustomerTile({required this.customer, required this.onTap});

  @override
  State<_CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<_CustomerTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.customer;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfL(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    (c['name'] as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['name'] ?? '',
                      style: TextStyle(
                        color: AppColors.text1(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: AppColors.text3(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c['phone'] ?? l10n.customerNoPhone,
                          style: TextStyle(
                            color: AppColors.text3(context),
                            fontSize: 12,
                          ),
                        ),
                        if (c['city'] != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.text3(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c['city'],
                            style: TextStyle(
                              color: AppColors.text3(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Preferred karat
              if (c['preferredKarat'] != null)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: StatusBadge(
                    label: c['preferredKarat'],
                    color: AppColors.gold,
                  ),
                ),
              // Total purchases
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatAmount(c['totalPurchases'])}',
                    style: TextStyle(
                      color: AppColors.text1(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${c['totalVisits'] ?? 0} ${l10n.customerVisits}',
                    style: TextStyle(
                      color: AppColors.text3(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _isHovered
                    ? AppColors.primary
                    : AppColors.text3(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is String ? double.tryParse(amount) ?? 0 : amount;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic>? customer;

  const _CustomerFormDialog({required this.api, this.customer});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _preferredKaratController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?['name']?.toString() ?? '');
    _phoneController = TextEditingController(
      text: c?['phone']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: c?['email']?.toString() ?? '',
    );
    _cityController = TextEditingController(text: c?['city']?.toString() ?? '');
    _preferredKaratController = TextEditingController(
      text: c?['preferredKarat']?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: c?['notes']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _preferredKaratController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final payload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'preferredKarat': _preferredKaratController.text.trim().isEmpty
          ? null
          : _preferredKaratController.text.trim(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (_isEdit) {
        await widget.api.dio.put(
          '/customers/${widget.customer!['id']}',
          data: payload,
        );
      } else {
        await widget.api.dio.post('/customers', data: payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, l10n.errorFailedSaveCustomer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_isEdit ? l10n.commonEdit : l10n.customerAdd),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  _nameController,
                  l10n.customerNameLabel,
                  requiredMessage: l10n.validationCustomerNameRequired,
                ),
                const SizedBox(height: AppSpacing.md),
                _field(_phoneController, l10n.customerPhoneLabel),
                const SizedBox(height: AppSpacing.md),
                _field(_emailController, l10n.customerEmailLabel),
                const SizedBox(height: AppSpacing.md),
                _field(_cityController, l10n.customerCityLabel),
                const SizedBox(height: AppSpacing.md),
                _field(
                  _preferredKaratController,
                  l10n.customerPreferredKaratLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                _field(_notesController, l10n.commonNotes, maxLines: 3),
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
        PrimaryActionButton.goldButton(
          label: _isEdit ? l10n.commonUpdate : l10n.commonCreate,
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? requiredMessage,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (requiredMessage != null &&
            (value == null || value.trim().isEmpty)) {
          return requiredMessage;
        }
        return null;
      },
    );
  }
}
