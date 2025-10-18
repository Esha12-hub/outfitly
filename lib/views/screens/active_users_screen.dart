import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_field.dart';
import 'blocked_users_screen.dart';
import 'manage_users_screen.dart';
import 'regular_users_screen.dart';
import 'content_writer_screen.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  int selectedTabIndex =
  1; // 0: All Users, 1: Active, 2: Blocked, 3: Regular, 4: Content Writer

  final List<Widget> _tabContents = const [
    ManageUsersScreen(),
    _ActiveUsersTab(),
    BlockedUsersScreen(),
    RegularUsersScreen(),
    ContentWriterScreen(),
  ];


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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Users',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppColors.textWhite,
                    ),
                  ),
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
                  children: [
                    _buildFilterTab('All Users', selectedTabIndex == 0, () {
                      setState(() => selectedTabIndex = 0);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterTab('Active', selectedTabIndex == 1, () {
                      setState(() => selectedTabIndex = 1);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterTab('Blocked', selectedTabIndex == 2, () {
                      setState(() => selectedTabIndex = 2);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterTab('Regular User', selectedTabIndex == 3, () {
                      setState(() => selectedTabIndex = 3);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterTab('Content Writer', selectedTabIndex == 4, () {
                      setState(() => selectedTabIndex = 4);
                    }),
                  ],
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
                child: IndexedStack(
                  index: selectedTabIndex,
                  children: _tabContents,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textWhite.withOpacity(0.7),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Active Users Content with Search
class _ActiveUsersTab extends StatefulWidget {
  const _ActiveUsersTab();

  @override
  State<_ActiveUsersTab> createState() => _ActiveUsersTabState();
}

class _ActiveUsersTabState extends State<_ActiveUsersTab> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchField(
            hint: 'Search...',
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase().trim();
              });
            },
          ),
        ),

        // Firestore User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('status', isEqualTo: 'Active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No active users found.',
                    style: AppTextStyles.h3,
                  ),
                );
              }

              final users = snapshot.data!.docs;

              // ✅ Filter users by search query (name or email)
              final filteredUsers = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();

                return name.contains(searchQuery) ||
                    email.contains(searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Text(
                    'No matching users.',
                    style: AppTextStyles.h3,
                  ),
                );
              }

              return ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user =
                  filteredUsers[index].data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: UserCard(
                      userId: filteredUsers[index].id,
                      name: user['name'] ?? 'Unknown',
                      email: user['email'] ?? '',
                      role: user['role'] ?? 'User',
                      status: user['status'] ?? 'Active',
                      avatarColor: AppColors.avatarColors[
                      index % AppColors.avatarColors.length],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
