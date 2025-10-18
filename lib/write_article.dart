import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WriteArticleScreen extends StatefulWidget {
  const WriteArticleScreen({super.key});

  @override
  State<WriteArticleScreen> createState() => _WriteArticleScreenState();
}

class _WriteArticleScreenState extends State<WriteArticleScreen> {
  String _selectedCategory = 'Styling Tips';
  String? _selectedMediaBase64;
  bool _isVideo = false;

  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _contentController = TextEditingController();
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _contentController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, bool isImage) async {
    final picker = ImagePicker();
    final pickedFile = await (isImage
        ? picker.pickImage(source: source)
        : picker.pickVideo(source: source));

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    setState(() {
      _selectedMediaBase64 = base64String;
      _isVideo = !isImage;
    });
  }

  Future<void> _submitArticle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in.")));
      return;
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
        'isVideo': _isVideo,
        'caption': _captionController.text.trim(),
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Article submitted!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset("assets/images/white_back_btn.png", height: 30, width: 30),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "New Article",
                        style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSection(
                        label: "Article Title",
                        child: _buildTextField("Enter article title...", _titleController),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSection(
                              label: "Category",
                              child: DropdownButtonFormField<String>(
                                decoration: _inputDecoration(),
                                value: _selectedCategory,
                                isExpanded: true,
                                items: ['Styling Tips', 'Trends', 'Do\'s and Don\'ts']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedCategory = val!);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSection(
                              label: "Tags",
                              child: Column(
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(label: "Content", child: _buildRichEditor()),
                      const SizedBox(height: 16),
                      _buildSection(label: "Insert Media", child: _buildMediaUpload()),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Draft saved (not implemented)')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: Colors.black),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Save a Draft"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitArticle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Submit for Review", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildSection({required String label, required Widget child}) {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

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

  Widget _buildTextField(String hint, TextEditingController controller) => TextField(
    controller: controller,
    style: const TextStyle(color: Colors.grey),
    decoration: _inputDecoration().copyWith(hintText: hint),
  );

  Widget _buildRichEditor() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: const [
          Icon(Icons.format_bold),
          SizedBox(width: 8),
          Icon(Icons.format_italic),
          SizedBox(width: 8),
          Icon(Icons.format_underline),
          SizedBox(width: 8),
          Icon(Icons.format_list_bulleted),
          SizedBox(width: 8),
          Icon(Icons.format_align_left),
          Spacer(),
          Icon(Icons.lightbulb),
          SizedBox(width: 4),
          Text("Add Style Tip"),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        height: 150,
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
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration.collapsed(
            hintText: 'Start writing your article...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    ],
  );

  Widget _buildMediaUpload() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _pickMedia(ImageSource.gallery, true),
              icon: const Icon(Icons.photo),
              label: const Text("Pick Image"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _pickMedia(ImageSource.gallery, false),
              icon: const Icon(Icons.videocam),
              label: const Text("Pick Video"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_selectedMediaBase64 != null)
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _isVideo
              ? const Center(child: Text("Video selected")) // You can replace with a video thumbnail widget.
              : ClipRRect(
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
