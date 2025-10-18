import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 for Firestore
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../screens/user_profile_screen.dart';

class UserCard extends StatelessWidget {
  final String userId; // Firestore document ID
  final String name;
  final String email;
  final String role;
  final String status;
  final Color avatarColor;
  final VoidCallback? onTap;
  final IconData? avatarIcon;
  final Widget? trailing;

  const UserCard({
    super.key,
    required this.userId, // 🔥 must be passed when building card
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.avatarColor,
    this.onTap,
    this.avatarIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor,
              child: Icon(
                avatarIcon ?? Icons.person,
                color: AppColors.textWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(role),
                      const SizedBox(width: 8),
                      _buildStatusChip(status),
                    ],
                  ),
                ],
              ),
            ),

            // Options Menu
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    Get.to(() => UserProfileScreen(
                      name: name,
                      email: email,
                      role: role,
                      status: status,
                      avatarColor: avatarColor,
                      avatarIcon: avatarIcon,
                    ));
                    break;

                  case 'block':
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({'status': 'Blocked'}); // 🔥 update Firestore

                      Get.snackbar(
                        'Block User',
                        '$name has been blocked ✅',
                        backgroundColor: AppColors.success,
                        colorText: AppColors.textWhite,
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Failed to block user: $e',
                        backgroundColor: AppColors.error,
                        colorText: AppColors.textWhite,
                      );
                    }
                    break;

                  case 'delete':
                    Get.snackbar(
                      'Delete User',
                      'User deleted successfully!',
                      backgroundColor: AppColors.error,
                      colorText: AppColors.textWhite,
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 16),
                      SizedBox(width: 8),
                      Text('Block User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16),
                      SizedBox(width: 8),
                      Text('Delete User'),
                    ],
                  ),
                ),
              ],
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption,
      ),
    );
  }
}
