import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'dashboard_screen.dart';
import 'manage_users_screen.dart';
import '../../controllers/navigation_controller.dart';

class UserProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String role;
  final String status;
  final Color avatarColor;
  final IconData? avatarIcon;

  const UserProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.avatarColor,
    this.avatarIcon,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final Map<String, List<String>> categories = {
    'Tops': ['Shirts', 'T-shirts', 'Frocks', 'Jackets', 'Long Shirts'],
    'Bottoms': ['Jeans', 'Trousers', 'Plazo', 'Lehnga', 'Skirts'],
    'Outerwear': ['Upper', 'Hoodie', 'Puffer Jackets', 'Coats', 'Denim Jackets'],
    'Dresses': ['Casual Dresses', 'Formal Dresses', 'Evening Dresses', 'Summer Dresses', 'Party Dresses'],
    'Shoes': ['Heels', 'Block Heels', 'Pumps', 'Sandals', 'Joggers'],
    'Accessories': ['Jewelry', 'Scarfs', 'Bags', 'Belts', 'Dupatta'],
  };

  final Set<String> expandedCategories = <String>{};

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
                    onPressed: () async {
                      final controller = Get.find<NavigationController>();
                      // Check if we came from dashboard (admin profile) or users screen
                      if (widget.name == 'Admin User' && widget.email == 'admin@aiwardrobe.com') {
                        // Admin profile - go back to dashboard
                        await controller.changeIndex(0); // Set to Home tab
                        Get.offAll(() => const DashboardScreen());
                      } else {
                        // Regular user profile - go back to users screen
                        await controller.changeIndex(1); // Set to Users tab
                        Get.offAll(() => const ManageUsersScreen());
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'User Profile',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  // Placeholder to balance the layout
                  const SizedBox(width: 48), // Same width as IconButton
                ],
              ),
            ),

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Profile Picture
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: widget.avatarColor.withOpacity(0.3),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.avatarColor,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 47,
                                  backgroundColor: widget.avatarColor,
                                  child: Icon(
                                    widget.avatarIcon ?? Icons.person,
                                    color: AppColors.textWhite,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // User Name & Email
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // User Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.role,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.status,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Key Metrics
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMetric('145', 'Wardrobe Items'),
                                _buildMetric('43', 'Outfits Created'),
                                _buildMetric('89', 'Try-Ons'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Account Action Buttons
                      Column(
                        children: [
                          _buildActionButton(
                            'Reset Password',
                            Icons.key,
                            AppColors.primary,
                            AppColors.textWhite,
                            () {
                              Get.snackbar(
                                'Reset Password',
                                'Password reset link sent to user email!',
                                backgroundColor: AppColors.primary,
                                colorText: AppColors.textWhite,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Block User',
                            Icons.block,
                            Colors.white,
                            Colors.black87,
                            () {
                              Get.snackbar(
                                'Block User',
                                'User has been blocked successfully!',
                                backgroundColor: AppColors.error,
                                colorText: AppColors.textWhite,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Delete Account',
                            Icons.delete,
                            Colors.white,
                            Colors.black87,
                            () {
                              Get.snackbar(
                                'Delete Account',
                                'Account deletion request sent!',
                                backgroundColor: AppColors.error,
                                colorText: AppColors.textWhite,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Activity Section
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem('Added new outfit', '2h ago'),
                      const SizedBox(height: 8),
                      _buildActivityItem('Updated Profile', '5h ago'),
                      const SizedBox(height: 24),

                      // View Activity Log Buttons
                      _buildActionButton(
                        'View Activity Log',
                        Icons.person,
                        AppColors.primary,
                        AppColors.textWhite,
                        () {
                          Get.snackbar(
                            'Activity Log',
                            'Opening detailed activity log...',
                            backgroundColor: AppColors.primary,
                            colorText: AppColors.textWhite,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'View Activity Log',
                        Icons.person,
                        Colors.grey[300]!,
                        Colors.grey[600]!,
                        null, // Disabled button
                      ),
                      const SizedBox(height: 24),

                      // Category Management Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: _expandAllCategories,
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Expand All'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: _collapseAllCategories,
                                  icon: const Icon(Icons.expand_less),
                                  label: const Text('Collapse All'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories.keys.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCategoryCard(category),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: textColor),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          activity,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category) {
    final isExpanded = expandedCategories.contains(category);
    final items = categories[category] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _editCategory(category),
                  child: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteCategory(category),
                  child: const Icon(Icons.delete, size: 18, color: Colors.red),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleCategoryExpansion(category),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Category Items
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.black)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _editItem(category, item),
                          child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteItem(category, item),
                          child: const Icon(Icons.delete, size: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleCategoryExpansion(String category) {
    setState(() {
      if (expandedCategories.contains(category)) {
        expandedCategories.remove(category);
      } else {
        expandedCategories.add(category);
      }
    });
  }

  void _expandAllCategories() {
    setState(() {
      expandedCategories.addAll(categories.keys);
    });
  }

  void _collapseAllCategories() {
    setState(() {
      expandedCategories.clear();
    });
  }

  void _editCategory(String category) {
    Get.snackbar(
      'Edit Category',
      'Editing $category...',
      backgroundColor: AppColors.primary,
      colorText: AppColors.textWhite,
    );
  }

  void _deleteCategory(String category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Category Deleted',
                '$category has been deleted.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editItem(String category, String item) {
    Get.snackbar(
      'Edit Item',
      'Editing $item in $category...',
      backgroundColor: AppColors.primary,
      colorText: AppColors.textWhite,
    );
  }

  void _deleteItem(String category, String item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$item"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Item Deleted',
                '$item has been deleted from $category.',
                backgroundColor: AppColors.success,
                colorText: AppColors.textWhite,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 