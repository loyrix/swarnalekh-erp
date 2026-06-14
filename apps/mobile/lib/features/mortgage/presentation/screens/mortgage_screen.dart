import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/mortgage/application/mortgage_receipt_payloads.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

class MortgageScreen extends StatefulWidget {
  const MortgageScreen({super.key});

  @override
  State<MortgageScreen> createState() => _MortgageScreenState();
}

class _MortgageScreenState extends State<MortgageScreen> {
  final ApiClient _api = ApiClient();
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  Map<String, dynamic> _dashboard = {};
  List<dynamic> _loans = [];
  bool _isLoading = true;
  bool _canManageMortgage = false;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadData();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (mounted) setState(() => _canManageMortgage = isAdminRole(role));
    } catch (_) {
      if (mounted) setState(() => _canManageMortgage = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final query = <String, dynamic>{
        if (_status != 'all') 'status': _status,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      };
      final responses = await Future.wait([
        _api.dio.get('/mortgages/dashboard'),
        _api.dio.get('/mortgages', queryParameters: query),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboard = responses[0].data as Map<String, dynamic>? ?? {};
        _loans = responses[1].data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, _errorMessage(error, 'Failed to load mortgages'));
    }
  }

  Future<void> _openCreateLoan() async {
    if (!_canManageMortgage) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _MortgageLoanDialog(api: _api),
    );

    if (created == true && mounted) {
      AppToast.success(context, 'Mortgage loan created');
      _loadData();
    }
  }

  Future<void> _openCollectPayment(Map<String, dynamic> loan) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _CollectPaymentDialog(api: _api, loan: loan),
    );

    if (updated == true && mounted) {
      AppToast.success(context, 'Payment saved');
      _loadData();
    }
  }

  Future<void> _openCloseLoan(Map<String, dynamic> loan) async {
    if (!_canManageMortgage) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _CloseLoanDialog(api: _api, loan: loan),
    );

    if (updated == true && mounted) {
      AppToast.success(context, 'Loan closed');
      _loadData();
    }
  }

  Future<void> _openPaymentReceipt(
    Map<String, dynamic> loan,
    Map<String, dynamic> payment,
  ) async {
    final loanId = loan['id']?.toString() ?? '';
    final paymentId = payment['id']?.toString() ?? '';
    if (loanId.isEmpty || paymentId.isEmpty) {
      AppToast.error(context, 'Payment receipt is missing');
      return;
    }

    try {
      final response = await _api.dio.get(
        '/mortgages/$loanId/payments/$paymentId/receipt',
      );
      final payload = decodeMortgageReceiptPdfPayload(
        Map<String, dynamic>.from(response.data as Map),
        fallbackFileName: 'mortgage-receipt-$paymentId.pdf',
      );
      await Printing.sharePdf(bytes: payload.bytes, filename: payload.fileName);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Failed to generate payment receipt');
      }
    }
  }

  String _money(dynamic value) => _currency.format(_asDouble(value));

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _errorMessage(Object error, String fallback) {
    if (error is DioException && error.message?.isNotEmpty == true) {
      return error.message!;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: KeyboardAwareScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildDashboardCards(),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(),
            const SizedBox(height: AppSpacing.md),
            _buildLoanList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mortgage / Gold Loan',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Track pledged ornaments, interest, receipts, and loan closure.',
                style: TextStyle(color: AppColors.text3(context)),
              ),
            ],
          ),
        ),
        if (_canManageMortgage)
          GoldButton(
            label: 'Add Mortgage',
            icon: Icons.add_rounded,
            onPressed: _openCreateLoan,
          ),
      ],
    );
  }

  Widget _buildDashboardCards() {
    final cards = [
      StatCard(
        icon: Icons.account_balance_rounded,
        label: 'Active Loans',
        value: _asInt(_dashboard['activeLoans']).toString(),
        accentColor: AppColors.info,
      ),
      StatCard(
        icon: Icons.check_circle_outline_rounded,
        label: 'Closed Loans',
        value: _asInt(_dashboard['closedLoans']).toString(),
        accentColor: AppColors.success,
      ),
      StatCard(
        icon: Icons.lock_clock_rounded,
        label: 'Pending Interest',
        value: _money(_dashboard['pendingInterest']),
        accentColor: AppColors.warning,
      ),
      StatCard(
        icon: Icons.payments_rounded,
        label: 'Total Loan Amount',
        value: _money(_dashboard['totalLoanAmount']),
        accentColor: AppColors.primary,
      ),
      StatCard(
        icon: Icons.currency_rupee_rounded,
        label: "Today's Collections",
        value: _money(_dashboard['todaysCollections']),
        accentColor: AppColors.success,
      ),
      StatCard(
        icon: Icons.event_busy_rounded,
        label: 'Overdue Loans',
        value: _asInt(_dashboard['overdueLoans']).toString(),
        accentColor: AppColors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1280
            ? 6
            : (constraints.maxWidth > 760 ? 3 : 2);
        final width =
            (constraints.maxWidth - ((count - 1) * AppSpacing.md)) / count;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildFilters() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadData(),
              decoration: InputDecoration(
                hintText: 'Search customer, mobile, or loan number',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.text3(context),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _loadData,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          _statusChip('active', 'Active'),
          _statusChip('closed', 'Closed'),
          _statusChip('all', 'All'),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _status == value;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        value == 'closed'
            ? Icons.check_circle_outline_rounded
            : value == 'active'
            ? Icons.pending_actions_rounded
            : Icons.list_alt_rounded,
        size: 18,
        color: selected ? AppColors.primary : AppColors.text2(context),
      ),
      label: Text(label),
      onSelected: (_) {
        setState(() => _status = value);
        _loadData();
      },
    );
  }

  Widget _buildLoanList() {
    if (_loans.isEmpty) {
      return SizedBox(
        height: 360,
        child: EmptyState(
          icon: Icons.account_balance_outlined,
          title: 'No mortgage loans found',
          subtitle: 'Create a gold loan or adjust the search and filters.',
          actionLabel: _canManageMortgage ? 'Add Mortgage' : null,
          onAction: _canManageMortgage ? _openCreateLoan : null,
          iconColor: AppColors.primary,
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _loans.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final loan = Map<String, dynamic>.from(_loans[index] as Map);
        return _MortgageLoanCard(
          loan: loan,
          money: _money,
          onCollect: () => _openCollectPayment(loan),
          onClose: _canManageMortgage ? () => _openCloseLoan(loan) : null,
          onReceipt: (payment) => _openPaymentReceipt(loan, payment),
        );
      },
    );
  }
}

class _MortgageLoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final String Function(dynamic value) money;
  final VoidCallback onCollect;
  final VoidCallback? onClose;
  final ValueChanged<Map<String, dynamic>> onReceipt;

  const _MortgageLoanCard({
    required this.loan,
    required this.money,
    required this.onCollect,
    required this.onClose,
    required this.onReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final status = loan['status']?.toString() ?? 'active';
    final isActive = status == 'active';
    final ornaments = loan['ornaments'] as List<dynamic>? ?? const [];
    final payments = (loan['payments'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((payment) => Map<String, dynamic>.from(payment))
        .toList();
    final nextDueDate = _formatDate(loan['nextDueDate']);
    final closedAt = _formatDate(loan['closedAt']);
    final verificationItems = [
      if (_hasText(loan['aadhaarNumber'])) 'Aadhaar',
      if (_hasText(loan['panNumber'])) 'PAN',
      if (_hasText(loan['photoIdUrl'])) 'Photo ID',
      if (_hasText(loan['customerPhotoUrl'])) 'Customer Photo',
    ];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            loan['loanNumber']?.toString() ?? 'Mortgage Loan',
                            style: Theme.of(context).textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusBadge(label: status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                            loan['customerName']?.toString() ?? 'Customer',
                            loan['customerPhone']?.toString(),
                          ]
                          .where((part) => part != null && part.isNotEmpty)
                          .join(' • '),
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                TextButton.icon(
                  onPressed: onCollect,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Collect'),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Close'),
                  ),
                ],
              ],
            ],
          ),
          if (verificationItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: verificationItems
                  .map(
                    (label) => Chip(
                      avatar: const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                      ),
                      label: Text(label),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _metric(context, 'Loan Amount', money(loan['principalAmount'])),
              if (isActive) ...[
                _metric(
                  context,
                  'Outstanding',
                  money(loan['outstandingPrincipal']),
                ),
                _metric(
                  context,
                  'Pending Interest',
                  money(loan['pendingInterestAmount']),
                ),
                _metric(
                  context,
                  'Total Payable',
                  money(loan['totalPayableAmount']),
                ),
              ] else ...[
                _metric(
                  context,
                  'Interest Paid',
                  money(loan['totalInterestPaid']),
                ),
                _metric(context, 'Closing Date', closedAt),
                _metric(context, 'Loan Status', status),
              ],
              _metric(
                context,
                'Interest Rate',
                '${loan['interestRateMonthly']}%',
              ),
              if (isActive) _metric(context, 'Next Due', nextDueDate),
              _metric(context, 'Ornaments', ornaments.length.toString()),
            ],
          ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: payments.take(3).map((payment) {
                final receiptNumber = payment['receiptNumber']
                    ?.toString()
                    .trim();
                return TextButton.icon(
                  onPressed: () => onReceipt(payment),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    receiptNumber == null || receiptNumber.isEmpty
                        ? 'Receipt'
                        : receiptNumber,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
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
            style: TextStyle(color: AppColors.text3(context), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text1(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  bool _hasText(dynamic value) => value?.toString().trim().isNotEmpty == true;
}

class _MortgageLoanDialog extends StatefulWidget {
  final ApiClient api;

  const _MortgageLoanDialog({required this.api});

  @override
  State<_MortgageLoanDialog> createState() => _MortgageLoanDialogState();
}

class _MortgageLoanDialogState extends State<_MortgageLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerAddress = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _ornamentType = TextEditingController();
  final _grossWeight = TextEditingController();
  final _netWeight = TextEditingController();
  final _loanAmount = TextEditingController();
  final _interestRate = TextEditingController(text: '2');
  final _loanDate = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _notes = TextEditingController();
  bool _isSaving = false;
  String _purity = '22K';
  String? _photoIdUrl;
  String? _customerPhotoUrl;

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _customerAddress.dispose();
    _aadhaar.dispose();
    _pan.dispose();
    _ornamentType.dispose();
    _grossWeight.dispose();
    _netWeight.dispose();
    _loanAmount.dispose();
    _interestRate.dispose();
    _loanDate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseVerificationImage(String target) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final dataUri = verificationImageDataUri(
      bytes: bytes,
      mimeType: image.mimeType ?? _mimeTypeForImage(image.name),
    );
    setState(() {
      if (target == 'photoId') {
        _photoIdUrl = dataUri;
      } else {
        _customerPhotoUrl = dataUri;
      }
    });
  }

  void _clearVerificationImage(String target) {
    setState(() {
      if (target == 'photoId') {
        _photoIdUrl = null;
      } else {
        _customerPhotoUrl = null;
      }
    });
  }

  Future<void> _pickLoanDate() async {
    final current = _parseLoanDate(_loanDate.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _loanDate.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final grossWeight = _number(_grossWeight.text);
    final netWeight = _number(_netWeight.text);
    final loanDate = _parseLoanDate(_loanDate.text);
    if (loanDate == null) {
      AppToast.error(context, 'Enter a valid loan date');
      return;
    }
    if (netWeight > grossWeight) {
      AppToast.error(context, 'Net weight cannot exceed gross weight');
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      'customerName': _customerName.text.trim(),
      'customerPhone': _emptyToNull(_customerPhone.text),
      'customerAddress': _emptyToNull(_customerAddress.text),
      'aadhaarNumber': _emptyToNull(_aadhaar.text),
      'panNumber': _emptyToNull(_pan.text),
      'photoIdUrl': _photoIdUrl,
      'customerPhotoUrl': _customerPhotoUrl,
      'principalAmount': _number(_loanAmount.text),
      'interestRateMonthly': _number(_interestRate.text),
      'loanDate': loanDate.toIso8601String(),
      'notes': _emptyToNull(_notes.text),
      'ornaments': [
        {
          'ornamentType': _ornamentType.text.trim(),
          'purity': _purity,
          'grossWeight': grossWeight,
          'netWeight': netWeight,
        },
      ],
    };

    try {
      await widget.api.dio.post('/mortgages', data: payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        _errorMessage(error, 'Failed to create mortgage'),
      );
    }
  }

  Widget _verificationImageField({
    required String label,
    required String? value,
    required VoidCallback onChoose,
    required VoidCallback onClear,
  }) {
    final hasImage = value != null && value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasImage
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.surf(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.brd(context)),
            ),
            child: Icon(
              hasImage
                  ? Icons.check_circle_outline_rounded
                  : Icons.add_photo_alternate_outlined,
              color: hasImage ? AppColors.success : AppColors.text3(context),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  hasImage ? 'Selected' : 'Choose image',
                  style: TextStyle(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Choose $label',
            onPressed: onChoose,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Remove $label',
            onPressed: hasImage ? onClear : null,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _loanDateField() {
    return TextFormField(
      controller: _loanDate,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Loan Date *',
        suffixIcon: IconButton(
          tooltip: 'Select loan date',
          onPressed: _pickLoanDate,
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
      validator: (value) =>
          _parseLoanDate(value ?? '') == null ? 'Required' : null,
    );
  }

  DateTime? _parseLoanDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse('${trimmed}T00:00:00.000Z');
    if (parsed == null) return null;
    return parsed;
  }

  String _mimeTypeForImage(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mortgage'),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: KeyboardAwareScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Customer Details'),
                _responsiveFields([
                  _field(_customerName, 'Customer Name *', required: true),
                  _field(_customerPhone, 'Mobile Number'),
                  _field(_customerAddress, 'Address'),
                  _field(_aadhaar, 'Aadhaar Number'),
                  _field(_pan, 'PAN Number'),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'Customer Verification'),
                _responsiveFields([
                  _verificationImageField(
                    label: 'Photo ID',
                    value: _photoIdUrl,
                    onChoose: () => _chooseVerificationImage('photoId'),
                    onClear: () => _clearVerificationImage('photoId'),
                  ),
                  _verificationImageField(
                    label: 'Customer Photo',
                    value: _customerPhotoUrl,
                    onChoose: () => _chooseVerificationImage('customerPhoto'),
                    onClear: () => _clearVerificationImage('customerPhoto'),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'Gold Details'),
                _responsiveFields([
                  _field(_ornamentType, 'Ornament Type *', required: true),
                  DropdownButtonFormField<String>(
                    initialValue: _purity,
                    decoration: const InputDecoration(labelText: 'Purity'),
                    items: const ['18K', '22K', '24K', 'Silver 925']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _purity = value ?? '22K'),
                  ),
                  _field(
                    _grossWeight,
                    'Gross Weight *',
                    required: true,
                    numeric: true,
                  ),
                  _field(
                    _netWeight,
                    'Net Weight *',
                    required: true,
                    numeric: true,
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'Loan Details'),
                _responsiveFields([
                  _field(
                    _loanAmount,
                    'Loan Amount *',
                    required: true,
                    numeric: true,
                  ),
                  _field(
                    _interestRate,
                    'Monthly Interest Rate % *',
                    required: true,
                    numeric: true,
                  ),
                  _loanDateField(),
                  _field(_notes, 'Notes'),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        GoldButton(label: 'Save Loan', isLoading: _isSaving, onPressed: _save),
      ],
    );
  }
}

class _CollectPaymentDialog extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> loan;

  const _CollectPaymentDialog({required this.api, required this.loan});

  @override
  State<_CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<_CollectPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  bool _isSaving = false;
  String _paymentType = 'interest';
  String _paymentMode = 'cash';

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.api.dio.post(
        '/mortgages/${widget.loan['id']}/payments',
        data: {
          'amount': _number(_amount.text),
          'paymentType': _paymentType,
          'paymentMode': _paymentMode,
          'paymentDate': DateTime.now().toIso8601String(),
          'referenceNumber': _emptyToNull(_reference.text),
          'notes': _emptyToNull(_notes.text),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, _errorMessage(error, 'Failed to save payment'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Collect Payment'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: KeyboardAwareScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_amount, 'Amount *', required: true, numeric: true),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _paymentType,
                  decoration: const InputDecoration(labelText: 'Payment Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'interest',
                      child: Text('Interest'),
                    ),
                    DropdownMenuItem(
                      value: 'principal',
                      child: Text('Principal'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _paymentType = value ?? 'interest'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _paymentMode = value ?? 'cash'),
                ),
                const SizedBox(height: AppSpacing.md),
                _field(_reference, 'Reference Number'),
                const SizedBox(height: AppSpacing.md),
                _field(_notes, 'Notes'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        GoldButton(
          label: 'Save Payment',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _CloseLoanDialog extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> loan;

  const _CloseLoanDialog({required this.api, required this.loan});

  @override
  State<_CloseLoanDialog> createState() => _CloseLoanDialogState();
}

class _CloseLoanDialogState extends State<_CloseLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _notes = TextEditingController();
  bool _isSaving = false;
  String _paymentMode = 'cash';

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: (widget.loan['totalPayableAmount'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.api.dio.post(
        '/mortgages/${widget.loan['id']}/close',
        data: {
          'amountPaid': _number(_amount.text),
          'paymentMode': _paymentMode,
          'closureDate': DateTime.now().toIso8601String(),
          'notes': _emptyToNull(_notes.text),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, _errorMessage(error, 'Failed to close loan'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Loan'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: KeyboardAwareScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  _amount,
                  'Settlement Amount *',
                  required: true,
                  numeric: true,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _paymentMode = value ?? 'cash'),
                ),
                const SizedBox(height: AppSpacing.md),
                _field(_notes, 'Notes'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        GoldButton(label: 'Close Loan', isLoading: _isSaving, onPressed: _save),
      ],
    );
  }
}

Widget _sectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

Widget _responsiveFields(List<Widget> children) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 640
          ? (constraints.maxWidth - AppSpacing.md) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool numeric = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Required';
      if (numeric && text.isNotEmpty && _number(text) <= 0) {
        return 'Enter a valid amount';
      }
      return null;
    },
  );
}

double _number(String value) {
  return double.tryParse(value.trim()) ?? 0;
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _errorMessage(Object error, String fallback) {
  if (error is DioException && error.message?.isNotEmpty == true) {
    return error.message!;
  }
  return fallback;
}
