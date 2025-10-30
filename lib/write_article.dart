import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'writer_login_screen.dart';

class WriteArticleScreen extends StatefulWidget {
  const WriteArticleScreen({super.key});

  @override
  State<WriteArticleScreen> createState() => _WriteArticleScreenState();
}

class _WriteArticleScreenState extends State<WriteArticleScreen> {
  String _selectedCategory = 'Styling Tips';
  String? _selectedMediaBase64;

  bool _isDraftSaving = false;
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _contentController = TextEditingController();
  final _captionController = TextEditingController();

  // Rich text formatting
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isList = false;
  TextAlign _textAlign = TextAlign.left;

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _contentController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // Pick Image Only
  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    setState(() {
      _selectedMediaBase64 = base64String;
    });
  }

  // Unified save function for draft or submit
  Future<void> _saveArticle({required String status}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please log in.")));
      return;
    }

    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title and content cannot be empty.")));
      return;
    }

    if (status == 'draft') {
      setState(() => _isDraftSaving = true);
    } else {
      setState(() => _isSubmitting = true);
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('articles')
          .add({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'tags': _tagController.text.trim(),
        'content': _contentController.text.trim(),
        'mediaBase64': _selectedMediaBase64 ?? '',
        'caption': _captionController.text.trim(),
        'timestamp': Timestamp.now(),
        'status': status, // 'draft' or 'pending'
      });

      // Reset form
      _titleController.clear();
      _tagController.clear();
      _contentController.clear();
      _captionController.clear();
      setState(() {
        _selectedMediaBase64 = null;
        _selectedCategory = 'Styling Tips';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                status == 'draft' ? "Draft saved!" : "Article submitted!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (status == 'draft') {
        setState(() => _isDraftSaving = false);
      } else {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            child: const Text("No", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutConfirmation();
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double basePadding = screenWidth * 0.04;
    double sectionSpacing = screenHeight * 0.02;
    double contentHeight = screenHeight * 0.25;

    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await _showLogoutConfirmation();
        if (shouldLogout == true) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
                  (route) => false,
            );
          }
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: basePadding, vertical: basePadding),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Image.asset('assets/images/white_back_btn.png',
                          width: 28, height: 28),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          "New Article",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                      Icon(Icons.logout, color: Colors.white, size: screenWidth * 0.07),
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: EdgeInsets.all(basePadding),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSection(
                          label: "Article Title",
                          child:
                          _buildTextField("Enter article title...", _titleController),
                        ),
                        SizedBox(height: sectionSpacing),

                        // Category + Tags
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 500) {
                              return Column(
                                children: [
                                  _buildSection(label: "Category", child: _buildDropdown()),
                                  SizedBox(height: sectionSpacing / 2),
                                  _buildSection(label: "Tags", child: _buildTags()),
                                ],
                              );
                            } else {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child:
                                      _buildSection(label: "Category", child: _buildDropdown())),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSection(label: "Tags", child: _buildTags())),
                                ],
                              );
                            }
                          },
                        ),

                        SizedBox(height: sectionSpacing),
                        _buildSection(label: "Content", child: _buildRichEditor(contentHeight)),
                        SizedBox(height: sectionSpacing),
                        _buildSection(label: "Insert Media", child: _buildMediaUpload(contentHeight)),

                        SizedBox(height: sectionSpacing * 1.5),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isDraftSaving ? null : () => _saveArticle(status: 'draft'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: const BorderSide(color: Colors.black),
                                  foregroundColor: Colors.black,
                                ),
                                child: _isDraftSaving
                                    ? const CircularProgressIndicator()
                                    : const Text("Save a Draft"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : () => _saveArticle(status: 'pending'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text("Submit for Review", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sectionSpacing * 2),
                      ],
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

  // --- Helper Widgets ---
  Widget _buildDropdown() => DropdownButtonFormField<String>(
    decoration: _inputDecoration(),
    value: _selectedCategory,
    isExpanded: true,
    items: ['Styling Tips', 'Trends', "Do's and Don'ts"]
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: (val) => setState(() => _selectedCategory = val!),
  );

  Widget _buildTags() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTextField("Add Tag...", _tagController),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: const [
          Chip(label: Text("#casual")),
          Chip(label: Text("#winter")),
          Chip(label: Text("#outfit")),
          Chip(label: Text("#longhashtag")),
        ],
      ),
    ],
  );

  Widget _buildSection({required String label, required Widget child}) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 8),
      child,
    ]),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black),
    ),
    hintStyle: TextStyle(color: Colors.grey.shade400),
  );

  Widget _buildTextField(String hint, TextEditingController controller) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.grey),
        decoration: _inputDecoration().copyWith(hintText: hint),
      );

  Widget _buildRichEditor(double height) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.format_bold, color: _isBold ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _isBold = !_isBold),
            ),
            IconButton(
              icon: Icon(Icons.format_italic, color: _isItalic ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _isItalic = !_isItalic),
            ),
            IconButton(
              icon: Icon(Icons.format_underline, color: _isUnderline ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _isUnderline = !_isUnderline),
            ),
            IconButton(
              icon: Icon(Icons.format_list_bulleted, color: _isList ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _isList = !_isList),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.format_align_left,
                  color: _textAlign == TextAlign.left ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _textAlign = TextAlign.left),
            ),
            IconButton(
              icon: Icon(Icons.format_align_center,
                  color: _textAlign == TextAlign.center ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _textAlign = TextAlign.center),
            ),
            IconButton(
              icon: Icon(Icons.format_align_right,
                  color: _textAlign == TextAlign.right ? Colors.pink : Colors.black),
              onPressed: () => setState(() => _textAlign = TextAlign.right),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _contentController,
          maxLines: null,
          expands: true,
          textAlign: _textAlign,
          style: TextStyle(
            color: Colors.black,
            fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
          ),
          decoration: const InputDecoration.collapsed(
            hintText: 'Start writing your article...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (text) {
            if (_isList && !text.startsWith("• ")) {
              _contentController.text = "• $text";
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            }
          },
        ),
      ),
    ],
  );

  Widget _buildMediaUpload(double height) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ElevatedButton.icon(
        onPressed: _pickMedia,
        icon: const Icon(Icons.photo),
        label: const Text("Pick Image"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
      ),
      const SizedBox(height: 12),
      if (_selectedMediaBase64 != null)
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(base64Decode(_selectedMediaBase64!), fit: BoxFit.cover),
          ),
        ),
      const SizedBox(height: 8),
      TextField(
        controller: _captionController,
        style: const TextStyle(color: Colors.grey),
        decoration: _inputDecoration().copyWith(hintText: 'Add a caption...'),
      ),
    ],
  );
}
