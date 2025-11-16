import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'writer_login_screen.dart';

class ArticleEditScreen extends StatefulWidget {
  final String articleId;
  const ArticleEditScreen({Key? key, required this.articleId}) : super(key: key);

  @override
  State<ArticleEditScreen> createState() => _ArticleEditScreenState();
}

class _ArticleEditScreenState extends State<ArticleEditScreen> {
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _contentController = TextEditingController();
  final _captionController = TextEditingController();
  String _selectedCategory = 'Styling Tips';
  String? _selectedMediaBase64;
  bool _loading = true;
  bool _updating = false;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  TextAlign _textAlign = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _loadArticleData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _contentController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadArticleData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('articles')
          .doc(widget.articleId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _selectedCategory = data['category'] ?? 'Styling Tips';
          _tagController.text = data['tags'] ?? '';
          _contentController.text = data['content'] ?? '';
          _captionController.text = data['caption'] ?? '';
          String? media = data['mediaBase64'];
          if (media != null && media.contains(',')) media = media.split(',').last;
          _selectedMediaBase64 = media;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Article not found')));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading article: $e')));
    }
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedMediaBase64 = base64Encode(bytes);
    });
  }

  Future<void> _updateArticle() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _updating = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('articles')
          .doc(widget.articleId)
          .update({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'tags': _tagController.text.trim(),
        'content': _contentController.text.trim(),
        'caption': _captionController.text.trim(),
        'mediaBase64': _selectedMediaBase64,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      });

      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article updated successfully!')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _updating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating article: $e')));
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WriterLoginScreen()),
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
        await _handleLogout();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: basePadding, vertical: basePadding),
                child: Row(
                  children: [
                    IconButton(
                      icon: Image.asset('assets/images/white_back_btn.png',
                          width: 28, height: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Edit Article",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout,
                          color: Colors.white, size: screenWidth * 0.07),
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: EdgeInsets.all(basePadding),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSection("Article Title",
                            _buildTextField("Enter title...", _titleController)),
                        SizedBox(height: sectionSpacing),
                        _buildSection("Category", _buildDropdown()),
                        SizedBox(height: sectionSpacing),
                        _buildSection("Tags", _buildTags()),
                        SizedBox(height: sectionSpacing),
                        _buildSection("Content", _buildRichEditor(contentHeight)),
                        SizedBox(height: sectionSpacing),
                        _buildSection("Insert Image",
                            _buildMediaUpload(contentHeight)),
                        SizedBox(height: sectionSpacing * 1.5),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  side: const BorderSide(color: Colors.black),
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text("Save a Draft"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _updating ? null : _updateArticle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                child: _updating
                                    ? const CircularProgressIndicator(
                                    color: Colors.white)
                                    : const Text("Update Article",
                                    style: TextStyle(color: Colors.white)),
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

  Widget _buildDropdown() => DropdownButtonFormField<String>(
    decoration: _inputDecoration(),
    value: _selectedCategory,
    isExpanded: true,
    items: ['Styling Tips', 'Trends', 'Do\'s and Don\'ts']
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

  Widget _buildSection(String label, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black)),
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
                icon: Icon(Icons.format_bold,
                    color: _isBold ? Colors.pink : Colors.black),
                onPressed: () => setState(() => _isBold = !_isBold)),
            IconButton(
                icon: Icon(Icons.format_italic,
                    color: _isItalic ? Colors.pink : Colors.black),
                onPressed: () => setState(() => _isItalic = !_isItalic)),
            IconButton(
                icon: Icon(Icons.format_underline,
                    color: _isUnderline ? Colors.pink : Colors.black),
                onPressed: () => setState(() => _isUnderline = !_isUnderline)),
            const SizedBox(width: 8),
            IconButton(
                icon: Icon(Icons.format_align_left,
                    color:
                    _textAlign == TextAlign.left ? Colors.pink : Colors.black),
                onPressed: () => setState(() => _textAlign = TextAlign.left)),
            IconButton(
                icon: Icon(Icons.format_align_center,
                    color: _textAlign == TextAlign.center
                        ? Colors.pink
                        : Colors.black),
                onPressed: () => setState(() => _textAlign = TextAlign.center)),
            IconButton(
                icon: Icon(Icons.format_align_right,
                    color: _textAlign == TextAlign.right
                        ? Colors.pink
                        : Colors.black),
                onPressed: () => setState(() => _textAlign = TextAlign.right)),
            IconButton(
                icon: Icon(Icons.format_align_justify,
                    color: _textAlign == TextAlign.justify
                        ? Colors.pink
                        : Colors.black),
                onPressed: () => setState(() => _textAlign = TextAlign.justify)),
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
            decoration: _isUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
          decoration: const InputDecoration.collapsed(
            hintText: 'Start writing your article...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    ],
  );

  Widget _buildMediaUpload(double height) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ElevatedButton.icon(
        onPressed: () => _pickMedia(ImageSource.gallery),
        icon: const Icon(Icons.photo),
        label: const Text("Pick Image"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black),
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
            child: Image.memory(base64Decode(_selectedMediaBase64!),
                fit: BoxFit.cover),
          ),
        ),
      const SizedBox(height: 8),
      _buildTextField('Add a caption...', _captionController),
    ],
  );
}
