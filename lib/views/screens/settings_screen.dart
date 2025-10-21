// ✅ IMPORTS
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
import 'package:untitled2/smart_shopping_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_approval_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Search...', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
                            MaterialPageRoute(builder: (context) => const UserProfileDetailsScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue[400],
                                child: const Icon(Icons.person, color: AppColors.textWhite, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'User Name',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Google Account, Apple ID & Wardrobe Details',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ===========================
                      // ACCOUNT SETTINGS
                      // ===========================
                      _buildSectionTitle('ACCOUNT SETTINGS'),
                      const SizedBox(height: 16),
                      _buildSettingItem('Verify Email/Phone Number', Icons.mail, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const VerifyEmailPhoneScreen()));
                      }),
                      const SizedBox(height: 8),
                      _buildSettingItem('Change Password', Icons.key, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                      }),
                      const SizedBox(height: 8),
                      _buildSettingItem('Delete Profile', Icons.person_remove, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DeleteProfileScreen()));
                      }),
                      const SizedBox(height: 32),

                      // ===========================
                      // ADMIN MANAGEMENT
                      // ===========================
                      _buildSectionTitle('ADMIN MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildSettingItem('Shopping Management', Icons.category, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartShoppingScreen()));
                      }),
                      const SizedBox(height: 32),

                      // ===========================
                      // USER MANAGEMENT
                      // ===========================
                      _buildSectionTitle('USER MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildSettingItem('View All Users', Icons.people, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartShoppingScreen()));
                      }),
                      const SizedBox(height: 16),

                      // ===========================
                      // APP SETTINGS
                      // ===========================
                      _buildSectionTitle('APP SETTINGS'),
                      const SizedBox(height: 16),
                      _buildToggleItem('Push Notifications', Icons.notifications, pushNotifications, (value) {
                        setState(() {
                          pushNotifications = value;
                        });
                      }),
                      const SizedBox(height: 32),

                      // ===========================
                      // CONTENT MANAGEMENT
                      // ===========================
                      _buildSectionTitle('CONTENT MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildSettingItem('Analytics Access', Icons.analytics),
                      const SizedBox(height: 32),

                      // BACKUP & MAINTENANCE
                      // ===========================
                      _buildSectionTitle('BACKUP & MAINTENANCE'),
                      const SizedBox(height: 16),
                      _buildSettingItem('App Version Info', Icons.info),
                      const SizedBox(height: 32),


                      // ===========================
                      // PRIVACY AND SECURITY
                      // ===========================
                      _buildSectionTitle('PRIVACY AND SECURITY'),
                      const SizedBox(height: 16),

                      _buildSettingItem('Manage Permissions', Icons.shield, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePermissionsScreen()));
                      }, showBadge: true),
                      const SizedBox(height: 32),

                      // Centered Logout Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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
        title: const Text('Logout', style: TextStyle(color: Colors.black87)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.primary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                    (route) => false,
              );
            },
            style: TextButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2));
  }

  Widget _buildSettingItem(String title, IconData icon, {VoidCallback? onTap, bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 20),
                if (showBadge)
                  const Positioned(right: 0, top: 0, child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
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
