import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/inventory/application/inventory_image_payloads.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

String inventoryWeightText(double? value) {
  final weight = value ?? 0;
  if (weight >= 1000) return '${(weight / 1000).toStringAsFixed(2)} kg';
  return '${weight.toStringAsFixed(3)} g';
}

String inventoryCurrencyText(num? value) {
  if (value == null) return '—';
  return '₹$value';
}

String inventoryOptionalWeight(double? value) {
  if (value == null) return '—';
  return '$value g';
}

String inventoryPurityText(InventoryItem item) {
  if (item.karat != null) return item.karat!;
  if (item.purity != null) return '${item.purity}%';
  return '—';
}

String inventoryDesignTag(InventoryItem item) =>
    item.designNumber ?? item.tagNumber ?? '—';

String inventoryShortDate(String? value) {
  if (value == null || value.isEmpty) return '—';
  return value.split('T').first;
}

String inventoryReadableValue(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '—';
  return text
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String inventoryStatusLabel(AppLocalizations l10n, String? value) {
  return switch ((value ?? '').toString()) {
    'in_stock' => l10n.inventoryInStock,
    'sold' => l10n.inventorySold,
    'on_approval' => l10n.inventoryOnApproval,
    'reserved' => l10n.inventoryReserved,
    _ => '—',
  };
}

String inventoryMetalLabel(AppLocalizations l10n, String? value) {
  return switch ((value ?? '').toString()) {
    'gold' => l10n.inventoryMetalGold,
    'silver' => l10n.inventoryMetalSilver,
    'platinum' => l10n.inventoryMetalPlatinum,
    'other' => l10n.inventoryMetalOther,
    _ => '—',
  };
}

String inventoryMakingText(AppLocalizations l10n, InventoryItem item) {
  final prefix = l10n.inventoryMakingPrefix;
  if (item.makingChargesPerGram != null) {
    return '$prefix ₹${item.makingChargesPerGram}/g';
  }
  if (item.makingChargesFixed != null) {
    return '$prefix ₹${item.makingChargesFixed}';
  }
  if (item.makingChargesPercent != null) {
    return '$prefix ${item.makingChargesPercent}%';
  }
  return '$prefix —';
}

String inventoryPurchasePriceText(InventoryItem item) {
  final rate = item.purchaseRate;
  if (rate == null) return '—';
  final net = item.netWeight ?? 0;
  return inventoryCurrencyText(rate * net * item.quantity);
}

/// Square image preview for an inventory photo (data-URI or network URL).
Widget inventoryImagePreview(
  BuildContext context,
  String? imageSource, {
  required double size,
}) {
  final fallback = Container(
    width: size,
    height: size,
    color: AppColors.primary.withValues(alpha: 0.1),
    child: Icon(
      Icons.diamond_outlined,
      color: AppColors.primary,
      size: size > 80 ? 52 : 22,
    ),
  );

  Widget child = fallback;
  if (imageSource != null && imageSource.isNotEmpty) {
    if (isInventoryDataImage(imageSource)) {
      try {
        child = Image.memory(
          decodeInventoryDataImage(imageSource),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (_) {
        child = fallback;
      }
    } else {
      child = Image.network(
        imageSource,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(
      size > 80 ? AppRadius.md : AppRadius.sm,
    ),
    child: SizedBox(width: size, height: size, child: child),
  );
}
