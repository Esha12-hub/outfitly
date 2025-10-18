import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_field.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  String searchQuery = '';

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
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Firestore Blocked User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('status', isEqualTo: 'Blocked')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No blocked users found.',
                    style: AppTextStyles.h3,
                  ),
                );
              }

              // Get all users
              final users = snapshot.data!.docs;

              // Apply search filter
              final filteredUsers = users.where((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final name = (user['name'] ?? '').toString().toLowerCase();
                final email = (user['email'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery) || email.contains(searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Text(
                    'No matching users found.',
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
                      status: user['status'] ?? 'Blocked',
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
