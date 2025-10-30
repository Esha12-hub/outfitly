import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'dashboard_screen.dart';
import 'user_profile_details_screen.dart';
import 'feedback_support_screen.dart';
import '../screens/admin_login_screen.dart';
import 'package:untitled2/smart_shopping_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_version_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Wardrobe & Notification Toggles
  bool seasonBasedFiltering = false;
  bool occasionTags = true;
  bool outfitSuggestions = false;
  bool shoppingRecommendations = true;
  bool appLock = true;

  // Admin App Settings Toggles
  bool darkMode = false;
  bool pushNotifications = true;
  bool twoFA = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        await _handleLogout();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                child: Row(
                  children: [
                    // Back / Logout
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Image.asset(
                        "assets/images/white_back_btn.png",
                        height: screenHeight * 0.04,
                        width: screenHeight * 0.04,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.whiteHeading.copyWith(
                            fontSize: screenHeight * 0.03,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenHeight * 0.04),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Section
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UserProfileDetailsScreen()),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(screenHeight * 0.02),
                            decoration: BoxDecoration(
                                color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: screenHeight * 0.03,
                                  backgroundColor: Colors.blue[400],
                                  child: Icon(Icons.person,
                                      color: AppColors.textWhite, size: screenHeight * 0.03),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Google Account, Apple ID & Account Details',
                                        style: TextStyle(
                                            fontSize: screenHeight * 0.016,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    color: AppColors.textSecondary, size: screenHeight * 0.02),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // ADMIN MANAGEMENT
                        _buildSectionTitle('ADMIN MANAGEMENT', screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        _buildSettingItem('Shopping Management', Icons.category, screenHeight,
                            onTap: () {
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (context) => const SmartShoppingScreen()));
                            }),
                        SizedBox(height: screenHeight * 0.03),

                        // USER MANAGEMENT
                        _buildSectionTitle('USER MANAGEMENT', screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        _buildSettingItem('Users Feedback', Icons.people, screenHeight, onTap: () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => const FeedbackSupportScreen()));
                        }),
                        SizedBox(height: screenHeight * 0.02),

                        // APP SETTINGS
                        _buildSectionTitle('APP SETTINGS', screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        _buildToggleItem('Push Notifications', Icons.notifications,
                            pushNotifications, screenHeight, (value) {
                              setState(() {
                                pushNotifications = value;
                              });
                            }),
                        SizedBox(height: screenHeight * 0.03),

                        // BACKUP & MAINTENANCE
                        _buildSectionTitle('BACKUP & MAINTENANCE', screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        _buildSettingItem('App Version Info', Icons.info, screenHeight,onTap: () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => const AppVersionScreen()));
                        }),
                        SizedBox(height: screenHeight * 0.03),

                        // Centered Logout Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _handleLogout,
                            icon: Icon(Icons.logout, color: Colors.white, size: screenHeight * 0.025),
                            label: Text(
                              'Logout',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenHeight * 0.022,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.12, vertical: screenHeight * 0.018),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  Widget _buildSectionTitle(String title, double screenHeight) {
    return Text(title,
        style: TextStyle(
            fontSize: screenHeight * 0.018,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.2));
  }

  Widget _buildSettingItem(String title, IconData icon, double screenHeight,
      {VoidCallback? onTap, bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenHeight * 0.018),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: screenHeight * 0.022),
                if (showBadge)
                  const Positioned(
                      right: 0, top: 0, child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary)),
              ],
            ),
            SizedBox(width: screenHeight * 0.018),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87))),
            Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, IconData icon, bool value, double screenHeight,
      ValueChanged<bool> onChanged) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenHeight * 0.018),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: screenHeight * 0.022),
          SizedBox(width: screenHeight * 0.018),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
            inactiveThumbColor: AppColors.textWhite,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
