import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedDateRange = 'Last 7 Days';
  String selectedUserRole = 'All Users';
  String selectedPlatform = 'All Platforms';

  List<Offset> chartPoints = [];
  List<String> xLabels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'https://analytics-api-ansr-n97kfb7n6-analytics-api.vercel.app/api/getAnalytics'
            '?dateRange=${Uri.encodeComponent(selectedDateRange)}'
            '&userRole=${Uri.encodeComponent(selectedUserRole)}'
            '&platform=${Uri.encodeComponent(selectedPlatform)}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rows = data['rows'] as List<dynamic>;

        List<int> values = [];
        List<String> dates = [];

        for (var row in rows) {
          String date = row['dimensionValues'][0]['value']; // e.g., "20250808"
          String formattedDate =
              "${date.substring(6, 8)}/${date.substring(4, 6)}"; // DD/MM
          int activeUsers = int.tryParse(row['metricValues'][0]['value']) ?? 0;

          dates.add(formattedDate);
          values.add(activeUsers);
        }

        final maxValRaw =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
        final minValRaw =
        values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);

        bool allSame = maxValRaw == minValRaw;
        final maxVal = allSame ? maxValRaw + 1 : maxValRaw;

        List<Offset> points = [];
        for (int i = 0; i < values.length; i++) {
          double dx = values.length > 1 ? i / (values.length - 1) : 0;
          double dy = 1 - (values[i] / maxVal);

          // Add slight variation if all values are the same
          if (allSame) {
            double fakeVariation = (i % 2 == 0 ? 0.02 : -0.02);
            dy = (0.5 + fakeVariation).clamp(0.0, 1.0);
          }

          points.add(Offset(dx, dy));
        }

        setState(() {
          chartPoints = points;
          xLabels = dates;
          isLoading = false;
        });
      } else {
        throw Exception(
          "Failed to fetch analytics. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricCards(),
                      const SizedBox(height: 24),
                      _buildFilters(),
                      const SizedBox(height: 24),
                      _buildChartSection(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          ),
          const Expanded(
            child: Text(
              'Monitor App Analytics',
              textAlign: TextAlign.center,
              style: AppTextStyles.whiteHeading,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            '1,2k',
            'Active Users',
            Icons.trending_up,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '500+',
            'New Signups',
            Icons.person_add,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '3m 20s',
            'Session Duration',
            Icons.timer,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            'Date Range',
            selectedDateRange,
            ['Last 7 Days', 'Last 30 Days', 'Last 3 Months'],
                (value) {
              setState(() => selectedDateRange = value);
              fetchAnalytics();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterDropdown(
            'User Role',
            selectedUserRole,
            ['All Users', 'Regular Users', 'Content Writers', 'Admins'],
                (value) {
              setState(() => selectedUserRole = value);
              fetchAnalytics();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterDropdown(
            'Platform',
            selectedPlatform,
            ['All Platforms', 'iOS', 'Android', 'Web'],
                (value) {
              setState(() => selectedPlatform = value);
              fetchAnalytics();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Activity Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: LineChartPainter(chartPoints, xLabels),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
      String label,
      String value,
      List<String> options,
      Function(String) onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

// -----------------------
// Chart Painter
// -----------------------
class LineChartPainter extends CustomPainter {
  final List<Offset> points;
  final List<String> xLabels;

  LineChartPainter(this.points, this.xLabels);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Scale points
    List<Offset> scaledPoints =
    points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    // Draw lines
    for (int i = 0; i < scaledPoints.length - 1; i++) {
      canvas.drawLine(scaledPoints[i], scaledPoints[i + 1], paint);
    }

    // Draw dots
    for (final point in scaledPoints) {
      canvas.drawCircle(point, 4, dotPaint);
    }

    // Draw X-axis labels
    final textStyle = TextStyle(fontSize: 10, color: Colors.grey[600]);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < xLabels.length; i++) {
      textPainter.text = TextSpan(text: xLabels[i], style: textStyle);
      textPainter.layout();
      final dx = scaledPoints[i].dx - (textPainter.width / 2);
      final dy = size.height + 5;
      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.xLabels != xLabels;
  }
}
