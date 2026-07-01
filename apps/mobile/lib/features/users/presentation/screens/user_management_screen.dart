import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';
import 'package:swarnbook/features/users/application/users_providers.dart';
import 'package:swarnbook/features/users/presentation/screens/user_form_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _api = ApiClient();
  final _searchController = TextEditingController();
  String _search = '';
  bool _roleLoaded = false;
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
      if (!mounted) return;
      setState(() {
        _canManage = isAdminRole(role);
        _roleLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _roleLoaded = true);
    }
  }

  Future<void> _openForm({ManagedUser? user}) async {
    final changed = await UserFormPage.open(context, user: user);
    if (changed == true && mounted) ref.invalidate(usersProvider);
  }

  Future<void> _deactivate(ManagedUser user) async {
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
      await ref.read(usersRepositoryProvider).deactivate(user.id);
      if (!mounted) return;
      AppToast.success(context, l10n.userDeactivated);
      ref.invalidate(usersProvider);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.errorFailedDeactivateUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_roleLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_canManage) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l10n.userRestrictedTitle,
        subtitle: l10n.userRestrictedSubtitle,
        iconColor: AppColors.warning,
      );
    }

    final async = ref.watch(usersProvider);
    return AppStateView<List<ManagedUser>>(
      value: async,
      onRetry: () => ref.invalidate(usersProvider),
      data: (users) {
        final filtered = _search.isEmpty
            ? users
            : users.where((u) => _matches(u, _search)).toList();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(usersProvider.future),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _OnboardingTip(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: l10n.userSearchHint,
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
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: l10n.userAddUser,
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.userNoResults,
                          style: TextStyle(color: AppColors.text3(context)),
                        ),
                      )
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

  bool _matches(ManagedUser u, String query) {
    final q = query.toLowerCase();
    return u.name.toLowerCase().contains(q) ||
        (u.email ?? '').toLowerCase().contains(q) ||
        (u.phone ?? '').toLowerCase().contains(q);
  }

  String _titleCase(String value) {
    final text = value.trim();
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  Widget _row(AppLocalizations l10n, ManagedUser user) {
    return CompactDataRow(
      leading: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: user.name,
      subtitle: user.email ?? user.phone ?? l10n.userNoContactInfo,
      metrics: [
        (l10n.userFieldRole, _titleCase(user.role)),
        (
          l10n.commonActive,
          user.isActive ? l10n.userStatusActive : l10n.userStatusInactive,
        ),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(
            label: user.authLinked
                ? l10n.userStatusLoginLinked
                : l10n.userStatusPendingLogin,
            color: user.authLinked ? AppColors.info : AppColors.warning,
          ),
          ItemActionsMenu(
            actions: [
              ItemAction(
                type: ItemActionType.edit,
                customLabel: l10n.userEditTooltip,
                onPressed: () => _openForm(user: user),
              ),
              if (!user.isOwner && user.isActive)
                ItemAction(
                  type: ItemActionType.delete,
                  customLabel: l10n.userDeactivateAction,
                  onPressed: () => _deactivate(user),
                  isDestructive: true,
                ),
            ],
          ),
        ],
      ),
      onTap: () => _openForm(user: user),
    );
  }
}

class _OnboardingTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}
