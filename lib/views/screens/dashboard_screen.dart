import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/metric_card.dart';
import '../widgets/pending_approval_card.dart';
import '../widgets/ai_usage_chart.dart';
import 'active_users_screen.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';
import '../screens/content_approval_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin_login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _DashboardHomeContent(),
    const ContentApprovalScreen(),
    const AnalyticsScreen(),
    const ActiveUsersScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }


  Future<bool> _onWillPop() async {
    // ✅ Styled logout confirmation dialog
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
      // If you use FirebaseAuth for admin, sign out
      // await FirebaseAuth.instance.signOut();

      // Navigate to AdminLoginScreen and remove all previous routes
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
      return false; // Prevent default back behavior
    }

    return false; // Stay on dashboard if No
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 👈 Handles back press
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(child: _pages[_selectedIndex]),
        bottomNavigationBar: CurvedNavigationBar(
          key: GlobalKey<CurvedNavigationBarState>(),
          index: _selectedIndex,
          height: 60.0,
          items: const <Widget>[
            Icon(Icons.dashboard, size: 30, color: Colors.white),
            Icon(Icons.analytics_outlined, size: 30, color: Colors.white),
            Icon(Icons.area_chart, size: 30, color: Colors.white),
            Icon(Icons.person, size: 30, color: Colors.white),
            Icon(Icons.settings, size: 30, color: Colors.white),
          ],
          color: AppColors.primary,
          buttonBackgroundColor: AppColors.primary.withOpacity(0.9),
          backgroundColor: Colors.black, // ✅ solid black nav background
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 400),
          onTap: _onItemTapped,
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}

class _DashboardHomeContent extends StatefulWidget {
  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent> {
  Future<int> _getWardrobeItemCountForUsersWithRoleUser() async {
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'User')
        .get();

    int totalItems = 0;
    for (var userDoc in usersSnap.docs) {
      final wardrobeSnap = await userDoc.reference.collection('wardrobe').get();
      totalItems += wardrobeSnap.docs.length;
    }
    return totalItems;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserProfileScreen(
                        name: 'Admin User',
                        email: 'admin@aiwardrobe.com',
                        role: 'Administrator',
                        status: 'Active',
                        avatarColor: AppColors.primary,
                        avatarIcon: Icons.admin_panel_settings,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.admin_panel_settings,
                      color: AppColors.textWhite, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Dashboard', style: AppTextStyles.whiteHeading),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
                icon: const Icon(Icons.notifications,
                    color: AppColors.textWhite, size: 24),
              ),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      // Users count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const MetricCard(
                              title: 'Users',
                              value: 'Loading...',
                              icon: Icons.people,
                              color: AppColors.primary,
                            );
                          }
                          final filteredUsers = snapshot.data!.docs.where((doc) {
                            final role =
                            (doc.data() as Map<String, dynamic>)['role'];
                            return role != null &&
                                role.toString().toLowerCase() == 'user';
                          }).toList();

                          return MetricCard(
                            title: 'Users',
                            value: filteredUsers.length.toString(),
                            icon: Icons.people,
                            color: AppColors.primary,
                          );
                        },
                      ),

                      // Wardrobe items count
                      FutureBuilder<int>(
                        future: _getWardrobeItemCountForUsersWithRoleUser(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const MetricCard(
                              title: 'Items',
                              value: 'Loading...',
                              icon: Icons.checkroom,
                              color: AppColors.info,
                            );
                          }

                          return MetricCard(
                            title: 'Items',
                            value: snapshot.data.toString(),
                            icon: Icons.checkroom,
                            color: AppColors.info,
                          );
                        },
                      ),

                      const MetricCard(
                          title: 'Active Today',
                          value: '1,046',
                          icon: Icons.trending_up,
                          color: AppColors.success),
                      const MetricCard(
                          title: 'AI Accuracy',
                          value: '98.5%',
                          icon: Icons.psychology,
                          color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Pending Approvals', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  const PendingApprovalCard(),
                  const SizedBox(height: 24),
                  const Text('AI Usage Breakdown', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  const AiUsageChart(),
                  const SizedBox(height: 24),
                  const Text('Recent Activity', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _buildRecentActivityItem(
                      'Added new outfit', '2h ago', Icons.add),
                  const SizedBox(height: 8),
                  _buildRecentActivityItem(
                      'Updated Profile', '5h ago', Icons.edit),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityItem(String title, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
