import 'package:flutter/material.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _api = ApiClient();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _canManageUsers = false;
  List<ManagedUser> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadRoleAndUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoleAndUsers() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (!mounted) return;
      _canManageUsers = isAdminRole(role);
      if (!_canManageUsers) {
        setState(() => _isLoading = false);
        return;
      }
      await _loadUsers();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(
        context,
        AppLocalizations.of(context)!.errorFailedLoadUsers,
      );
    }
  }

  Future<void> _loadUsers() async {
    if (!_canManageUsers) return;
    try {
      final response = await _api.dio.get<List<dynamic>>(
        '/users',
        queryParameters: {
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _users = parseManagedUsers(response.data);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(
        context,
        AppLocalizations.of(context)!.errorFailedLoadUsers,
      );
    }
  }

  Future<void> _openUserDialog({ManagedUser? user}) async {
    final changed = await showResponsiveDialog<bool>(
      context: context,
      builder: (context) => _UserFormDialog(api: _api, user: user),
    );

    if (changed == true && mounted) {
      await _loadUsers();
    }
  }

  Future<void> _deactivateUser(ManagedUser user) async {
    if (user.isOwner) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.userDeactivateTitle),
        content: Text(l10n.userDeactivateConfirm(user.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.userDeactivateAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.dio.delete('/users/${user.id}');
      if (!mounted) return;
      AppToast.success(context, l10n.userDeactivated);
      await _loadUsers();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.errorFailedDeactivateUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canManageUsers) {
      final l10n = AppLocalizations.of(context)!;
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l10n.userRestrictedTitle,
        subtitle: l10n.userRestrictedSubtitle,
        iconColor: AppColors.warning,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: KeyboardAwareScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildOnboardingTip(),
            const SizedBox(height: AppSpacing.lg),
            _buildSearch(),
            const SizedBox(height: AppSpacing.lg),
            _buildUserList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pageUserManagement,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.userManagementSubtitle,
                style: TextStyle(color: AppColors.text3(context)),
              ),
            ],
          ),
        ),
        PrimaryActionButton.goldButton(
          label: l10n.userAddUser,
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => _openUserDialog(),
        ),
      ],
    );
  }

  Widget _buildOnboardingTip() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.userOnboardingTipTitle,
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.userOnboardingTipDesc,
                  style: TextStyle(
                    color: AppColors.text2(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: l10n.userSearchHint,
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.commonClearSearch,
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        onSubmitted: (_) => _loadUsers(),
      ),
    );
  }

  Widget _buildUserList() {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.userTeamHeader,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                l10n.userCount(_users.length),
                style: TextStyle(color: AppColors.text3(context)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                l10n.userNoResults,
                style: TextStyle(color: AppColors.text3(context)),
              ),
            )
          else
            ..._users.map(_buildUserRow),
        ],
      ),
    );
  }

  Widget _buildUserRow(ManagedUser user) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.div(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: AppColors.text1(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? user.phone ?? l10n.userNoContactInfo,
                  style: TextStyle(color: AppColors.text3(context)),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(label: _titleCase(user.role)),
                    StatusBadge(
                      label: user.isActive
                          ? l10n.userStatusActive
                          : l10n.userStatusInactive,
                      color: user.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    StatusBadge(
                      label: user.authLinked
                          ? l10n.userStatusLoginLinked
                          : l10n.userStatusPendingLogin,
                      color: user.authLinked
                          ? AppColors.info
                          : AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.userEditTooltip,
            onPressed: () => _openUserDialog(user: user),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: l10n.userDeactivateTooltip,
            onPressed: user.isOwner || !user.isActive
                ? null
                : () => _deactivateUser(user),
            icon: const Icon(Icons.person_off_rounded),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    final text = value.trim();
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
}

class _UserFormDialog extends StatefulWidget {
  final ApiClient api;
  final ManagedUser? user;

  const _UserFormDialog({required this.api, this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

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
      _nameController.text = user.name;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
      _role = user.isOwner ? 'staff' : user.role;
      _isActive = user.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = managedUserPayload(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      role: _role,
      isActive: _isEditing && !_isOwner ? _isActive : null,
    );
    if (_isOwner) {
      payload.remove('role');
    }

    try {
      if (_isEditing) {
        await widget.api.dio.put('/users/${widget.user!.id}', data: payload);
      } else {
        await widget.api.dio.post('/users', data: payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: Text(_isEditing ? l10n.userEditTitle : l10n.userAddTitle),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: KeyboardAwareScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.userFieldName),
                  validator: (value) => value == null || value.trim().length < 2
                      ? l10n.validationUserName
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.userFieldEmail),
                  keyboardType: TextInputType.emailAddress,
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
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: l10n.userFieldPhone),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isOwner)
                  TextFormField(
                    initialValue: 'Owner',
                    enabled: false,
                    decoration: InputDecoration(labelText: l10n.userFieldRole),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: InputDecoration(labelText: l10n.userFieldRole),
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
                    onChanged: (value) =>
                        setState(() => _role = value ?? 'staff'),
                  ),
                if (_isEditing && !_isOwner) ...[
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.commonActive),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
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
          label: l10n.commonSave,
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
