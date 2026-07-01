import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/customers/data/customers_repository.dart';
import 'package:swarnbook/features/customers/data/models/customer.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen Add/Edit customer form. Returns `true` when saved.
class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key, this.customer});

  final Customer? customer;

  static Future<bool?> open(BuildContext context, {Customer? customer}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => CustomerFormPage(customer: customer),
    );
  }

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CustomersRepository();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _city;
  late final TextEditingController _preferredKarat;
  late final TextEditingController _notes;
  bool _isSaving = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _city = TextEditingController(text: c?.city ?? '');
    _preferredKarat = TextEditingController(text: c?.preferredKarat ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _preferredKarat.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? nn(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final payload = {
      'name': _name.text.trim(),
      'phone': nn(_phone),
      'email': nn(_email),
      'city': nn(_city),
      'preferredKarat': nn(_preferredKarat),
      'notes': nn(_notes),
    };

    try {
      await _repo.save(payload, id: widget.customer?.id);
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
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: _isEdit ? l10n.commonEdit : l10n.customerAdd,
        isSaving: _isSaving,
        saveLabel: _isEdit ? l10n.commonUpdate : l10n.commonCreate,
        onSave: _save,
        children: [
          _field(
            _name,
            l10n.customerNameLabel,
            requiredMessage: l10n.validationCustomerNameRequired,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(_phone, l10n.customerPhoneLabel),
          const SizedBox(height: AppSpacing.md),
          _field(_email, l10n.customerEmailLabel),
          const SizedBox(height: AppSpacing.md),
          _field(_city, l10n.customerCityLabel),
          const SizedBox(height: AppSpacing.md),
          _field(_preferredKarat, l10n.customerPreferredKaratLabel),
          const SizedBox(height: AppSpacing.md),
          _field(_notes, l10n.commonNotes, maxLines: 3),
        ],
      ),
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
