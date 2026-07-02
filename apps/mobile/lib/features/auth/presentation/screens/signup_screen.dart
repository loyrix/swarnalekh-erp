import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/auth_controller.dart';
import 'package:swarnbook/features/auth/data/auth_repository.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/brand_mark.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            RegisterRequest(
              shopName: _shopNameController.text.trim(),
              ownerName: _ownerNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        AppToast.error(context, message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.isDark(context)
                    ? [
                        const Color(0xFF0D0D12),
                        const Color(0xFF141420),
                        const Color(0xFF1A1530),
                      ]
                    : [
                        const Color(0xFFF7F6F3),
                        const Color(0xFFF0EDE5),
                        const Color(0xFFE8E2D3),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          KeyboardAwareScrollView(
            centerContent: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surf(context),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: AppColors.isDark(context)
                            ? AppColors.glassBorder
                            : AppColors.glassBorderLight,
                      ),
                      boxShadow: AppShadows.forElevated(context),
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: BrandMark(size: 68, padding: 6),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.signupTitle,
                              style: Theme.of(context).textTheme.displaySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.signupSubtitle,
                              style: TextStyle(
                                color: AppColors.text3(context),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildLabel(l10n.registrationShopName),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _shopNameController,
                              decoration: InputDecoration(
                                hintText: l10n.registrationShopName,
                                prefixIcon: Icon(
                                  Icons.storefront_outlined,
                                  color: AppColors.text3(context),
                                  size: 20,
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.organizationName,
                              ],
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.validationShopNameRequired
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLabel(l10n.registrationOwnerName),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _ownerNameController,
                              decoration: InputDecoration(
                                hintText: l10n.registrationOwnerName,
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.text3(context),
                                  size: 20,
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.validationOwnerNameRequired
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLabel(l10n.authEmailAddress),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'you@example.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppColors.text3(context),
                                  size: 20,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              enableSuggestions: false,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (v) => v!.isEmpty || !v.contains('@')
                                  ? l10n.validationValidEmail
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLabel(l10n.authPassword),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.text3(context),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.text3(context),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (v) => v!.length < 6
                                  ? l10n.validationPasswordMin
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLabel(l10n.authConfirmPassword),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.text3(context),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.text3(context),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _signup(),
                              validator: (v) => v != _passwordController.text
                                  ? l10n.validationPasswordsNoMatch
                                  : null,
                            ),
                            const SizedBox(
                              height: AppSpacing.lg + AppSpacing.sm,
                            ),
                            GoldButton(
                              label: l10n.authCreateAccount,
                              icon: Icons.person_add_rounded,
                              isLoading: _isLoading,
                              onPressed: _signup,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: '${l10n.authAlreadyHaveAccount} ',
                                  style: TextStyle(
                                    color: AppColors.text3(context),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: l10n.authSignIn,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: AppColors.success.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.authSecureConnection,
                                  style: TextStyle(
                                    color: AppColors.text3(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.text2(context),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    );
  }
}
