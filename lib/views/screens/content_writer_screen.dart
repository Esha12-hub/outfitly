import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/user_card.dart';
import '../widgets/custom_search_field.dart';

class ContentWriterScreen extends StatefulWidget {
  const ContentWriterScreen({super.key});

  @override
  State<ContentWriterScreen> createState() => _ContentWriterScreenState();
}

class _ContentWriterScreenState extends State<ContentWriterScreen> {
  String searchQuery = '';

  ImageProvider? _getProfileImage(Map<String, dynamic> data) {
    final imageBase64 = data['image_base64'];
    final imageUrl = data['imageUrl'];
    final photoUrl = data['photoUrl'];
    final profilePic = data['profilePic']; // sometimes stored with this name

    ImageProvider? profileImage;

    try {
      if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
        // ✅ Decode Base64 image
        final bytes = base64Decode(imageBase64.toString().split(',').last);
        profileImage = MemoryImage(bytes);
      } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        // ✅ Use Firestore URL
        profileImage = NetworkImage(imageUrl);
      } else if (photoUrl != null && photoUrl.toString().isNotEmpty) {
        // ✅ Use Google/Firebase Auth photo URL
        profileImage = NetworkImage(photoUrl);
      } else if (profilePic != null && profilePic.toString().isNotEmpty) {
        // ✅ Handle profilePic (could be Base64 or direct URL)
        final picStr = profilePic.toString();
        if (picStr.startsWith('data:image')) {
          final bytes = base64Decode(picStr.split(',').last);
          profileImage = MemoryImage(bytes);
        } else {
          profileImage = NetworkImage(picStr);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error decoding profile image: $e');
      profileImage = null;
    }

    return profileImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

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
                    // 🔍 Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomSearchField(
                        hint: 'Search content writers...',
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase().trim();
                          });
                        },
                      ),
                    ),

                    // 📋 Firestore List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'Content Writer')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No content writers found.',
                                style: AppTextStyles.h3,
                              ),
                            );
                          }

                          final users = snapshot.data!.docs;

                          // 🔍 Apply search filter
                          final filteredUsers = users.where((doc) {
                            final user = doc.data() as Map<String, dynamic>;
                            final name = (user['name'] ?? '').toString().toLowerCase();
                            final email = (user['email'] ?? '').toString().toLowerCase();
                            return name.contains(searchQuery) || email.contains(searchQuery);
                          }).toList();

                          if (filteredUsers.isEmpty) {
                            return const Center(
                              child: Text(
                                'No matching content writers found.',
                                style: AppTextStyles.h3,
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final doc = filteredUsers[index];
                              final data = doc.data() as Map<String, dynamic>;

                              final profileImage = _getProfileImage(data);

                              return UserCard(
                                userId: doc.id,
                                name: data['name'] ?? 'Unknown',
                                email: data['email'] ?? '',
                                role: data['role'] ?? 'Content Writer',
                                status: data['status'] ?? 'Active',
                                avatarColor: AppColors.avatarColors[index % AppColors.avatarColors.length],
                                profileImage: profileImage, // ✅ Added
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
