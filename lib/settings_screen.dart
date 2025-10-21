import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'manage_permissions_screen.dart';
import 'about_us_screen.dart';
import 'verify_email_user.dart';
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

          // Load season-based filtering from Firestore
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black)),

          // Main content
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Tile
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: profilePhotoBytes != null
                                  ? MemoryImage(profilePhotoBytes!)
                                  : const AssetImage('assets/images/user (1).png') as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Text(
                                    "Google Account, Apple ID & Wardrobe Details",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Settings
                    _sectionTitle("ACCOUNT SETTINGS"),
                    _iconTile(Icons.lock, "Change Password", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
                      );
                    }),
                    _iconTile(Icons.delete_forever, "Delete Profile", onTap: () {
                      _showDeleteConfirmationDialog();
                    }),

                    const SizedBox(height: 24),

                    // Wardrobe Preferences
                    _sectionTitle("WARDROBE PREFERENCES"),
                    _toggleTile(Icons.wb_sunny, "Season-Based Filtering", seasonBasedFiltering,
                            (val) {
                          setState(() => seasonBasedFiltering = val);
                          _updatePreference('seasonBasedFiltering', val);
                          
                        }),


                    const SizedBox(height: 24),

                    // Notifications
                    _sectionTitle("NOTIFICATIONS"),
                    _toggleTile(Icons.checkroom, "Outfit Suggestions", outfitSuggestions, (val) {
                      setState(() => outfitSuggestions = val);
                      _updatePreference('outfitSuggestions', val);
                    }),
                    _toggleTile(Icons.shopping_bag, "Shopping Recommendations", shoppingRecommendations,
                            (val) {
                          setState(() => shoppingRecommendations = val);
                          _updatePreference('shoppingRecommendations', val);
                        }),

                    const SizedBox(height: 24),

                    // Privacy & Security
                    _sectionTitle("PRIVACY AND SECURITY"),
                    _toggleTile(Icons.lock_outline, "App Lock", appLock, (val) {
                      setState(() => appLock = val);
                      _updatePreference('appLock', val);
                    }),
                    _iconTile(Icons.shield, "Manage Permissions", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManagePermissionsScreen()),
                      );
                    }),

                    const SizedBox(height: 24),

                    // About App
                    _sectionTitle("ABOUT APP"),
                    _iconTile(Icons.book, "Terms of Use", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                      );
                    }),
                    _iconTile(Icons.warning_amber_outlined, "About App", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                      );
                    }),
                    _iconTile(Icons.smart_toy_outlined, "User Support", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SmartAssistantWelcomeScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: 30,
                      width: 30,
                    ),
                  ),
                ),
                const Text(
                  "Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile(IconData icon, String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
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
