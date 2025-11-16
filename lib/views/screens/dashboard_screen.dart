import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/metric_card.dart';
import 'active_users_screen.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';
import '../screens/content_approval_screen.dart';
import '../screens/analytics_screen.dart';
import '../../smart_shopping_screen.dart';
import '../screens/admin_login_screen.dart';
import 'admin_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavKey = GlobalKey();

  final List<Widget> _pages = [
    _DashboardHomeContent(),
    const ContentApprovalScreen(),
    const AnalyticsScreen(),
    const ActiveUsersScreen(),
    const SmartShoppingScreen(),
    const AdminSettingsScreen(),
  ];

  Future<bool> _onWillPop() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            child: const Text(
              "No",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context, true);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminLoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );

    return shouldLogout ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(child: _pages[_selectedIndex]),
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavKey,
          index: _selectedIndex,
          height: 60.0,
          items: const <Widget>[
            Icon(Icons.dashboard, size: 30, color: Colors.white),
            Icon(Icons.analytics_outlined, size: 30, color: Colors.white),
            Icon(Icons.area_chart, size: 30, color: Colors.white),
            Icon(Icons.person, size: 30, color: Colors.white),
            Icon(Icons.shopping_bag, size: 30, color: Colors.white),
            Icon(Icons.settings, size: 30, color: Colors.white),
          ],
          color: Colors.pink,
          buttonBackgroundColor: Colors.pinkAccent,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
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
  Future<int> _getWardrobeItemCount() async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    int totalItems = 0;
    for (var userDoc in usersSnap.docs) {
      final data = userDoc.data() as Map<String, dynamic>;
      final role = data['role']?.toString().toLowerCase();
      final email = data['email']?.toString().toLowerCase() ?? '';

      if (role == 'user' || email.endsWith('@outfitly.com') || role == 'User') {
        final wardrobeSnap = await userDoc.reference.collection('wardrobe').get();
        totalItems += wardrobeSnap.docs.length;
      }
    }
    return totalItems;
  }

  Future<int> _getPendingItemsCount() async {
    int totalPending = 0;
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnap.docs) {
      final articlesSnap = await userDoc.reference
          .collection('articles')
          .where('status', isEqualTo: 'pending')
          .get();
      totalPending += articlesSnap.docs.length;
    }

    return totalPending;
  }

  Future<int> _getFeedbackCount() async {
    int totalFeedback = 0;
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnap.docs) {
      final feedbackSnap = await userDoc.reference.collection('feedback').get();
      totalFeedback += feedbackSnap.docs.length;
    }

    return totalFeedback;
  }

  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    List<Map<String, dynamic>> activities = [];
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 15));

    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnap.docs) {
      final userId = userDoc.id;
      final userName = (userDoc.data()['name'] ?? 'Unknown');

      final articlesSnap = await FirebaseFirestore.instance
          .collection('users/$userId/articles')
          .orderBy('timestamp', descending: true)
          .get();

      for (var articleDoc in articlesSnap.docs) {
        final articleData = articleDoc.data();
        final articleTimestamp = (articleData['timestamp'] as Timestamp).toDate();

        if (articleTimestamp.isBefore(cutoffDate)) continue;

        activities.add({
          'type': 'article',
          'title': articleData['title'] ?? '',
          'userName': userName,
          'time': articleData['timestamp'] ?? Timestamp.now(),
        });

        final commentsSnap = await FirebaseFirestore.instance
            .collection('users/$userId/articles/${articleDoc.id}/comments')
            .orderBy('timestamp', descending: true)
            .get();

        for (var commentDoc in commentsSnap.docs) {
          final commentData = commentDoc.data();
          final commentTimestamp = (commentData['timestamp'] as Timestamp).toDate();
          if (commentTimestamp.isBefore(cutoffDate)) continue;

          activities.add({
            'type': 'comment',
            'title': commentData['content'] ?? '',
            'userName': userName,
            'time': commentData['timestamp'] ?? Timestamp.now(),
          });
        }
      }
    }

    activities.sort((a, b) =>
        (b['time'] as Timestamp).compareTo(a['time'] as Timestamp));

    return activities.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                        uid: '',
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

              FutureBuilder<int>(
                future: _getPendingItemsCount(),
                builder: (context, pendingSnap) {
                  return FutureBuilder<int>(
                    future: _getFeedbackCount(),
                    builder: (context, feedbackSnap) {
                      bool hasNotifications = false;
                      if (pendingSnap.hasData && feedbackSnap.hasData) {
                        hasNotifications =
                            pendingSnap.data! > 0 || feedbackSnap.data! > 0;
                      }

                      return Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );

                            },
                            icon: const Icon(Icons.notifications,
                                color: AppColors.textWhite, size: 24),
                          ),
                          if (hasNotifications)
                            Positioned(
                              right: 12,
                              top: 10,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

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
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
                            final data = doc.data() as Map<String, dynamic>;
                            final role = (data['role'] ?? '').toString().toLowerCase();
                            final email = (data['email'] ?? '').toString().toLowerCase();

                            return role == 'user' ||
                                role == 'content writer' ||
                                email.endsWith('@outfitly.com');
                          }).toList();

                          return MetricCard(
                            title: 'Users',
                            value: filteredUsers.length.toString(),
                            icon: Icons.people,
                            color: AppColors.primary,
                          );
                        },
                      ),

                      FutureBuilder<int>(
                        future: _getWardrobeItemCount(),
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
                      FutureBuilder<int>(
                        future: _getFeedbackCount(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const MetricCard(
                              title: 'Feedback',
                              value: 'Loading...',
                              icon: Icons.feedback,
                              color: AppColors.success,
                            );
                          }

                          return MetricCard(
                            title: 'Feedback',
                            value: snapshot.data.toString(),
                            icon: Icons.feedback,
                            color: AppColors.success,
                          );
                        },
                      ),
                      FutureBuilder<int>(
                        future: _getPendingItemsCount(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const MetricCard(
                              title: 'Pending Approvals',
                              value: 'Loading...',
                              icon: Icons.pending_actions,
                              color: AppColors.warning,
                            );
                          }

                          return MetricCard(
                            title: 'Pending Approvals',
                            value: snapshot.data.toString(),
                            icon: Icons.pending_actions,
                            color: AppColors.warning,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Recent Activity', style: AppTextStyles.h3),
                  const SizedBox(height: 12),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchRecentActivity(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final activities = snapshot.data!;
                      if (activities.isEmpty) {
                        return const Text(
                          'No recent activity',
                          style: AppTextStyles.bodyMedium,
                        );
                      }

                      return Column(
                        children: activities.map((activity) {
                          IconData icon;
                          if (activity['type'] == 'article') {
                            icon = Icons.article;
                          } else if (activity['type'] == 'comment') {
                            icon = Icons.comment;
                          } else {
                            icon = Icons.info;
                          }

                          final timeAgo = _timeAgoSinceDate(
                              (activity['time'] as Timestamp).toDate());

                          return _buildRecentActivityItem(
                              '${activity['userName']} ${activity['type'] == 'comment' ? 'commented' : 'submitted'}: ${activity['title']}',
                              timeAgo,
                              icon);
                        }).toList(),
                      );
                    },
                  ),
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
      margin: const EdgeInsets.symmetric(vertical: 4),
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

  String _timeAgoSinceDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
