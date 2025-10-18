import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manage_permissions_screen.dart';

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
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

  /// ✅ Check local media storage permission
  Future<bool> _checkMediaPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final isMediaAllowed = prefs.getBool('mediaStorage') ?? true;

    if (!isMediaAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Row(
            children: [
              Expanded(
                child: Text(
                  "Media access is disabled in manage permissions.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManagePermissionsScreen(),
                    ),
                  );
                },
                child: Text(
                  "Open",
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return false;
    }
    return true;
  }

  /// ✅ Check local camera permission
  Future<bool> _checkCameraPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final isCameraAllowed = prefs.getBool('cameraAccess') ?? true;

    if (!isCameraAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Row(
            children: [
              Expanded(
                child: Text(
                  "Camera access is disabled in manage permissions.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManagePermissionsScreen(),
                    ),
                  );
                },
                child: Text(
                  "Open",
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return false;
    }
    return true;
  }

  /// ✅ Show bottom sheet for image source
  Future<void> showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose an action",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () async {
                      Navigator.of(context).pop();
                      final allowed = await _checkCameraPermission();
                      if (!allowed) return;

                      final picked =
                      await picker.pickImage(source: ImageSource.camera);
                      if (picked != null) {
                        setState(() => selectedImage = File(picked.path));
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () async {
                      Navigator.of(context).pop();
                      final allowed = await _checkMediaPermission();
                      if (!allowed) return;

                      final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => selectedImage = File(picked.path));
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(16),
            child: Icon(icon, color: Colors.pink, size: 30),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void showAddDialog(String type) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add $type"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter $type"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                if (type == 'Category')
                  categories.add(controller.text);
                else if (type == 'Subcategory')
                  subcategories.add(controller.text);
              });
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void showDeleteDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete $type"),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: type == 'Category' ? categories.length : subcategories.length,
            itemBuilder: (context, index) {
              String item = type == 'Category' ? categories[index] : subcategories[index];
              return ListTile(
                title: Text(item),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      if (type == 'Category')
                        categories.removeAt(index);
                      else
                        subcategories.removeAt(index);
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void showColorPickerDialog() async {
    Color tempColor = Colors.black;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pick a Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) => tempColor = color,
            enableAlpha: false,
            showLabel: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                if (!colors.contains(tempColor)) colors.add(tempColor);
                selectedColor = tempColor;
              });
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void showDeleteColorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Color"),
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
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          if (onAdd != null)
            IconButton(icon: Icon(Icons.add, color: Colors.pink), onPressed: onAdd),
          if (onDelete != null)
            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget buildSelectableButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.pink : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset(
                            "assets/images/white_back_btn.png",
                            height: 30,
                            width: 30,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 70),
                        child: Text(
                          "Add Item",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: showImageSourceDialog,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 220,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Tap to upload image", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 250,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            TextField(
              controller: itemNameController,
              decoration: InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextField(
              controller: fabricController,
              decoration: InputDecoration(labelText: "Fabric", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            sectionTitle("Select Category",
                onAdd: () => showAddDialog('Category'), onDelete: () => showDeleteDialog('Category')),
            _buildGrid(categories, selectedCategory, (cat) => setState(() => selectedCategory = cat)),
            sectionTitle("Select Subcategory",
                onAdd: () => showAddDialog('Subcategory'), onDelete: () => showDeleteDialog('Subcategory')),
            _buildGrid(subcategories, selectedSubcategory, (sub) => setState(() => selectedSubcategory = sub)),
            sectionTitle("Select Season"),
            _buildGrid(seasons, selectedSeason, (season) => setState(() => selectedSeason = season)),
            sectionTitle("Select Occasion"),
            _buildGrid(occasions, selectedOccasion, (oc) => setState(() => selectedOccasion = oc)),
            sectionTitle("Select Color", onAdd: showColorPickerDialog, onDelete: showDeleteColorDialog),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: colors.map((c) => buildColorCircle(c)).toList()),
            ),
            SizedBox(height: 24),
            _buildSaveButton(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<String> items, String selected, ValueChanged<String> onSelect) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      children:
      items.map((item) => buildSelectableButton(item, selected == item, () => onSelect(item))).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (selectedImage == null || itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide item name and image")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      final base64Image =
      await selectedImage!.readAsBytes().then((bytes) => base64Encode(bytes));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe')
          .add({
        'item_name': itemNameController.text.trim(),
        'fabric': fabricController.text.trim(),
        'category': selectedCategory,
        'subcategory': selectedSubcategory,
        'season': selectedSeason,
        'occasion': selectedOccasion,
        'color': selectedColor?.value,
        'image_base64': base64Image,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        itemNameController.clear();
        fabricController.clear();
        selectedImage = null;
        selectedCategory = 'Top';
        selectedSubcategory = 'Shirt';
        selectedSeason = 'Summer';
        selectedOccasion = 'Casual';
        selectedColor = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item saved successfully ✅")),
      );
    } catch (e) {
      print("Error saving item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save item")),
      );
    }
  }
}
