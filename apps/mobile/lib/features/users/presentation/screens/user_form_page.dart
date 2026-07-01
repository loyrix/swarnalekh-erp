import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';
import 'package:swarnbook/features/users/data/users_repository.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen Add/Edit team-member form. Returns `true` when saved.
class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key, this.user});

  final ManagedUser? user;

  static Future<bool?> open(BuildContext context, {ManagedUser? user}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => UserFormPage(user: user),
    );
  }

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UsersRepository();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _isSaving = false;
  bool _isActive = true;
  String _role = 'staff';

  bool get _isEditing => widget.user != null;
  bool get _isOwner => widget.user?.isOwner == true;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user != null) {
      _name.text = user.name;
      _email.text = user.email ?? '';
      _phone.text = user.phone ?? '';
      _role = user.isOwner ? 'staff' : user.role;
      _isActive = user.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = managedUserPayload(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      role: _role,
      isActive: _isEditing && !_isOwner ? _isActive : null,
    );
    if (_isOwner) payload.remove('role');

    try {
      await _repo.save(payload, id: widget.user?.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        AppLocalizations.of(context)!.errorFailedSaveUser,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: _isEditing ? l10n.userEditTitle : l10n.userAddTitle,
        isSaving: _isSaving,
        onSave: _save,
        children: [
          TextFormField(
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.userFieldName,
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().length < 2
                ? l10n.validationUserName
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.userFieldEmail,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty || !email.contains('@')) {
                return l10n.validationUserEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.userFieldPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isOwner)
            TextFormField(
              initialValue: 'Owner',
              enabled: false,
              decoration: InputDecoration(
                labelText: l10n.userFieldRole,
                border: const OutlineInputBorder(),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(
                labelText: l10n.userFieldRole,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'staff',
                  child: Text(l10n.userRoleStaff),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text(l10n.userRoleAdmin),
                ),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'staff'),
            ),
          if (_isEditing && !_isOwner) ...[
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.commonActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ],
      ),
    );
  }
}
