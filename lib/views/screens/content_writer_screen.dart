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
    final profilePic = data['profilePic'];

    ImageProvider? profileImage;

    try {
      if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
        final bytes = base64Decode(imageBase64.toString().split(',').last);
        profileImage = MemoryImage(bytes);
      } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        profileImage = NetworkImage(imageUrl);
      } else if (photoUrl != null && photoUrl.toString().isNotEmpty) {
        profileImage = NetworkImage(photoUrl);
      } else if (profilePic != null && profilePic.toString().isNotEmpty) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;
            final horizontalPadding = isWideScreen ? 32.0 : 16.0;
            final verticalPadding = isWideScreen ? 24.0 : 16.0;

            return Column(
              children: [
                SizedBox(height: verticalPadding / 2),

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
                        Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: CustomSearchField(
                            hint: 'Search content writers...',
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase().trim();
                              });
                            },
                          ),
                        ),

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
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: verticalPadding / 2),
                                itemCount: filteredUsers.length,
                                separatorBuilder: (_, __) => SizedBox(height: verticalPadding / 2),
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
                                    profileImage: profileImage,
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
            );
          },
        ),
      ),
    );
  }
}
