import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

class CompactStatStrip extends StatelessWidget {
  final List<({IconData icon, String label, String value, Color color})> stats;

  /// Optional per-tile tap handlers, index-aligned with [stats]. A null entry
  /// (or omitting the list) keeps that tile static.
  final List<VoidCallback?>? onTaps;

  const CompactStatStrip({super.key, required this.stats, this.onTaps});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final spacing = 12.0;
        final runSpacing = 12.0;
        // Floor to avoid floating point precision layout overflows
        final itemWidth =
            ((constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                    crossAxisCount)
                .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: stats.asMap().entries.map((entry) {
            final stat = entry.value;
            final onTap = onTaps != null && entry.key < onTaps!.length
                ? onTaps![entry.key]
                : null;
            return SizedBox(
              width: itemWidth,
              child: _wrapTap(
                onTap,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    // Uniform card: one neutral surface + hairline border + soft
                    // lift for every stat. The only colour is the small icon tile.
                    color: AppColors.surf(context),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.brd(context).withValues(alpha: 0.6),
                    ),
                    boxShadow: AppShadows.soft(context),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: stat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(stat.icon, size: 16, color: stat.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stat.value,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.1,
                                color: AppColors.text1(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              stat.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.text3(context),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static Widget _wrapTap(VoidCallback? onTap, Widget child) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
