import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/notification_card.dart';
import 'dashboard_screen.dart';
import '../../controllers/navigation_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int selectedFilterIndex = 0;

  final List<String> filterTabs = [
    'All',
    'Promotional',
    'System Updates',
    'User Messages',
    'AI Insights',
    'Errors / Alerts',
  ];

  void _onFilterTapped(int index) {
    setState(() {
      selectedFilterIndex = index;
    });
  }

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
                    onPressed: () async {
                      final controller = Get.find<NavigationController>();
                      await controller.changeIndex(0); // Reset to Home
                      Get.offAll(() => const DashboardScreen());
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  // Placeholder to balance the layout
                  const SizedBox(width: 48), // Same width as IconButton
                ],
              ),
            ),

            // Filter Tabs
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterTabs.asMap().entries.map((entry) {
                    int index = entry.key;
                    String label = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < filterTabs.length - 1 ? 8 : 0,
                      ),
                      child: _buildFilterTab(
                        label,
                        selectedFilterIndex == index,
                        () => _onFilterTapped(index),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                child: Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            selectedFilterIndex == 4 ? 'AI Insights' : 'All Notifications',
                            style: AppTextStyles.h3,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // Clear all notifications
                            },
                            child: const Text(
                              'Clear all',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notifications List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Text(
                            selectedFilterIndex == 4 ? 'AI Insights' : filterTabs[selectedFilterIndex],
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: 12),
                          _buildNotificationsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.textWhite.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textWhite : AppColors.textWhite,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    switch (selectedFilterIndex) {
      case 0: // All
        return Column(
          children: [
            _buildNotificationSection('Today', [
              NotificationCard(
                title: 'Update Deployed',
                description: 'App v1.8 deployed successfully with performance upgrades.',
                time: '2 hours ago',
                icon: Icons.system_update,
              ),
              const SizedBox(height: 8),
              NotificationCard(
                title: 'Feedback Received',
                description: 'User @sofia_22 left feedback: \'AI didn\'t recognize winter wear.\'',
                time: '3 hours ago',
                icon: Icons.feedback,
              ),
              const SizedBox(height: 8),
              NotificationCard(
                title: 'Content Flagged',
                description: 'Post by user @lily_style reported for inappropriate outfit tags.',
                time: '3 hours ago',
                icon: Icons.flag,
              ),
            ]),
            const SizedBox(height: 16),
            _buildNotificationSection('Yesterday', [
              NotificationCard(
                title: 'Moderation Alert',
                description: '2 user posts flagged - require admin review.',
                time: '1 day ago',
                icon: Icons.warning,
              ),
            ]),
          ],
        );
      case 1: // Promotional
        return Column(
          children: [
            NotificationCard(
              title: 'New Collection Alert',
              description: 'Spring collection is now available! Check out the latest trends.',
              time: '1 hour ago',
              icon: Icons.shopping_bag,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'Special Offer',
              description: '50% off on premium AI styling features this week.',
              time: '3 hours ago',
              icon: Icons.local_offer,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'Feature Launch',
              description: 'Virtual Try-On 2.0 is now available for all users!',
              time: '2 hours ago',
              icon: Icons.celebration,
            ),
          ],
        );
      case 2: // System Updates
        return Column(
          children: [
            NotificationCard(
              title: 'Update Deployed',
              description: 'App v1.8 deployed successfully with performance upgrades.',
              time: '2 hours ago',
              icon: Icons.system_update,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'Maintenance Complete',
              description: 'Scheduled maintenance completed successfully.',
              time: '5 hours ago',
              icon: Icons.build,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'Database Backup',
              description: 'Daily backup completed successfully.',
              time: '1 day ago',
              icon: Icons.backup,
            ),
          ],
        );
      case 3: // User Messages
        return Column(
          children: [
            NotificationCard(
              title: 'Feedback Received',
              description: 'User @sofia_22 left feedback: \'AI didn\'t recognize winter wear.\'',
              time: '3 hours ago',
              icon: Icons.feedback,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'Support Request',
              description: 'User @john_doe requested help with account settings.',
              time: '4 hours ago',
              icon: Icons.support_agent,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'User Registration',
              description: 'New user @emma_wilson joined the platform.',
              time: '6 hours ago',
              icon: Icons.person_add,
            ),
          ],
        );
      case 4: // AI Insights
        return Column(
          children: [
            _buildNotificationSection('Today', [
              NotificationCard(
                title: 'Usage Spike',
                description: 'Virtual Try-On used by 78% of users today.',
                time: '2 hours ago',
                icon: Icons.trending_up,
              ),
            ]),
            const SizedBox(height: 16),
            _buildNotificationSection('Yesterday', [
              NotificationCard(
                title: 'Query Failure',
                description: 'AI model failed to respond to 3 unique user queries.',
                time: '1 day ago',
                icon: Icons.error_outline,
              ),
            ]),
          ],
        );
      case 5: // Errors / Alerts
        return Column(
          children: [
            NotificationCard(
              title: 'Content Flagged',
              description: 'Post by user @lily_style reported for inappropriate outfit tags.',
              time: '3 hours ago',
              icon: Icons.flag,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'Moderation Alert',
              description: '2 user posts flagged - require admin review.',
              time: '1 day ago',
              icon: Icons.warning,
            ),
            const SizedBox(height: 8),
            NotificationCard(
              title: 'System Error',
              description: 'Image processing service temporarily unavailable.',
              time: '2 days ago',
              icon: Icons.error,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNotificationSection(String title, List<Widget> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),
        ...notifications,
      ],
    );
  }
} 