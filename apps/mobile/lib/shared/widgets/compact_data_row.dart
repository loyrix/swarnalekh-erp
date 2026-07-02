import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';

/// The canonical compact list row for every SwarnaLekh screen.
///
/// Stage V visual language ("trailing value + accent"): the **first** metric is
/// pulled to the right as a bold, glanceable figure (with a small caption);
/// remaining metrics render inline under the subtitle; a thin status-colored
/// accent bar runs down the left edge. The accent is taken from [accentColor]
/// when given, otherwise auto-derived from a [StatusBadge] passed as [trailing]
/// — so every existing call site gains the accent with no changes.
///
/// The API is unchanged from before, so screens compose it exactly as they did.
class CompactDataRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// `(label, value)` pairs. The first pair is rendered as the emphasized
  /// trailing figure; any others render inline beneath the subtitle.
  final List<(String, String)> metrics;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Optional explicit accent color for the left edge. When null, a [trailing]
  /// [StatusBadge]'s color is used; when that is absent too, no accent shows.
  final Color? accentColor;

  const CompactDataRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    this.trailing,
    this.onTap,
    this.accentColor,
  });

  /// A short symbol label (e.g. `₹`, `$`) reads better fused onto its value
  /// than stacked as a caption underneath it.
  static bool _isSymbolLabel(String label) =>
      label.trim().length <= 2 && !RegExp(r'[A-Za-z]').hasMatch(label);

  @override
  Widget build(BuildContext context) {
    final Color? accent =
        accentColor ??
        (trailing is StatusBadge
            ? (trailing! as StatusBadge).effectiveColor
            : null);

    final (String, String)? primary = metrics.isNotEmpty ? metrics.first : null;
    final List<(String, String)> secondary = metrics.length > 1
        ? metrics.sublist(1)
        : const [];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surf(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.brd(context).withValues(alpha: 0.5),
              ),
              boxShadow: AppShadows.soft(context),
            ),
            child: Stack(
              children: [
                Padding(
                  // Extra left inset when an accent bar is present.
                  padding: EdgeInsets.fromLTRB(
                    accent != null ? 15 : 12,
                    10,
                    12,
                    10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: leading!,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: _mainColumn(context, secondary)),
                      if (primary != null || trailing != null) ...[
                        const SizedBox(width: 8),
                        _trailingBlock(context, primary),
                      ],
                    ],
                  ),
                ),
                // Left status accent — full height via top/bottom anchoring.
                if (accent != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: accent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainColumn(BuildContext context, List<(String, String)> secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            height: 1.15,
            color: AppColors.text1(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 11, color: AppColors.text3(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 2,
            children: secondary.map((m) => _inlineMetric(context, m)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _inlineMetric(BuildContext context, (String, String) m) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 11, color: AppColors.text3(context)),
        children: [
          TextSpan(text: '${m.$1} '),
          TextSpan(
            text: m.$2,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text2(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trailingBlock(BuildContext context, (String, String)? primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (primary != null) _primaryFigure(context, primary),
        if (primary != null && trailing != null) const SizedBox(height: 4),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _primaryFigure(BuildContext context, (String, String) m) {
    final symbol = _isSymbolLabel(m.$1);
    if (symbol) {
      return Text(
        '${m.$1}${m.$2}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: AppColors.text1(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.$2,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            height: 1.1,
            color: AppColors.text1(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          m.$1,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: AppColors.text3(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
