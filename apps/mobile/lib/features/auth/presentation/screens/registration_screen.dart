import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/data/auth_provider.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).registerTenant({
        'shopName': _shopNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'city': _cityController.text.trim(),
      });
      // Registration successful! Now the user is attached to a tenant.
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        AppToast.error(
          context,
          '${AppLocalizations.of(context)!.registrationFailedPrefix} $message',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.registrationSetupShop),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: KeyboardAwareScrollView(
        centerContent: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.elev(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brd(context)),
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.registrationAlmostThere,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.registrationSubtitle,
                      style: TextStyle(color: AppColors.text3(context)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _shopNameController,
                      decoration: InputDecoration(
                        labelText: l10n.registrationShopName,
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.organizationName],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (v) => v!.isEmpty
                          ? '${l10n.registrationShopName} is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: InputDecoration(
                        labelText: l10n.registrationOwnerName,
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (v) => v!.isEmpty
                          ? '${l10n.registrationOwnerName} is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: l10n.registrationCityOptional,
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.addressCity],
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GoldButton(
                      label: l10n.registrationCompleteSetup,
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
