import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'models/clothing_item_model.dart';

class AddClothingItemScreen extends StatefulWidget {
  const AddClothingItemScreen({super.key});

  @override
  State<AddClothingItemScreen> createState() => _AddClothingItemScreenState();
}

class _AddClothingItemScreenState extends State<AddClothingItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productLinkController = TextEditingController();

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  List<ClothingCategory> _categories = ClothingCategory.getDefaultCategories();
  ClothingCategory? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _productLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)).toList());
        });
      }
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  void _clearAllImages() {
    setState(() => _selectedImages.clear());
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final bytes = await _selectedImages[i].readAsBytes();
        final base64String = base64Encode(bytes);
        String mimeType = 'image/jpeg';
        final fileName = _selectedImages[i].path.toLowerCase();
        if (fileName.endsWith('.png')) mimeType = 'image/png';
        if (fileName.endsWith('.gif')) mimeType = 'image/gif';
        if (fileName.endsWith('.webp')) mimeType = 'image/webp';
        imageUrls.add('data:$mimeType;base64,$base64String');
      } catch (e) {
        imageUrls.add('https://via.placeholder.com/400x400?text=Image+${i + 1}');
      }
    }
    return imageUrls;
  }

  Future<void> _saveClothingItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) return _showError('Please select at least one image');
    if (_selectedCategory == null) return _showError('Please select a category');

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _showError('User not authenticated');

      final imageUrls = await _uploadImages();

      final clothingItem = ClothingItem(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        productLink: _productLinkController.text.trim(),
        createdAt: DateTime.now(),
        adminId: user.uid,
        categoryId: _selectedCategory!.id,
      );

      await FirebaseFirestore.instance.collection('clothing_items').add(clothingItem.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clothing item added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error adding item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Clothing Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
          fontSize: 20),
        ),
        leading: IconButton(
          icon: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: Container(
          color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Product Images',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_selectedImages.isNotEmpty)
                              TextButton(
                                onPressed: _clearAllImages,
                                child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: size.height * 0.16,
                          child: _selectedImages.isEmpty
                              ? GestureDetector(
                            onTap: _pickImages,
                            child: DottedBorderContainer(),
                          )
                              : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _selectedImages.length) {
                                return AddMoreImageButton(onTap: _pickImages);
                              }
                              return SelectedImageThumbnail(
                                image: _selectedImages[index],
                                onRemove: () {
                                  setState(() => _selectedImages.removeAt(index));
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        buildTextField(_nameController, 'Product Name', Icons.shopping_bag),
                        SizedBox(height: size.height * 0.015),
                        buildTextField(_descriptionController, 'Description', Icons.description,
                            maxLines: 3, optional: true),
                        SizedBox(height: size.height * 0.02),
                        buildTextField(_productLinkController, 'Product Link', Icons.link,
                            hintText: 'https://example.com/product'),
                        SizedBox(height: size.height * 0.02),
                        DropdownButtonFormField<ClothingCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a category' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: SizedBox(
                  width: double.infinity,
                  height: size.height * 0.06,
                  child: ElevatedButton(
                    onPressed: _saveClothingItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Add Clothing Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
        String? hintText,
        int maxLines = 1,
        bool optional = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (!optional && (value == null || value.trim().isEmpty)) {
          return 'Please enter ${label.toLowerCase()}';
        }
        return null;
      },
    );
  }
}

class DottedBorderContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: size.height * 0.14,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 40),
            Text('Tap to add images'),
          ],
        ),
      ),
    );
  }
}

class AddMoreImageButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddMoreImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width * 0.25,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 30),
              Text(
                'Add More\nImages',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectedImageThumbnail extends StatelessWidget {
  final File image;
  final VoidCallback onRemove;
  const SelectedImageThumbnail({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.25,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(image, width: size.width * 0.25, height: size.width * 0.25, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
