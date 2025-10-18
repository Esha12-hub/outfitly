import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UserEngagementAnalyticsScreen extends StatelessWidget {
  const UserEngagementAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "User Engagement Analytics",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),


            // White container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: 'Today',
                            items: ['Today', 'This Week', 'This Month']
                                .map((e) => DropdownMenuItem(
                                value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) {},
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.8, // Adjusted to fix overflow
                        children: const [
                          MetricCard(
                              icon: Icons.people,
                              label: "Total Active Users",
                              value: "1,200"),
                          MetricCard(
                              icon: Icons.bar_chart,
                              label: "Daily Session",
                              value: "3,000"),
                          MetricCard(
                              icon: Icons.timer,
                              label: "Avg. Session Dur.",
                              value: "5m"),
                          MetricCard(
                              icon: Icons.trending_down,
                              label: "Bounce Rate",
                              value: "20%"),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Daily Active Users",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 200, child: DailyUsersLineChart()),

                      const SizedBox(height: 16),
                      const Text(
                        "Most Interacted Screens",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(
                          height: 200, child: MostInteractedBarChart()),

                      const SizedBox(height: 24),

                      // Download Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Download Report",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 12),
          Flexible( // Added to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class DailyUsersLineChart extends StatelessWidget {
  const DailyUsersLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) {
                const labels = [
                  'Apr1',
                  'Apr2',
                  'Apr3',
                  'Apr4',
                  'Apr5',
                  'Apr6',
                  'Apr7'
                ];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(labels[value.toInt()],
                      style: const TextStyle(fontSize: 10));
                } else {
                  return const Text('');
                }
              },
              interval: 1,
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 1),
              FlSpot(1, 3),
              FlSpot(2, 6),
              FlSpot(3, 3),
              FlSpot(4, 2),
              FlSpot(5, 7),
              FlSpot(6, 6),
            ],
            isCurved: false,
            barWidth: 2,
            color: Colors.pink,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class MostInteractedBarChart extends StatelessWidget {
  const MostInteractedBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                const labels = ['Home', 'Wardrobe', 'Suggestion', 'Try-on'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(labels[value.toInt()],
                      style: const TextStyle(fontSize: 10));
                } else {
                  return const Text('');
                }
              },
              interval: 1,
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(
              x: 0,
              barRods: [BarChartRodData(toY: 1, color: Colors.pink, width: 16)]),
          BarChartGroupData(
              x: 1,
              barRods: [BarChartRodData(toY: 5, color: Colors.pink, width: 16)]),
          BarChartGroupData(
              x: 2,
              barRods: [BarChartRodData(toY: 7, color: Colors.pink, width: 16)]),
          BarChartGroupData(
              x: 3,
              barRods: [BarChartRodData(toY: 4, color: Colors.pink, width: 16)]),
        ],
      ),
    );
  }
}