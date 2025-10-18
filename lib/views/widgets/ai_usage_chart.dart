import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class AiUsageChart extends StatelessWidget {
  const AiUsageChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Usage Breakdown',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: PieChartPainter(),
                    child: const Center(
                      child: Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildLegendItem('AI Outfit Recommendations', 38, AppColors.primary),
                    const SizedBox(height: 8),
                    _buildLegendItem('Virtual Try-On', 22, AppColors.warning),
                    const SizedBox(height: 8),
                    _buildLegendItem('Fashion Assistant Chat', 18, AppColors.error),
                    const SizedBox(height: 8),
                    _buildLegendItem('Smart Shopping Tips', 10, AppColors.secondary),
                    const SizedBox(height: 8),
                    _buildLegendItem('Color Palette Advisor', 5, AppColors.info),
                    const SizedBox(height: 8),
                    _buildLegendItem('Seasonal Outfit Ideas', 4, AppColors.success),
                    const SizedBox(height: 8),
                    _buildLegendItem('Laundry & Usage Tracker', 2, AppColors.cardBorder),
                    const SizedBox(height: 8),
                    _buildLegendItem('Other', 1, AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$percentage%',
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    
    // Data for pie chart
    final data = [
      {'percentage': 38, 'color': AppColors.primary},
      {'percentage': 22, 'color': AppColors.warning},
      {'percentage': 18, 'color': AppColors.error},
      {'percentage': 10, 'color': AppColors.secondary},
      {'percentage': 5, 'color': AppColors.info},
      {'percentage': 4, 'color': AppColors.success},
      {'percentage': 2, 'color': AppColors.cardBorder},
      {'percentage': 1, 'color': AppColors.textSecondary},
    ];
    
    double startAngle = -math.pi / 2; // Start from top
    
    for (final item in data) {
      final percentage = item['percentage'] as int;
      final color = item['color'] as Color;
      final sweepAngle = (percentage / 100) * 2 * math.pi;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.cardBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, borderPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 