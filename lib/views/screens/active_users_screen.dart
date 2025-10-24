import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_field.dart';
import 'blocked_users_screen.dart';
import 'manage_users_screen.dart';
import 'regular_users_screen.dart';
import 'content_writer_screen.dart';
import 'admin_login_screen.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  int selectedTabIndex = 1; // 0: All Users, 1: Active, 2: Blocked, 3: Regular, 4: Writer

  final List<Widget> _tabContents = const [
    ManageUsersScreen(),
    _ActiveUsersTab(),
    BlockedUsersScreen(),
    RegularUsersScreen(),
    ContentWriterScreen(),
  ];

  // ✅ Logout Handler
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleLogout, // ✅ Logout on back press
                    icon: Image.asset(
                      'assets/images/white_back_btn.png',
                      width: screenWidth * 0.07,
                      height: screenWidth * 0.07,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Users',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading.copyWith(
                        fontSize: screenWidth * 0.05,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        // Just rebuild to refresh the stream
                      });
                    },
                    icon: const Icon(Icons.refresh, color: AppColors.textWhite),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              height: screenHeight * 0.065,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTab('All Users', selectedTabIndex == 0, () {
                      setState(() => selectedTabIndex = 0);
                    }, screenWidth),
                    SizedBox(width: screenWidth * 0.02),
                    _buildFilterTab('Active', selectedTabIndex == 1, () {
                      setState(() => selectedTabIndex = 1);
                    }, screenWidth),
                    SizedBox(width: screenWidth * 0.02),
                    _buildFilterTab('Blocked', selectedTabIndex == 2, () {
                      setState(() => selectedTabIndex = 2);
                    }, screenWidth),
                    SizedBox(width: screenWidth * 0.02),
                    _buildFilterTab('Regular User', selectedTabIndex == 3, () {
                      setState(() => selectedTabIndex = 3);
                    }, screenWidth),
                    SizedBox(width: screenWidth * 0.02),
                    _buildFilterTab('Content Writer', selectedTabIndex == 4, () {
                      setState(() => selectedTabIndex = 4);
                    }, screenWidth),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

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

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap, double screenWidth) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.025),
        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
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
              fontSize: screenWidth * 0.033,
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Active Users Tab (Base64 + imageUrl + photoUrl + placeholder)
class _ActiveUsersTab extends StatefulWidget {
  const _ActiveUsersTab();

  @override
  State<_ActiveUsersTab> createState() => _ActiveUsersTabState();
}

class _ActiveUsersTabState extends State<_ActiveUsersTab> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    return Column(
      children: [
        // 🔍 Search Bar
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: CustomSearchField(
            hint: 'Search...',
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase().trim();
              });
            },
          ),
        ),

        // 👥 Firestore Active Users List
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
                return Center(
                  child: Text('No active users found.',
                      style: AppTextStyles.h3.copyWith(fontSize: screenWidth * 0.04)),
                );
              }

              final users = snapshot.data!.docs;

              final filteredUsers = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery) || email.contains(searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Text('No matching users.',
                      style: AppTextStyles.h3.copyWith(fontSize: screenWidth * 0.04)),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final data = filteredUsers[index].data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'Unknown';
                  final email = data['email'] ?? '';
                  final role = data['role'] ?? 'User';
                  final status = data['status'] ?? 'Active';

                  // ✅ Handle all image sources
                  final imageBase64 = data['image_base64'];
                  final imageUrl = data['imageUrl'];
                  final photoUrl = data['photoUrl'];
                  ImageProvider? profileImage;

                  if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
                    try {
                      final bytes = base64Decode(imageBase64.toString().split(',').last);
                      profileImage = MemoryImage(bytes);
                    } catch (e) {
                      profileImage = null;
                    }
                  } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
                    profileImage = NetworkImage(imageUrl);
                  } else if (photoUrl != null && photoUrl.toString().isNotEmpty) {
                    profileImage = NetworkImage(photoUrl);
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                    child: UserCard(
                      userId: filteredUsers[index].id,
                      name: name,
                      email: email,
                      role: role,
                      status: status,
                      avatarColor: AppColors.avatarColors[index % AppColors.avatarColors.length],
                      profileImage: profileImage,
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
