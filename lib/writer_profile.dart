import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'writer_login_screen.dart';

class WriterProfileScreen extends StatefulWidget {
  const WriterProfileScreen({super.key});

  @override
  State<WriterProfileScreen> createState() => _WriterProfileScreenState();
}

class _WriterProfileScreenState extends State<WriterProfileScreen> {
  String name = 'Loading...';
  String role = 'Writer';
  String birthday = 'Loading...';
  String password = ''; // password from Firestore
  String? base64Image;
  bool isLoading = true;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? 'No name';
          role = data['role'] ?? 'Writer';
          birthday = data['birthday'] ?? 'No birthday';
          password = data.containsKey('password')
              ? data['password'] ?? ''
              : 'Not stored';
          base64Image = data['image_base64'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          name = 'Profile not found';
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() {
        isLoading = false;
        name = 'Error loading profile';
      });
    }
  }

  Uint8List? _decodeBase64(String? base64String) {
    if (base64String == null) return null;
    try {
      return base64Decode(
          base64String.contains(',') ? base64String.split(',').last : base64String);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = base64Image != null
        ? MemoryImage(_decodeBase64(base64Image!)!)
        : const AssetImage("assets/images/user (1).png") as ImageProvider;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Account Details",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: Image.asset(
            "assets/images/white_back_btn.png",
            height: 28,
            width: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImage,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _profileField("Name", name),
                    _profileField("Birthday", birthday),
                    _profileField("Role", role),
                    _profileField(
                      "Password",
                      password,
                      obscureText: !isPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _profileField(String title, String value,
      {bool obscureText = false, VoidCallback? onToggleVisibility}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    obscureText ? "********" : value,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onToggleVisibility != null)
                  IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
      );
    }
  }
}
