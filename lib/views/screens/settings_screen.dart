import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'dashboard_screen.dart';
import 'verify_email_phone_screen.dart';
import 'change_password_screen.dart';
import 'delete_profile_screen.dart';
import 'user_profile_details_screen.dart';
import 'manage_permissions_screen.dart';
import 'ai_model_management_screen.dart';
import 'feedback_support_screen.dart';
import 'update_faq_screen.dart';
import 'category_management_screen.dart';
import '../screens/admin_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool seasonBasedFiltering = false;
  bool occasionTags = true;
  bool outfitSuggestions = false;
  bool shoppingRecommendations = true;
  bool appLock = true;

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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DashboardScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                      // User Profile Section
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const UserProfileDetailsScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue[400],
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.textWhite,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'User Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Google Account, Apple ID & Wardrobe Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Account Settings Section
                      _buildSectionTitle('ACCOUNT SETTINGS'),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        'Verify Email/Phone Number',
                        Icons.mail,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const VerifyEmailPhoneScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        'Change Password',
                        Icons.key,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const ChangePasswordScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        'Delete Profile',
                        Icons.person_remove,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const DeleteProfileScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Admin Management Section
                      _buildSectionTitle('ADMIN MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        'AI Model Management',
                        Icons.psychology,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const AiModelManagementScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        'Feedback & Support',
                        Icons.support_agent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const FeedbackSupportScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        'Update FAQ Section',
                        Icons.help_outline,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const UpdateFaqScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        'Category Management',
                        Icons.category,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const CategoryManagementScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Wardrobe Preferences Section
                      _buildSectionTitle('WARDROBE PREFERENCES'),
                      const SizedBox(height: 16),
                      _buildToggleItem(
                        'Season-Based Filtering',
                        Icons.wb_sunny,
                        seasonBasedFiltering,
                            (value) {
                          setState(() {
                            seasonBasedFiltering = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildToggleItem(
                        'Occasion Tags',
                        Icons.local_offer,
                        occasionTags,
                            (value) {
                          setState(() {
                            occasionTags = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Notifications Section
                      _buildSectionTitle('NOTIFICATIONS'),
                      const SizedBox(height: 16),
                      _buildToggleItem(
                        'Outfit Suggestions',
                        Icons.checkroom,
                        outfitSuggestions,
                            (value) {
                          setState(() {
                            outfitSuggestions = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildToggleItem(
                        'Shopping Recommendations',
                        Icons.shopping_bag,
                        shoppingRecommendations,
                            (value) {
                          setState(() {
                            shoppingRecommendations = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Privacy and Security Section
                      _buildSectionTitle('PRIVACY AND SECURITY'),
                      const SizedBox(height: 16),
                      _buildToggleItem(
                        'App Lock',
                        Icons.lock,
                        appLock,
                            (value) {
                          setState(() {
                            appLock = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        'Manage Permissions',
                        Icons.shield,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const ManagePermissionsScreen()),
                          );
                        },
                        showBadge: true,
                      ),
                      const SizedBox(height: 8),

                      // Logout Button
                      _buildSettingItem(
                        'Logout',
                        Icons.logout,
                        onTap: () {
                          _showLogoutDialog();
                        },
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.black87),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear stored user data

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                    (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon,
      {VoidCallback? onTap, bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color:
                  title == 'Logout' ? Colors.black : AppColors.textSecondary,
                  size: 20,
                ),
                if (showBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: title == 'Logout' ? Colors.black : Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
      String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
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
