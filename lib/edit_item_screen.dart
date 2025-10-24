import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

class EditItemScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const EditItemScreen({super.key, required this.itemId, required this.itemData});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  File? selectedImage;
  TextEditingController itemNameController = TextEditingController();
  TextEditingController fabricController = TextEditingController();

  List<String> categories = ['Top', 'Bottom', 'Outerwear'];
  List<String> subcategories = ['Shirt', 'Jeans', 'Jacket'];
  List<String> seasons = ['Summer', 'Winter', 'Rainy'];
  List<String> occasions = ['Casual', 'Formal', 'Party', 'Work'];
  List<Color> colors = [];

  String selectedCategory = 'Top';
  String selectedSubcategory = 'Shirt';
  String selectedSeason = 'Summer';
  String selectedOccasion = 'Casual';
  Color? selectedColor;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    itemNameController.text = widget.itemData['item_name'] ?? '';
    fabricController.text = widget.itemData['fabric'] ?? '';
    selectedCategory = widget.itemData['category'] ?? 'Top';
    selectedSubcategory = widget.itemData['subcategory'] ?? 'Shirt';
    selectedSeason = widget.itemData['season'] ?? 'Summer';
    selectedOccasion = widget.itemData['occasion'] ?? 'Casual';

    if (widget.itemData['colors'] != null) {
      List<dynamic> savedColors = widget.itemData['colors'];
      colors = savedColors.map((c) => Color(c)).toList();
      if (colors.isNotEmpty) selectedColor = colors.first;
    } else if (widget.itemData['color'] != null) {
      selectedColor = Color(widget.itemData['color']);
      colors.add(selectedColor!);
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> updateItem() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? base64Image;
      if (selectedImage != null) {
        base64Image =
        await selectedImage!.readAsBytes().then((bytes) => base64Encode(bytes));
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe')
          .doc(widget.itemId)
          .update({
        'item_name': itemNameController.text.trim(),
        'fabric': fabricController.text.trim(),
        'category': selectedCategory,
        'subcategory': selectedSubcategory,
        'season': selectedSeason,
        'occasion': selectedOccasion,
        'colors': colors.map((c) => c.value).toList(),
        if (base64Image != null) 'image_base64': base64Image,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item updated successfully")),
        );
      }
    } catch (e) {
      print("Error updating item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update item")),
      );
    }
  }

  void showColorPickerDialog() async {
    Color tempColor = Colors.black;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pick a Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) => tempColor = color,
            enableAlpha: false,
            showLabel: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                if (!colors.contains(tempColor)) colors.add(tempColor);
                selectedColor = tempColor;
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void showDeleteColorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Color"),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => colors.remove(color));
                Navigator.pop(context);
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, {VoidCallback? onAdd, VoidCallback? onDelete}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          if (onAdd != null)
            IconButton(icon: const Icon(Icons.add, color: Colors.pink), onPressed: onAdd),
          if (onDelete != null)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.pink : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingImageBase64 = widget.itemData['image_base64'];
    final size = MediaQuery.of(context).size;
    final textScale = size.width < 400 ? 0.9 : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double horizontalPadding = constraints.maxWidth * 0.04;
            double fieldSpacing = constraints.maxHeight * 0.015;

            return Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: constraints.maxHeight * 0.02),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset("assets/images/white_back_btn.png",
                            height: 30, width: 30),
                      ),
                      SizedBox(width: constraints.maxWidth * 0.04),
                      Text(
                        "Edit Item",
                        textScaleFactor: textScale,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Image Picker
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    height: constraints.maxHeight * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: selectedImage != null
                        ? ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.file(selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: constraints.maxHeight * 0.25),
                    )
                        : (existingImageBase64 != null
                        ? ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.memory(
                        base64Decode(existingImageBase64.split(',').last),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: constraints.maxHeight * 0.25,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Tap to upload image",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    )),
                  ),
                ),

                // Form
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(horizontalPadding),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: itemNameController,
                            decoration: const InputDecoration(
                                labelText: "Item Name", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: fieldSpacing),
                          TextField(
                            controller: fabricController,
                            decoration: const InputDecoration(
                                labelText: "Fabric", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: fieldSpacing),

                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            items: categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedCategory = val!),
                            decoration: const InputDecoration(
                                labelText: "Category", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: fieldSpacing),

                          DropdownButtonFormField<String>(
                            value: selectedSubcategory,
                            items: subcategories
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedSubcategory = val!),
                            decoration: const InputDecoration(
                                labelText: "Subcategory", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: fieldSpacing),

                          DropdownButtonFormField<String>(
                            value: selectedSeason,
                            items: seasons
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedSeason = val!),
                            decoration: const InputDecoration(
                                labelText: "Season", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: fieldSpacing),

                          DropdownButtonFormField<String>(
                            value: selectedOccasion,
                            items: occasions
                                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedOccasion = val!),
                            decoration: const InputDecoration(
                                labelText: "Occasion", border: OutlineInputBorder()),
                          ),
                          SizedBox(height: fieldSpacing),

                          sectionTitle("Select Color",
                              onAdd: showColorPickerDialog,
                              onDelete: showDeleteColorDialog),
                          SizedBox(height: fieldSpacing * 0.5),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: colors.map((c) => buildColorCircle(c)).toList(),
                            ),
                          ),
                          SizedBox(height: fieldSpacing * 1.5),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: updateItem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Update",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              SizedBox(width: constraints.maxWidth * 0.03),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Cancel",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
