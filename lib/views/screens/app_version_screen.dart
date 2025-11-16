import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class AppVersionScreen extends StatelessWidget {
  const AppVersionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const String appName = "Smart Wardrobe Admin";
    const String version = "1.0.0";
    const String buildNumber = "42";
    const String lastUpdated = "2025-10-30";

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: screenHeight * 0.04,
                      width: screenHeight * 0.04,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'App Version',
                        style: AppTextStyles.whiteHeading.copyWith(
                          fontSize: screenHeight * 0.025,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenHeight * 0.04),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.05),
                      Container(
                        width: screenHeight * 0.12,
                        height: screenHeight * 0.12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo_app.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      Text(
                        appName,
                        style: TextStyle(
                          fontSize: screenHeight * 0.025,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      _buildInfoCard("Version", version, screenHeight),
                      SizedBox(height: screenHeight * 0.015),
                      _buildInfoCard("Build Number", buildNumber, screenHeight),
                      SizedBox(height: screenHeight * 0.015),
                      _buildInfoCard("Last Updated", lastUpdated, screenHeight),
                      SizedBox(height: screenHeight * 0.05),

                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("You are using the latest version")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.2, vertical: screenHeight * 0.018),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          "Check for Updates",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.022,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
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

  Widget _buildInfoCard(String label, String value, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015, horizontal: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: screenHeight * 0.018, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: screenHeight * 0.018, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
