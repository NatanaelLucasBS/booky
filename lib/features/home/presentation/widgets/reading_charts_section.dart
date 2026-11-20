import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/use_cases/get_dashboard_stats_use_case.dart';
import '../viewmodels/home_viewmodel.dart';

// Seção do gráfico de leitura mensal
class ReadingChartsSection extends StatelessWidget {
  final List<MonthlyReadingStat> stats;
  final ChartMetric selectedMetric;
  final ValueChanged<ChartMetric> onMetricChanged;

  const ReadingChartsSection({
    super.key,
    required this.stats,
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final values = stats.map((s) => selectedMetric == ChartMetric.pages ? s.pagesRead : s.booksFinished).toList();
    final maxValue = values.fold<int>(0, max);
    final maxY = maxValue > 0 ? (maxValue * 1.25).ceilToDouble() : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown : AppColors.lightCream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.mediumBrown : AppColors.beige,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'HISTÓRICO MENSAL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Seletor de métrica do gráfico
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBrown : AppColors.beige.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.mediumBrown : AppColors.beige,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ChartMetric.values.map((metric) {
                    final isSelected = metric == selectedMetric;
                    return InkWell(
                      onTap: () => onMetricChanged(metric),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.lightCream : AppColors.darkBrown)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          metric == ChartMetric.pages ? 'PÁGINAS' : 'LIVROS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isSelected
                                ? (isDark ? AppColors.darkBrown : AppColors.lightCream)
                                : (isDark ? AppColors.beige : AppColors.mediumBrown),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico fl_chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? AppColors.darkBrown : AppColors.darkBrown,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = stats[groupIndex];
                      final unit = selectedMetric == ChartMetric.pages ? 'págs' : 'livros';
                      return BarTooltipItem(
                        '${item.label}\n${rod.toY.toInt()} $unit',
                        const TextStyle(
                          color: AppColors.lightCream,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? AppColors.beige : AppColors.mediumBrown,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= stats.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            stats[index].label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.mediumBrown.withValues(alpha: 0.3) : AppColors.beige.withValues(alpha: 0.5),
                    strokeWidth: 1.0,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(stats.length, (index) {
                  final stat = stats[index];
                  final val = selectedMetric == ChartMetric.pages
                      ? stat.pagesRead.toDouble()
                      : stat.booksFinished.toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        color: isDark ? AppColors.lightCream : AppColors.woodBrown,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: isDark ? AppColors.darkBrown : AppColors.beige.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
