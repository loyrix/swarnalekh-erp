import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/brand_mark.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

/// First screen an unauthenticated visitor sees.
///
/// Splits the two audiences before either sees a form: a jeweller opening a
/// new shop account, and everyone signing in to one that already exists —
/// owner, manager or counter staff alike, since they all authenticate the same
/// way and differ only by the role on their user record.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _animController,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );

  @override
  void initState() {
    super.initState();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: KeyboardAwareScrollView(
              centerContent: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandMark(size: 84, padding: 7)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.welcomeBrandName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ornamentRule(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.welcomeTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.text2(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _choice(
                          icon: Icons.storefront_rounded,
                          title: l10n.welcomeRegisterTitle,
                          subtitle: l10n.welcomeRegisterSubtitle,
                          primary: true,
                          onTap: () => context.go('/signup'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _choice(
                          icon: Icons.login_rounded,
                          title: l10n.welcomeSignInTitle,
                          subtitle: l10n.welcomeSignInSubtitle,
                          primary: false,
                          onTap: () => context.go('/login'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _staffNote(l10n),
                        const SizedBox(height: AppSpacing.lg),
                        _secureFootnote(l10n),
                      ],
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

  /// One of the two paths. The primary card carries the gold fill; the second
  /// is outlined, so the choice is legible at a glance without either option
  /// looking disabled.
  Widget _choice({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final accent = primary ? AppColors.textOnPrimary : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primaryDark],
                  )
                : null,
            color: primary ? null : AppColors.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: primary
                  ? Colors.transparent
                  : AppColors.primary.withValues(alpha: 0.35),
            ),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary
                      ? AppColors.textOnPrimary.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 21, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primary
                            ? AppColors.textOnPrimary
                            : AppColors.text1(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: primary
                            ? AppColors.textOnPrimary.withValues(alpha: 0.78)
                            : AppColors.text3(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  /// Staff don't self-register — their accounts are created by the shop owner.
  /// Saying so here saves them signing up and creating an orphan tenant.
  Widget _staffNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.welcomeStaffNote,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.text3(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secureFootnote(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          size: 14,
          color: AppColors.success,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.welcomeSecureNote,
            style: TextStyle(fontSize: 11.5, color: AppColors.text3(context)),
          ),
        ),
      ],
    );
  }

  Widget _ornamentRule() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 46,
          child: Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Transform.rotate(
            angle: 0.785398, // 45° — a square on its corner reads as a diamond.
            child: Container(width: 5, height: 5, color: AppColors.primary),
          ),
        ),
        SizedBox(
          width: 46,
          child: Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  /// Same gradient the login and signup screens use, so the three read as one
  /// continuous entry flow rather than three unrelated pages.
  Widget _background() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDark(context)
              ? [
                  const Color(0xFF0A0A0C),
                  const Color(0xFF131316),
                  const Color(0xFF1B1913),
                ]
              : [
                  const Color(0xFFF6F6F7),
                  const Color(0xFFF2F1EE),
                  const Color(0xFFECE7DC),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
