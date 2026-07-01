import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

Widget mortgageSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Widget mortgageField(
  BuildContext context,
  TextEditingController controller,
  String label, {
  bool required = false,
  bool numeric = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  return TextFormField(
    controller: controller,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return l10n.mortgageRequired;
      if (numeric && text.isNotEmpty && mortgageNumber(text) <= 0) {
        return l10n.mortgageEnterValidAmount;
      }
      return null;
    },
  );
}

double mortgageNumber(String value) => double.tryParse(value.trim()) ?? 0;

String? mortgageEmptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String mortgageErrorMessage(Object error, String fallback) {
  if (error is DioException && error.message?.isNotEmpty == true) {
    return error.message!;
  }
  return fallback;
}
