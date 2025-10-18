import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_field.dart';
import 'user_profile_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 Search Bar (outside container)
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchField(
            hint: 'Search users...',
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // 📋 Firestore Users List inside container
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No users found', style: AppTextStyles.h3),
                );
              }

              final users = snapshot.data!.docs;

              // ✅ Apply search filter
              final filteredUsers = users.where((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final name = (user['name'] ?? '').toString().toLowerCase();
                final email = (user['email'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery) || email.contains(searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Text('No matching users found.', style: AppTextStyles.h3),
                );
              }

              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final data = userDoc.data() as Map<String, dynamic>;

                    return UserCard(
                      userId: userDoc.id,
                      name: data['name'] ?? 'Unknown',
                      email: data['email'] ?? '',
                      role: data['role'] ?? 'User',
                      status: data['status'] ?? 'Active',
                      avatarColor: AppColors.avatarColors[
                      index % AppColors.avatarColors.length],
                      onTap: () => Get.to(() => UserProfileScreen(
                        name: data['name'] ?? 'Unknown',
                        email: data['email'] ?? '',
                        role: data['role'] ?? 'User',
                        status: data['status'] ?? 'Active',
                        avatarColor: AppColors.avatarColors[
                        index % AppColors.avatarColors.length],
                        avatarIcon: Icons.person,
                      )),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
