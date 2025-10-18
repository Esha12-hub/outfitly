import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class AiModelManagementScreen extends StatefulWidget {
  const AiModelManagementScreen({super.key});

  @override
  State<AiModelManagementScreen> createState() => _AiModelManagementScreenState();
}

class _AiModelManagementScreenState extends State<AiModelManagementScreen> {
  String selectedDataset = 'Outfit Database v2.0';
  String testInput = '';
  double aiRating = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'AI Model Management',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Content
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
                      // Model Version Card
                      _buildModelVersionCard(),
                      const SizedBox(height: 24),

                      // Train New Model Section
                      _buildTrainNewModelSection(),
                      const SizedBox(height: 24),

                      // Test AI Model Section
                      _buildTestAiModelSection(),
                      const SizedBox(height: 24),

                      // Train History Section
                      _buildTrainHistorySection(),
                      const SizedBox(height: 40),

                      // Bottom Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Clear All Logs',
                              AppColors.surface,
                              AppColors.primary,
                              () => _showClearLogsDialog(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Export Model Data',
                              AppColors.primary,
                              AppColors.textWhite,
                              () => _exportModelData(),
                            ),
                          ),
                        ],
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

  Widget _buildModelVersionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model Version 1.2',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'TRAINED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Trained: May 11, 2025',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainNewModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Train New Model',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDataset,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              items: [
                'Outfit Database v2.0',
                'User Preferences v1.5',
                'Style Analysis v1.0',
                'Trend Data v2.1',
              ].map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => selectedDataset = newValue);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _trainNewModel(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Train Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Training may take several minutes.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTestAiModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test AI Model',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => testInput = value),
          decoration: InputDecoration(
            labelText: 'Enter test input',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _testAiModel(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Test Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rate AI Response',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => setState(() => aiRating = index + 1.0),
              child: Icon(
                index < aiRating ? Icons.star : Icons.star_border,
                color: AppColors.primary,
                size: 24,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTrainHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Train History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'May 11, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Outfit DB v.2.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _refreshModel(),
                icon: const Icon(Icons.refresh, color: AppColors.primary),
              ),
              IconButton(
                onPressed: () => _runModel(),
                icon: const Icon(Icons.play_arrow, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color backgroundColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: backgroundColor == AppColors.surface
              ? BorderSide(color: AppColors.primary)
              : BorderSide.none,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _trainNewModel() {
    Get.snackbar(
      'Training Started',
      'Model training has been initiated. This may take several minutes.',
      backgroundColor: AppColors.primary,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _testAiModel() {
    if (testInput.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter test input first.',
        backgroundColor: Colors.red,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    Get.snackbar(
      'Test Completed',
      'AI model test completed successfully.',
      backgroundColor: AppColors.success,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _refreshModel() {
    Get.snackbar(
      'Model Refreshed',
      'Model has been refreshed successfully.',
      backgroundColor: AppColors.info,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _runModel() {
    Get.snackbar(
      'Model Running',
      'AI model is now running in the background.',
      backgroundColor: AppColors.primary,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showClearLogsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to clear all training logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Logs Cleared',
                'All training logs have been cleared successfully.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Clear', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _exportModelData() {
    Get.snackbar(
      'Export Started',
      'Model data export has been initiated. You will receive a notification when complete.',
      backgroundColor: AppColors.primary,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.TOP,
    );
  }
} 