import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeProfileImageScreen extends StatefulWidget {
  const ChangeProfileImageScreen({super.key});

  @override
  State<ChangeProfileImageScreen> createState() =>
      _ChangeProfileImageScreenState();
}

class _ChangeProfileImageScreenState extends State<ChangeProfileImageScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _imageBytes == null) return;

    setState(() => _isLoading = true);
    try {
      final base64Image = base64Encode(_imageBytes!);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'image_base64': base64Image,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating image: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              SizedBox(height: height * 0.06),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: width * 0.07,
                          width: width * 0.07,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Change Profile Image",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0,
                      child: IconButton(
                        onPressed: () {},
                        icon: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: width * 0.07,
                          width: width * 0.07,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.02),

              // Main Container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: height * 0.04,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          "Upload a new profile photo",
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.04),

                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: width * 0.22,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : null,
                            child: _imageBytes == null
                                ? Icon(
                              Icons.add_a_photo,
                              size: width * 0.12,
                              color: Colors.black54,
                            )
                                : null,
                          ),
                        ),

                        SizedBox(height: height * 0.05),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade600,
                            minimumSize: Size.fromHeight(height * 0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}
