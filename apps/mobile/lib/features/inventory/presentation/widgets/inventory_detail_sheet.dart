import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/features/inventory/presentation/inventory_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

/// Shows the canonical read-only product detail as an [AppDetailSheet].
Future<void> showInventoryDetail(BuildContext context, InventoryItem item) {
  final l10n = AppLocalizations.of(context)!;
  return AppDetailSheet.show(
    context,
    title: item.itemName ?? l10n.inventoryUnnamedItem,
    subtitle: inventoryDesignTag(item),
    leading: inventoryImagePreview(context, item.photo, size: 56),
    sections: [
      AppDetailSection(
        heading: l10n.inventoryProductInfo,
        rows: [
          AppDetailRow(l10n.inventoryProductName, item.itemName ?? '—'),
          AppDetailRow(l10n.inventoryProductCode, item.tagNumber ?? '—'),
          AppDetailRow(
            l10n.inventoryFieldDesignNumber,
            inventoryDesignTag(item),
          ),
          AppDetailRow(l10n.inventoryFieldCategory, item.categoryName ?? '—'),
          AppDetailRow(l10n.inventoryColumnPurity, inventoryPurityText(item)),
          AppDetailRow(l10n.inventoryFieldBranch, item.location ?? '—'),
        ],
      ),
      AppDetailSection(
        heading: l10n.inventoryWeightDetails,
        rows: [
          AppDetailRow(
            l10n.inventoryGrossWeight,
            inventoryOptionalWeight(item.grossWeight),
          ),
          AppDetailRow(
            l10n.inventoryStoneWeight,
            inventoryOptionalWeight(item.stoneWeight),
          ),
          AppDetailRow(
            l10n.inventoryCalcNetWeight,
            inventoryOptionalWeight(item.netWeight),
          ),
        ],
      ),
      AppDetailSection(
        heading: l10n.inventoryPriceDetails,
        rows: [
          AppDetailRow(
            l10n.inventoryPurchasePrice,
            inventoryPurchasePriceText(item),
          ),
          AppDetailRow(
            l10n.inventoryFieldSellingPrice,
            inventoryCurrencyText(item.estimatedSellingPrice),
            emphasize: true,
          ),
          AppDetailRow(
            l10n.inventoryMakingCharges,
            inventoryMakingText(l10n, item),
          ),
        ],
      ),
      AppDetailSection(
        heading: l10n.inventoryStatusInfo,
        rows: [
          AppDetailRow(
            l10n.inventoryFormStatus,
            inventoryStatusLabel(l10n, item.status),
          ),
          AppDetailRow(l10n.inventoryQuantity, '${item.quantity}'),
        ],
      ),
    ],
    extra: Center(child: inventoryImagePreview(context, item.photo, size: 160)),
  );
}

/// Status badge coloured by status, reused by list rows.
Color inventoryStatusColor(String status) => switch (status) {
  'sold' => AppColors.success,
  'reserved' => AppColors.warning,
  _ => AppColors.info,
};
