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
  String email = 'Loading...';
  String createdAt = 'Loading...';
  String status = 'Loading...';
  String? base64Image;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? 'No name';
          role = data['role'] ?? 'Writer';
          birthday = data['birthday'] ?? 'No birthday';
          email = user.email ?? 'No email';
          createdAt = data.containsKey('createdAt')
              ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]
              : data['createdAt'].toString())
              : 'N/A';
          status = data['status'] ?? 'N/A';
          base64Image = data['image_base64'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          name = 'Profile not found';
          email = user.email ?? 'No email';
          createdAt = 'N/A';
          status = 'N/A';
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() {
        isLoading = false;
        name = 'Error loading profile';
        email = user.email ?? 'No email';
        createdAt = 'N/A';
        status = 'N/A';
      });
    }
  }

  Uint8List? _decodeBase64(String? base64String) {
    if (base64String == null) return null;
    try {
      return base64Decode(base64String.contains(',') ? base64String.split(',').last : base64String);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    ImageProvider profileImage;
    if (base64Image != null && base64Image!.isNotEmpty) {
      final bytes = _decodeBase64(base64Image!);
      profileImage = MemoryImage(bytes!);
    } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      profileImage = NetworkImage(user.photoURL!);
    } else {
      profileImage = const AssetImage("assets/images/user (1).png");
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Account Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
          SizedBox(height: height * 0.02),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: height * 0.02,
              ),
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
                      radius: width * 0.15,
                      backgroundImage: profileImage,
                    ),
                    SizedBox(height: height * 0.015),
                    FittedBox(
                      child: Text(
                        name,
                        style: TextStyle(fontSize: width * 0.06, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    FittedBox(
                      child: Text(
                        role,
                        style: TextStyle(fontSize: width * 0.04, color: Colors.black54),
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                    _profileField("Name", name, width: width),
                    _profileField("Birthday", birthday, width: width),
                    _profileField("Email", email, width: width),
                    _profileField("Role", role, width: width),
                    _profileField("Created At", createdAt, width: width),
                    _profileField("Status", status, width: width),
                    SizedBox(height: height * 0.03),
                    ElevatedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: EdgeInsets.symmetric(
                          vertical: height * 0.018,
                          horizontal: width * 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: Size(double.infinity, height * 0.065),
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

  static Widget _profileField(String title, String value, {required double width}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: width * 0.02),
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.035),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: width * 0.04),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
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
