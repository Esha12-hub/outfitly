import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_field.dart';

class RegularUsersScreen extends StatefulWidget {
  const RegularUsersScreen({super.key});

  @override
  State<RegularUsersScreen> createState() => _RegularUsersScreenState();
}

class _RegularUsersScreenState extends State<RegularUsersScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16), // spacing at top

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

                    // Firestore Users List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', whereIn: ['User', 'user']) // handle case sensitivity
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No regular users found.',
                                style: AppTextStyles.h3,
                              ),
                            );
                          }

                          final users = snapshot.data!.docs;

                          // 🔍 Filter by search query (name or email)
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final userData = filteredUsers[index].data() as Map<String, dynamic>;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: UserCard(
                                  userId: filteredUsers[index].id, // 🔑 Firestore doc ID
                                  name: userData['name'] ?? 'Unknown',
                                  email: userData['email'] ?? '',
                                  role: userData['role'] ?? 'User',
                                  status: userData['status'] ?? 'Active',
                                  avatarColor: AppColors.avatarColors[index % AppColors.avatarColors.length],
                                ),
                              );
                            },
                          );
                        },
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
}
