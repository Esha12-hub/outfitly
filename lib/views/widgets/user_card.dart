import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../screens/user_profile_screen.dart';

class UserCard extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final Color avatarColor;
  final ImageProvider? profileImage;
  final VoidCallback? onTap;
  final IconData? avatarIcon;
  final Widget? trailing;

  const UserCard({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.avatarColor,
    this.profileImage,
    this.onTap,
    this.avatarIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor:
              profileImage == null ? avatarColor : Colors.transparent,
              backgroundImage: profileImage,
              child: profileImage == null
                  ? Icon(avatarIcon ?? Icons.person,
                  color: AppColors.textWhite, size: 26)
                  : null,
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(email, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(role, AppColors.primary.withOpacity(0.2),
                          AppColors.primary),
                      const SizedBox(width: 8),
                      _buildChip(
                        status,
                        status == 'Active'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        status == 'Active' ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Options Menu
            PopupMenuButton<String>(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          uid: userId, // pass actual userId
                          name: name,
                          email: email,
                          role: role,
                          status: status,
                          avatarColor: avatarColor,
                          avatarIcon: avatarIcon,
                        ),

                      ),
                    );
                    break;

                  case 'block':
                    _confirmAction(
                      context,
                      title: 'Block User',
                      message: 'Are you sure you want to block $name?',
                      confirmText: 'Block',
                      confirmColor: Colors.red,
                      onConfirm: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({'status': 'Blocked'});
                        _showMessage(context, '$name has been blocked.');
                      },
                    );
                    break;

                  case 'delete':
                    _confirmAction(
                      context,
                      title: 'Delete User',
                      message:
                      'Are you sure you want to permanently delete $name?',
                      confirmText: 'Delete',
                      confirmColor: Colors.red,
                      onConfirm: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .delete();
                        _showMessage(context, '$name has been deleted.');
                      },
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.black87),
                      SizedBox(width: 8),
                      Text('Edit User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Block User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete User'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
    );
  }

  void _confirmAction(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmText,
        required Color confirmColor,
        required VoidCallback onConfirm,
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            child:
            const Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 14)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(confirmText,
                style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
