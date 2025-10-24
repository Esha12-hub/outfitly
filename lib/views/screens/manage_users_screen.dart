import 'dart:convert';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        final horizontalPadding = isWideScreen ? 32.0 : 16.0;
        final verticalPadding = isWideScreen ? 24.0 : 16.0;

        return Column(
          children: [
            // 🔍 Search Bar (outside container)
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: CustomSearchField(
                hint: 'Search users...',
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase().trim();
                  });
                },
              ),
            ),

            // 📋 Firestore Users List inside container
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding / 2,
                      ),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => SizedBox(height: verticalPadding / 2),
                      itemBuilder: (context, index) {
                        final userDoc = filteredUsers[index];
                        final data = userDoc.data() as Map<String, dynamic>;

                        // ✅ Handle profile images: Base64, imageUrl, photoUrl, fallback
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

                        return UserCard(
                          userId: userDoc.id,
                          name: data['name'] ?? 'Unknown',
                          email: data['email'] ?? '',
                          role: data['role'] ?? 'User',
                          status: data['status'] ?? 'Active',
                          avatarColor: AppColors.avatarColors[index % AppColors.avatarColors.length],
                          profileImage: profileImage,
                          onTap: () => Get.to(
                                () => UserProfileScreen(
                              name: data['name'] ?? 'Unknown',
                              email: data['email'] ?? '',
                              role: data['role'] ?? 'User',
                              status: data['status'] ?? 'Active',
                              avatarColor: AppColors.avatarColors[index % AppColors.avatarColors.length],
                              avatarIcon: Icons.person,
                              uid: '',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
