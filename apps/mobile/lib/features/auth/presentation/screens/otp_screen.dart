import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

class OtpScreen extends StatelessWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.otpNotActiveTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.otpNotActiveMessage,
                style: TextStyle(color: AppColors.text3(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfL(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.brd(context)),
                ),
                child: Text(
                  phone.isEmpty
                      ? l10n.otpNoPhoneProvided
                      : l10n.otpLegacyPhone(phone),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text2(context)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  l10n.otpBackToLogin,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
