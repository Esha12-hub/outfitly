import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'manage_permissions_screen.dart';
import 'about_us_screen.dart';
import 'user_profile_screen.dart';
import 'smart_assistant_welcome.dart';
import 'terms.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool seasonBasedFiltering = false;
  bool occasionTags = true;
  bool outfitSuggestions = false;
  bool shoppingRecommendations = true;
  bool appLock = true;

  String username = "User Name";
  Uint8List? profilePhotoBytes;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          username = data['name'] ?? "User Name";
          final base64Image = data['image_base64'];
          if (base64Image != null) {
            profilePhotoBytes = base64Decode(
              base64Image.contains(',') ? base64Image.split(',').last : base64Image,
            );
          }
          seasonBasedFiltering = data['seasonBasedFiltering'] ?? false;
          occasionTags = data['occasionTags'] ?? true;
          outfitSuggestions = data['outfitSuggestions'] ?? false;
          shoppingRecommendations = data['shoppingRecommendations'] ?? true;
          appLock = data['appLock'] ?? true;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _updatePreference(String field, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        field: value,
      });
    } catch (e) {
      print("Error updating $field: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height / 812; // base iPhone X height
    final w = size.width / 375; // base width

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.black)),

              // Main content
              Positioned(
                top: 140 * h,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28 * w),
                      topRight: Radius.circular(28 * w),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16 * w, 20 * h, 16 * w, 16 * h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 * w, vertical: 4 * h),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20 * w),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: InputBorder.none,
                              icon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        SizedBox(height: 20 * h),

                        // Profile Tile
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UserProfileScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16 * w),
                          child: Container(
                            padding: EdgeInsets.all(12 * w),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16 * w),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28 * w,
                                  backgroundImage: profilePhotoBytes != null
                                      ? MemoryImage(profilePhotoBytes!)
                                      : const AssetImage('assets/images/user (1).png')
                                  as ImageProvider,
                                ),
                                SizedBox(width: 12 * w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16 * w,
                                        ),
                                      ),
                                      Text(
                                        "Google Account, Apple ID & Wardrobe Details",
                                        style: TextStyle(fontSize: 12 * w),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16 * w),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24 * h),

                        _sectionTitle("ACCOUNT SETTINGS", w),
                        _iconTile(Icons.lock, "Change Password", w, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChangePasswordScreen()),
                          );
                        }),
                        _iconTile(Icons.delete_forever, "Delete Profile", w,
                            onTap: () {
                              _showDeleteConfirmationDialog();
                            }),

                        SizedBox(height: 24 * h),

                        _sectionTitle("WARDROBE PREFERENCES", w),
                        _toggleTile(Icons.wb_sunny, "Season-Based Filtering",
                            seasonBasedFiltering, (val) {
                              setState(() => seasonBasedFiltering = val);
                              _updatePreference('seasonBasedFiltering', val);
                            }, w),

                        SizedBox(height: 24 * h),

                        _sectionTitle("NOTIFICATIONS", w),
                        _toggleTile(Icons.checkroom, "Outfit Suggestions",
                            outfitSuggestions, (val) {
                              setState(() => outfitSuggestions = val);
                              _updatePreference('outfitSuggestions', val);
                            }, w),
                        _toggleTile(
                            Icons.shopping_bag,
                            "Shopping Recommendations",
                            shoppingRecommendations, (val) {
                          setState(() => shoppingRecommendations = val);
                          _updatePreference('shoppingRecommendations', val);
                        }, w),

                        SizedBox(height: 24 * h),

                        _sectionTitle("PRIVACY AND SECURITY", w),

                        _iconTile(Icons.shield, "Manage Permissions", w,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ManagePermissionsScreen()),
                              );
                            }),

                        SizedBox(height: 24 * h),

                        _sectionTitle("ABOUT APP", w),
                        _iconTile(Icons.book, "Terms of Use", w, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TermsOfUseScreen()),
                          );
                        }),
                        _iconTile(Icons.warning_amber_outlined, "About App", w,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AboutUsScreen()),
                              );
                            }),
                        _iconTile(Icons.smart_toy_outlined, "User Support", w,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                    const SmartAssistantWelcomeScreen()),
                              );
                            }),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Bar
              Positioned(
                top: 60 * h,
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 16 * w,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          "assets/images/white_back_btn.png",
                          height: 30 * w,
                          width: 30 * w,
                        ),
                      ),
                    ),
                    Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22 * w,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, double w) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * w),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14 * w,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, String title, double w, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * w),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6 * w),
        padding: EdgeInsets.symmetric(vertical: 14 * w, horizontal: 16 * w),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16 * w),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20 * w, color: Colors.black),
            SizedBox(width: 16 * w),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14 * w))),
            Icon(Icons.arrow_forward_ios, size: 14 * w),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile(
      IconData icon, String title, bool value, Function(bool) onChanged, double w) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6 * w),
      padding: EdgeInsets.symmetric(vertical: 10 * w, horizontal: 16 * w),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16 * w),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20 * w, color: Colors.black),
          SizedBox(width: 16 * w),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14 * w))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.pink,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Confirm Deletion",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "No",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account deletion not implemented yet")),
    );
  }
}
