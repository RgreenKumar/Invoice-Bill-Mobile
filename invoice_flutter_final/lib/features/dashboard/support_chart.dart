import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Port of `src/AuthenticationPages/SupportChart.js` (ApexCharts sparkline
/// "area" chart) using fl_chart's LineChart with an area fill, matching
/// the original's smooth curve + `#4680ff` color + no axis/grid
/// ("sparkline: { enabled: true }").
class SupportChart extends StatelessWidget {
  const SupportChart({super.key, required this.data});

  final List<num> data;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].toDouble()),
    ];

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                isCurved: true,
                color: const Color(0xFF4680FF),
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF4680FF).withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
