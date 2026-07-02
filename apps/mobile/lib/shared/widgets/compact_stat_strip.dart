import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

class CompactStatStrip extends StatelessWidget {
  final List<({IconData icon, String label, String value, Color color})> stats;

  const CompactStatStrip({super.key, required this.stats});

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
          children: stats.map((stat) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfL(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: stat.color.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: stat.color.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
            );
          }).toList(),
        );
      },
    );
  }
}
