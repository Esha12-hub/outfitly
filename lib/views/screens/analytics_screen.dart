import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'admin_login_screen.dart';
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

  // Real metrics
  int dailyActiveUsers = 0; // Latest day's value
  int totalNewSignups = 0;
  String sessionDuration = '0m 0s';

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  // ✅ Logout confirmation dialog
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            child: const Text("No", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              (route) => false,
        );
      }
    }
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
        final rows = data['rows'] as List<dynamic>? ?? [];

        List<int> values = [];
        List<String> dates = [];
        int latestActiveUsers = 0;

        for (int i = 0; i < rows.length; i++) {
          try {
            final date = rows[i]['dimensionValues']?[0]?['value'] ?? '';
            final formattedDate = date.isNotEmpty && date.length == 8
                ? "${date.substring(6, 8)}/${date.substring(4, 6)}"
                : date;

            final metricValue = rows[i]['metricValues']?[0]?['value'] ?? '0';
            final activeUsers = int.tryParse(metricValue) ?? 0;

            if (i == rows.length - 1) {
              latestActiveUsers = activeUsers;
            }

            dates.add(formattedDate);
            values.add(activeUsers);
          } catch (e) {
            debugPrint("Error parsing row: ${rows[i]}, error: $e");
          }
        }

        final maxValRaw = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
        final minValRaw = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
        final allSame = maxValRaw == minValRaw;
        final maxVal = allSame ? maxValRaw + 1 : maxValRaw;

        List<Offset> points = [];
        for (int i = 0; i < values.length; i++) {
          double dx = values.length > 1 ? i / (values.length - 1) : 0;
          double dy = 1 - (values[i] / maxVal);
          if (allSame) {
            double fakeVariation = (i % 2 == 0 ? 0.02 : -0.02);
            dy = (0.5 + fakeVariation).clamp(0.0, 1.0);
          }
          points.add(Offset(dx, dy));
        }

        setState(() {
          chartPoints = points;
          xLabels = dates;
          dailyActiveUsers = latestActiveUsers; // Latest day's active users
          totalNewSignups = 0;
          sessionDuration = '0m 0s';
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, width),
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
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricCards(width, height),
                      SizedBox(height: height * 0.03),
                      _buildFilters(width),
                      SizedBox(height: height * 0.03),
                      _buildChartSection(context, width, height),
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

  Widget _buildHeader(BuildContext context, double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleLogout, // ✅ Added logout dialog trigger
            icon: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
          ),
          Expanded(
            child: Text(
              'Monitor App Analytics',
              textAlign: TextAlign.center,
              style: AppTextStyles.whiteHeading.copyWith(fontSize: width * 0.05),
            ),
          ),
          SizedBox(width: width * 0.12),
        ],
      ),
    );
  }

  Widget _buildMetricCards(double width, double height) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            dailyActiveUsers.toString(),
            'Active Users',
            Icons.trending_up,
            AppColors.primary,
            width,
            height,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildMetricCard(
            totalNewSignups.toString(),
            'New Signups',
            Icons.person_add,
            AppColors.success,
            width,
            height,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildMetricCard(
            sessionDuration,
            'Session Duration',
            Icons.timer,
            AppColors.info,
            width,
            height,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String value,
      String label,
      IconData icon,
      Color color,
      double width,
      double height,
      ) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.03),
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
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: width * 0.02),
              Icon(icon, color: color, size: width * 0.05),
            ],
          ),
          SizedBox(height: height * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: width * 0.035,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(double width) {
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
            width,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildFilterDropdown(
            'User Role',
            selectedUserRole,
            ['All Users', 'Regular Users', 'Content Writers', 'Admins'],
                (value) {
              setState(() => selectedUserRole = value);
              fetchAnalytics();
            },
            width,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildFilterDropdown(
            'Platform',
            selectedPlatform,
            ['All Platforms', 'iOS', 'Android', 'Web'],
                (value) {
              setState(() => selectedPlatform = value);
              fetchAnalytics();
            },
            width,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
      String label,
      String value,
      List<String> options,
      Function(String) onChanged,
      double width,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.02),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: width * 0.04),
          style: TextStyle(
            fontSize: width * 0.035,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: width * 0.032),
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

  Widget _buildChartSection(BuildContext context, double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.03),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Activity Trend',
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: height * 0.02),
          SizedBox(
            height: height * 0.25,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomPaint(
              size: Size(width, height * 0.25),
              painter: LineChartPainter(chartPoints, xLabels),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------
// Chart Painter with Y-axis labels
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
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
    }

    // Draw Y-axis labels
    final textStyle = TextStyle(fontSize: 10, color: Colors.grey[600]);
    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    int maxVal = (points.map((p) => ((1 - p.dy) * 4).round()).reduce((a, b) => a > b ? a : b));
    for (int i = 0; i <= 4; i++) {
      textPainter.text = TextSpan(text: ((maxVal * i / 4).round()).toString(), style: textStyle);
      textPainter.layout();
      final dy = size.height - (size.height * i / 4) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(0, dy));
    }

    // Scale points
    List<Offset> scaledPoints =
    points.map((p) => Offset(30 + p.dx * (size.width - 30), p.dy * size.height)).toList();

    // Draw lines
    for (int i = 0; i < scaledPoints.length - 1; i++) {
      canvas.drawLine(scaledPoints[i], scaledPoints[i + 1], paint);
    }

    // Draw dots
    for (final point in scaledPoints) {
      canvas.drawCircle(point, 4, dotPaint);
    }

    // Draw X-axis labels
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
