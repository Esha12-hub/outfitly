import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';
import 'models/clothing_item_model.dart';
import 'add_clothing_item_screen.dart';
import 'clothing_item_detail_screen.dart';
import 'views/screens/dashboard_screen.dart';

class SmartShoppingScreen extends StatefulWidget {
  const SmartShoppingScreen({super.key});

  @override
  State<SmartShoppingScreen> createState() => _SmartShoppingScreenState();
}

class _SmartShoppingScreenState extends State<SmartShoppingScreen> {
  String? selectedCategory;
  bool isAdmin = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final adminDoc =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();

      if (adminDoc.exists) {
        setState(() => isAdmin = true);
        return;
      }

      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() => isAdmin = data['isAdmin'] ?? false);
      }
    }
  }

  Future<void> _deleteClothingItem(String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('clothing_items')
          .doc(itemId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(String itemId, String itemName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.pink),
              const SizedBox(height: 16),
              Text(
                'Delete Product',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete "$itemName"?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteClothingItem(itemId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          selectedCategory == null
              ? 'Smart Shopping'
              : _getCategoryName(selectedCategory!),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/white_back_btn.png',
            width: 28,
            height: 28,
          ),
          onPressed: () {
            setState(() {
              if (_searchQuery.isNotEmpty) {
                _searchQuery = '';
                _searchController.clear();
              } else if (selectedCategory != null) {
                selectedCategory = null;
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              }
            });
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _searchQuery.isNotEmpty
              ? _buildClothingItemsGrid()
              : selectedCategory == null
              ? _buildCategoryGrid()
              : _buildClothingItemsGrid(),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddClothingItemScreen(),
            ),
          );
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildCategoryGrid() {
    final categories = ClothingCategory.getDefaultCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop by Category',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a category to explore our collection',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchField(),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(categories[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ClothingCategory category) {
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = category.id.toLowerCase()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  category.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child:
                      const Icon(Icons.image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClothingItemsGrid() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: _buildSearchField()),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
            FirebaseFirestore.instance.collection('clothing_items').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _noItemsWidget('No items found');
              }

              final items = snapshot.data!.docs
                  .map((doc) =>
                  ClothingItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .where((item) {
                final matchesSearch = _searchQuery.isEmpty ||
                    item.name.toLowerCase().contains(_searchQuery) ||
                    item.description.toLowerCase().contains(_searchQuery);

                final matchesCategory = selectedCategory == null ||
                    (item.categoryId.toLowerCase() ==
                        selectedCategory!.toLowerCase());

                return matchesSearch && matchesCategory;
              }).toList();

              if (items.isEmpty) {
                return _noItemsWidget(selectedCategory != null
                    ? 'No items found in this category'
                    : 'No products found for "$_searchQuery"');
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildClothingItemCard(items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 500), () {
          setState(() => _searchQuery = value.toLowerCase());
        });
      },
      onSubmitted: (value) {
        _searchTimer?.cancel();
        setState(() => _searchQuery = value.toLowerCase());
      },
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          },
          icon: const Icon(Icons.clear),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _noItemsWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    final categories = ClothingCategory.getDefaultCategories();
    final category = categories.firstWhere(
          (cat) => cat.id.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => ClothingCategory(
        id: categoryId,
        name: categoryId.toUpperCase(),
        imageUrl: '',
        description: '',
      ),
    );
    return category.name;
  }

  Widget _buildClothingItemCard(ClothingItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClothingItemDetailScreen(item: item),
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[200]),
                      child: item.imageUrls.isNotEmpty
                          ? _buildImageWidget(item.imageUrls.first)
                          : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showDeleteConfirmation(item.id, item.name),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child:
                  const Icon(Icons.delete, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image')) {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        return Image.memory(bytes, fit: BoxFit.cover);
      } else {
        return Image.network(imageUrl, fit: BoxFit.cover);
      }
    } catch (_) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
  }
}
