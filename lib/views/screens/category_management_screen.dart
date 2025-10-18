import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/color_utils.dart';
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final Map<String, List<String>> categories = {
    'Tops': ['Shirts', 'T-shirts', 'Frocks', 'Jackets', 'Long Shirts'],
    'Bottoms': ['Jeans', 'Trousers', 'Plazo', 'Lehnga', 'Skirts'],
    'Outerwear': ['Upper', 'Hoodie', 'Puffer Jackets', 'Coats', 'Denim Jackets'],
    'Dresses': ['Casual Dresses', 'Formal Dresses', 'Evening Dresses', 'Summer Dresses', 'Party Dresses'],
    'Shoes': ['Heels', 'Block Heels', 'Pumps', 'Sandals', 'Joggers'],
    'Accessories': ['Jewelry', 'Scarfs', 'Bags', 'Belts', 'Dupatta'],
  };

  final Set<String> expandedCategories = <String>{};
  final Set<String> selectedCategories = {'Fashion Trends', 'Style Guides', 'Seasonal Outfits', 'DIY Fashion', 'Sustainable Fashion', 'Luxury Brands', 'Streetwear', 'Vintage Fashion'};

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
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Category Management',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.whiteHeading,
                    ),
                  ),
                  const SizedBox(width: 48),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ColorUtils.withOpacity(Colors.grey, 0.08),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorUtils.withOpacity(AppColors.primary, 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.category,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Category Management',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Manage your fashion categories and subcategories',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _expandAllCategories,
                                      icon: const Icon(Icons.expand_more, size: 18),
                                      label: const Text('Expand All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _collapseAllCategories,
                                      icon: const Icon(Icons.expand_less, size: 18),
                                      label: const Text('Collapse All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Categories List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories.keys.elementAt(index);
                            return _buildCategoryCard(category);
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Selected Categories Section
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ColorUtils.withOpacity(Colors.grey, 0.08),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorUtils.withOpacity(AppColors.secondary, 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Selected Categories',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (selectedCategories.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: ColorUtils.withOpacity(Colors.grey, 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: ColorUtils.withOpacity(Colors.grey, 0.1),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No categories selected yet',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: selectedCategories.map((category) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: ColorUtils.withOpacity(AppColors.primary, 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: ColorUtils.withOpacity(AppColors.primary, 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedCategories.remove(category);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoryCard(String category) {
    final isExpanded = expandedCategories.contains(category);
    final items = categories[category] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? AppColors.primary : ColorUtils.withOpacity(Colors.grey, 0.2),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withOpacity(Colors.grey, 0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpanded ? ColorUtils.withOpacity(AppColors.primary, 0.05) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isExpanded ? AppColors.primary : ColorUtils.withOpacity(AppColors.primary, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: isExpanded ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpanded ? ColorUtils.withOpacity(AppColors.primary, 0.7) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      color: AppColors.primary,
                      onTap: () => _editCategory(category),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () => _deleteCategory(category),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      onTap: () => _toggleCategoryExpansion(category),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Items (if expanded)
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items in this category:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorUtils.withOpacity(Colors.grey, 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.edit,
                              color: AppColors.primary,
                              onTap: () => _editItem(category, item),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            _buildActionButton(
                              icon: Icons.delete,
                              color: Colors.red,
                              onTap: () => _deleteItem(category, item),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorUtils.withOpacity(color, 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tops':
        return Icons.checkroom;
      case 'bottoms':
        return Icons.accessibility;
      case 'outerwear':
        return Icons.ac_unit;
      case 'dresses':
        return Icons.style;
      case 'shoes':
        return Icons.sports_soccer;
      case 'accessories':
        return Icons.watch;
      default:
        return Icons.category;
    }
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
    final TextEditingController categoryController = TextEditingController(text: category);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryController.text.trim().isNotEmpty) {
                final newName = categoryController.text.trim();
                setState(() {
                  final items = categories[category]!;
                  categories.remove(category);
                  categories[newName] = items;
                  if (expandedCategories.contains(category)) {
                    expandedCategories.remove(category);
                    expandedCategories.add(newName);
                  }
                });
                Get.back();
                Get.snackbar(
                  'Category Updated',
                  'Category has been renamed to $newName.',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textWhite,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"? This will also delete all items in this category.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                categories.remove(category);
                expandedCategories.remove(category);
              });
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
    final TextEditingController itemController = TextEditingController(text: item);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(
          controller: itemController,
          decoration: const InputDecoration(
            labelText: 'Item Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (itemController.text.trim().isNotEmpty) {
                setState(() {
                  final index = categories[category]!.indexOf(item);
                  categories[category]![index] = itemController.text.trim();
                });
                Get.back();
                Get.snackbar(
                  'Item Updated',
                  'Item has been updated successfully.',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textWhite,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
              setState(() {
                categories[category]!.remove(item);
              });
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