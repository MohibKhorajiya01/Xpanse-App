import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xpanse/data/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class StockLineChart extends ConsumerWidget {
  final List<Map<String, double>> candleData;

  const StockLineChart({
    super.key,
    required this.candleData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(settingsServiceProvider).currencySymbol;
    if (candleData.isEmpty) {
      return Center(child: Text('No data yet', style: AppTypography.bodySmall));
    }

    final spots = List.generate(candleData.length, (i) {
      return FlSpot(i.toDouble(), candleData[i]['close']!);
    });

    final isProfit = candleData.last['close']! >= candleData.first['open']!;
    final mainColor = isProfit ? AppColors.income : AppColors.expense;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxY() / 4 > 0 ? _getMaxY() / 4 : 1000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.03),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final startDate = DateTime.now().subtract(const Duration(days: 6));
                int idx = startDate.add(Duration(days: value.toInt())).weekday - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(dayNames[idx][0], style: AppTypography.bodySmall.copyWith(fontSize: 10, color: Colors.white24)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.surfaceDark,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                return LineTooltipItem(
                  '$currencySymbol${s.y.toStringAsFixed(0)}',
                  AppTypography.bodyMedium.copyWith(color: mainColor, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: mainColor.withValues(alpha: 0.2), strokeWidth: 1),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3,
                    color: mainColor,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.backgroundDark,
                  ),
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: mainColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // No dots by default in Google style
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [mainColor.withValues(alpha: 0.1), mainColor.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  double _getMaxY() {
    if (candleData.isEmpty) return 1000;
    return candleData.map((e) => e['high']!).reduce((a, b) => a > b ? a : b);
  }
}




