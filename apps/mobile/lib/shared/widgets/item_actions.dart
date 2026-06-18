import 'package:flutter/material.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

enum ItemActionType {
  view,
  edit,
  delete,
  print,
  download,
  share,
  collect,
  close,
  receipt,
  payment,
}

class ItemAction {
  final ItemActionType type;
  final String? customLabel;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isDestructive;

  const ItemAction({
    required this.type,
    this.customLabel,
    this.onPressed,
    this.enabled = true,
    this.isDestructive = false,
  });

  String getLabel(AppLocalizations l10n) {
    if (customLabel != null) return customLabel!;
    switch (type) {
      case ItemActionType.view:
        return l10n.billingViewInvoiceDetails;
      case ItemActionType.edit:
        return l10n.commonEdit;
      case ItemActionType.delete:
        return l10n.commonDelete;
      case ItemActionType.print:
        return l10n.billingReprintInvoice;
      case ItemActionType.download:
        return l10n.billingDownloadPdf;
      case ItemActionType.share:
        return l10n.billingShareWhatsApp;
      case ItemActionType.collect:
        return l10n.mortgageCollect;
      case ItemActionType.close:
        return l10n.mortgageClose;
      case ItemActionType.receipt:
        return l10n.mortgageReceipt;
      case ItemActionType.payment:
        return l10n.mortgagePaymentType;
    }
  }

  IconData getIcon() {
    switch (type) {
      case ItemActionType.view:
        return Icons.visibility_outlined;
      case ItemActionType.edit:
        return Icons.edit_outlined;
      case ItemActionType.delete:
        return Icons.delete_outline_rounded;
      case ItemActionType.print:
        return Icons.print_outlined;
      case ItemActionType.download:
        return Icons.download_outlined;
      case ItemActionType.share:
        return Icons.share_outlined;
      case ItemActionType.collect:
        return Icons.payments_outlined;
      case ItemActionType.close:
        return Icons.task_alt_rounded;
      case ItemActionType.receipt:
        return Icons.receipt_long_outlined;
      case ItemActionType.payment:
        return Icons.payment_outlined;
    }
  }

  Color getColor(BuildContext context) {
    if (isDestructive) return AppColors.error;
    switch (type) {
      case ItemActionType.view:
        return AppColors.info;
      case ItemActionType.edit:
        return AppColors.primary;
      case ItemActionType.print:
        return AppColors.text2(context);
      case ItemActionType.download:
        return AppColors.text2(context);
      case ItemActionType.share:
        return AppColors.success;
      case ItemActionType.collect:
        return AppColors.success;
      case ItemActionType.close:
        return AppColors.warning;
      case ItemActionType.receipt:
        return AppColors.info;
      case ItemActionType.payment:
        return AppColors.primary;
      default:
        return AppColors.text2(context);
    }
  }
}

class ItemActionsMenu extends StatelessWidget {
  final List<ItemAction> actions;
  final bool compact;
  final IconData? menuIcon;

  const ItemActionsMenu({
    super.key,
    required this.actions,
    this.compact = false,
    this.menuIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledActions = actions.where((a) => a.enabled).toList();

    if (enabledActions.isEmpty) return const SizedBox.shrink();

    if (compact && enabledActions.length <= 3) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: enabledActions.map((action) {
          return _ActionButton(action: action, compact: true);
        }).toList(),
      );
    }

    return PopupMenuButton<ItemAction>(
      icon: Icon(
        menuIcon ?? Icons.more_vert_rounded,
        size: 18,
        color: AppColors.text3(context),
      ),
      color: AppColors.surfL(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.brd(context)),
      ),
      itemBuilder: (context) => enabledActions.map((action) {
        return PopupMenuItem<ItemAction>(
          value: action,
          enabled: action.enabled && action.onPressed != null,
          child: Row(
            children: [
              Icon(
                action.getIcon(),
                size: 18,
                color: action.enabled
                    ? action.getColor(context)
                    : AppColors.text3(context),
              ),
              const SizedBox(width: 10),
              Text(
                action.getLabel(l10n),
                style: TextStyle(
                  color: action.enabled
                      ? AppColors.text1(context)
                      : AppColors.text3(context),
                  fontWeight: action.isDestructive
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (action) {
        if (action.enabled && action.onPressed != null) {
          action.onPressed!();
        }
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ItemAction action;
  final bool compact;

  const _ActionButton({required this.action, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = action.getColor(context);

    return IconButton(
      icon: Icon(action.getIcon(), size: compact ? 18 : 20, color: color),
      onPressed: action.enabled && action.onPressed != null
          ? action.onPressed
          : null,
      tooltip: action.getLabel(l10n),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      constraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      padding: compact ? EdgeInsets.zero : null,
      color: action.enabled ? color : null,
      disabledColor: AppColors.text3(context),
    );
  }
}

class ItemActionsRow extends StatelessWidget {
  final List<ItemAction> actions;
  final MainAxisAlignment alignment;
  final double spacing;

  const ItemActionsRow({
    super.key,
    required this.actions,
    this.alignment = MainAxisAlignment.end,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final enabledActions = actions.where((a) => a.enabled).toList();

    if (enabledActions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: enabledActions.map((action) {
        return Padding(
          padding: EdgeInsets.only(left: spacing),
          child: _ActionButton(action: action, compact: false),
        );
      }).toList(),
    );
  }
}
