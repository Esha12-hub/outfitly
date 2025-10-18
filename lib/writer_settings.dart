import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'writer_login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool feedbackNotifications = false;
  bool submissionAlerts = true;
  bool twoFactorAuth = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  children: [
                    _buildSearchBar(),
                    _buildUserProfileTile(),
                    const SizedBox(height: 20),

                    /// Account Section
                    _buildSectionTitle('ACCOUNT SETTINGS'),
                    _buildTile(Icons.email, 'Email/Phone Number Details'),
                    _buildTile(Icons.lock, 'Change Password'),
                    _buildTile(Icons.delete, 'Delete Profile'),
                    const SizedBox(height: 20),

                    /// Content Preferences
                    _buildSectionTitle('CONTENT PREFERENCES'),
                    _buildTile(Icons.language, 'Language',
                        trailingText: 'English'),
                    _buildTile(Icons.access_time, 'Timezone',
                        trailingText: '(GMT+0) UTC'),
                    const SizedBox(height: 20),

                    /// Notifications
                    _buildSectionTitle('NOTIFICATIONS'),
                    _buildToggleTile(Icons.feedback, 'Feedback Notifications',
                        feedbackNotifications, (val) {
                          setState(() => feedbackNotifications = val);
                        }),
                    _buildToggleTile(Icons.notifications_active,
                        'Submission Alerts', submissionAlerts, (val) {
                          setState(() => submissionAlerts = val);
                        }),
                    const SizedBox(height: 20),

                    /// Privacy
                    _buildSectionTitle('PRIVACY AND SECURITY'),
                    _buildToggleTile(Icons.security, '2-Factor Authentication',
                        twoFactorAuth, (val) {
                          setState(() => twoFactorAuth = val);
                        }),
                    const SizedBox(height: 20),

                    /// About
                    _buildSectionTitle('ABOUT APP'),
                    _buildTile(Icons.menu_book, 'Terms of Use'),
                    _buildTile(Icons.info_outline, 'About App'),

                    /// Logout
                    const SizedBox(height: 5),
                    _buildTile(Icons.logout, 'Logout', onTap: _confirmLogout),

                    const SizedBox(height: 20),
                    const Center(
                        child: Text("Version 1.1.1",
                            style: TextStyle(
                                fontSize: 12, color: Colors.black54))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------ UI COMPONENTS ------------------ ///

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const Center(
            child: Text(
              "Settings",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search),
          hintText: "Search...",
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// ✅ Fetch user info & base64 image from Firestore
  Widget _buildUserProfileTile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("User data not found");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'User Name';
        final email = data['email'] ?? '';
        final imageBase64 = data['image_base64'];

        Widget avatar;
        if (imageBase64 != null &&
            imageBase64.isNotEmpty &&
            imageBase64 is String) {
          try {
            final bytes = base64Decode(imageBase64.split(',').last);
            avatar =
                CircleAvatar(radius: 26, backgroundImage: MemoryImage(bytes));
          } catch (_) {
            avatar = _buildFallbackAvatar(name);
          }
        } else {
          avatar = _buildFallbackAvatar(name);
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.grey.shade400,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTile(IconData icon, String title,
      {String? trailingText, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, overflow: TextOverflow.ellipsis),
        trailing: trailingText != null
            ? Text(trailingText,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold))
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleTile(
      IconData icon, String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.black),
        title: Text(title, overflow: TextOverflow.ellipsis),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.pink,
      ),
    );
  }

  /// ------------------ LOGOUT ------------------ ///
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
        );
      }
    }
  }
}
