// ✅ IMPORTS
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'writer_login_screen.dart';
// ✅ LOCAL SCREENS
import 'writer_content.dart';
import 'write_article.dart';
import 'package:untitled2/User_engagement_screen.dart';
import 'writer_settings.dart';
import 'writer_notification.dart';

class WriterDashboardScreen extends StatefulWidget {
  const WriterDashboardScreen({super.key});

  @override
  State<WriterDashboardScreen> createState() => _WriterDashboardScreenState();
}

class _WriterDashboardScreenState extends State<WriterDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Home Screen')),
    WriterContentScreen(),
    WriteArticleScreen(),
    const UserEngagementAnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 👈 Handle back press
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _currentIndex == 0 ? _buildDashboard() : _pages[_currentIndex],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: _currentIndex,
          backgroundColor: Colors.white,
          color: Colors.pink,
          buttonBackgroundColor: Colors.pink,
          height: 60,
          animationDuration: const Duration(milliseconds: 300),
          items: const [
            FaIcon(FontAwesomeIcons.house, color: Colors.white),
            FaIcon(FontAwesomeIcons.chartBar, color: Colors.white),
            FaIcon(FontAwesomeIcons.clipboard, color: Colors.white),
            FaIcon(FontAwesomeIcons.chartLine, color: Colors.white),
            FaIcon(FontAwesomeIcons.gear, color: Colors.white),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  /// 🔹 Handle phone back button with logout confirmation
  Future<bool> _onWillPop() async {
    // If user is on a tab other than home, navigate to home first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // ✅ Styled logout confirmation dialog
    final shouldLogout = await showDialog<bool>(
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

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
      );
      return false;
    }

    return false;
  }

  /// 🔹 DASHBOARD UI
  Widget _buildDashboard() {
    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsGrid(),
                const SizedBox(height: 24),
                const Text(
                  'My Submissions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildSubmissionsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 TOP SECTION WITH PROFILE + NOTIFICATIONS
  Widget _buildTopSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _defaultTopBar();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _defaultTopBar();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        Uint8List? profileImageBytes;

        if (data != null &&
            data['image_base64'] != null &&
            data['image_base64'] is String) {
          try {
            profileImageBytes = base64Decode(data['image_base64'].split(',').last);
          } catch (_) {}
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                backgroundImage:
                profileImageBytes != null ? MemoryImage(profileImageBytes) : null,
                child: profileImageBytes == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WriterNotificationScreen()),
                  );
                },
                icon: const Icon(Icons.notifications, color: Colors.white, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _defaultTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          Text(
            'Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Icon(Icons.notifications_none, color: Colors.white),
        ],
      ),
    );
  }

  /// 🔹 Get total comments count across all articles
  Future<int> _getTotalCommentsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    int total = 0;

    final articlesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('articles')
        .get();

    for (var doc in articlesSnapshot.docs) {
      final commentsSnapshot = await doc.reference.collection('comments').get();
      total += commentsSnapshot.size;
    }

    return total;
  }

  /// 🔹 Stats Grid (Live Firestore Data)
  Widget _buildStatsGrid() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('articles')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final approvedCount =
            docs.where((doc) => (doc['status'] ?? '').toLowerCase() == 'approved').length;
        final pendingCount =
            docs.where((doc) => (doc['status'] ?? '').toLowerCase() == 'pending').length;

        return Column(
          children: [
            Row(
              children: [
                _StatCard(
                  title: 'Articles Published',
                  value: approvedCount.toString(),
                  icon: Icons.list_alt,
                ),
                _StatCard(
                  title: 'Pending Submissions',
                  value: pendingCount.toString(),
                  icon: Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FutureBuilder<int>(
                  future: _getTotalCommentsCount(),
                  builder: (context, snapshot) {
                    final commentCount = snapshot.data?.toString() ?? '...';
                    return _StatCard(
                      title: 'Comments Received',
                      value: commentCount,
                      icon: Icons.comment,
                    );
                  },
                ),
                const _StatCard(
                  title: 'Engagement Score',
                  value: '82%',
                  icon: Icons.bar_chart,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Submissions List
  Widget _buildSubmissionsList() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('articles')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Text('Loading...'));

        final articles = snapshot.data!.docs;

        if (articles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No articles submitted yet.'),
            ),
          );
        }

        return Column(
          children: articles.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            Uint8List? imageBytes;

            if (data['mediaBase64'] != null) {
              try {
                imageBytes = base64Decode(data['mediaBase64'].split(',').last);
              } catch (_) {}
            }

            return _SubmissionTile(
              imageBytes: imageBytes,
              title: data['title'] ?? 'Untitled',
              status: data['status'] ?? 'Unknown',
              statusColor: _getStatusColor(data['status']),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// 🔹 Individual Stat Card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Article Submission Tile
class _SubmissionTile extends StatelessWidget {
  final Uint8List? imageBytes;
  final String title;
  final String status;
  final Color statusColor;

  const _SubmissionTile({
    required this.imageBytes,
    required this.title,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageBytes != null
                ? Image.memory(imageBytes!, height: 50, width: 50, fit: BoxFit.cover)
                : Container(
              height: 50,
              width: 50,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
