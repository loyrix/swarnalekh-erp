import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/auth_controller.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/brand_mark.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());
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
          _buildBackground(),
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
                            _buildLogo(),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.loginWelcomeBack,
                              style: Theme.of(context).textTheme.displaySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.loginSubtitle,
                              style: TextStyle(
                                color: AppColors.text3(context),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
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
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _login(),
                              validator: (v) => v!.length < 6
                                  ? l10n.validationPasswordMin
                                  : null,
                            ),
                            const SizedBox(
                              height: AppSpacing.lg + AppSpacing.sm,
                            ),
                            GoldButton(
                              label: l10n.authSignIn,
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              onPressed: _login,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: AppColors.div(context)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    l10n.authOr,
                                    style: TextStyle(
                                      color: AppColors.text3(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: AppColors.div(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: '${l10n.authDontHaveAccount} ',
                                  style: TextStyle(
                                    color: AppColors.text3(context),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: l10n.authSignUp,
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
                            _buildTrustBadge(),
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

  Widget _buildBackground() {
    return Container(
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
    );
  }

  Widget _buildLogo() {
    return const Center(child: BrandMark(size: 68, padding: 6));
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

  Widget _buildTrustBadge() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 14,
          color: AppColors.success.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.authSecureConnection,
          style: TextStyle(color: AppColors.text3(context), fontSize: 11),
        ),
      ],
    );
  }
}
