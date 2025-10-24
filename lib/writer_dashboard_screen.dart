import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'writer_login_screen.dart';

import 'writer_content.dart';
import 'write_article.dart';
import 'seo_optimization.dart';
import 'writer_settings.dart';
import 'writer_notification.dart';
import 'writer_profile.dart';

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
    const SeoAnalyzerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _currentIndex == 0 ? _buildDashboard(size) : _pages[_currentIndex],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: _currentIndex,
          backgroundColor: Colors.white,
          color: Colors.pink,
          buttonBackgroundColor: Colors.pink,
          height: isSmallScreen ? 50 : 60,
          animationDuration: const Duration(milliseconds: 300),
          items: const [
            FaIcon(FontAwesomeIcons.house, color: Colors.white),
            FaIcon(FontAwesomeIcons.chartBar, color: Colors.white),
            FaIcon(FontAwesomeIcons.clipboard, color: Colors.white),
            FaIcon(FontAwesomeIcons.chartLine, color: Colors.white),
            FaIcon(FontAwesomeIcons.gear, color: Colors.white),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

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
    }

    return false;
  }

  Widget _buildDashboard(Size size) {
    return Column(
      children: [
        _buildTopSection(size),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04, vertical: size.height * 0.02),
              children: [
                _buildStatsGrid(size),
                SizedBox(height: size.height * 0.03),
                Text(
                  'My Submissions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.045,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                _buildSubmissionsList(size),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection(Size size) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _defaultTopBar(size);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _defaultTopBar(size);

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
          padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04, vertical: size.height * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WriterProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: size.width * 0.06,
                  backgroundColor: Colors.grey,
                  backgroundImage: profileImageBytes != null
                      ? MemoryImage(profileImageBytes)
                      : (data != null &&
                      data['photoUrl'] != null &&
                      data['photoUrl'] is String
                      ? NetworkImage(data['photoUrl'])
                      : null),
                  child: (profileImageBytes == null &&
                      (data == null || data['photoUrl'] == null))
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),

              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  bool hasUnread =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const WriterNotificationScreen()),
                          );
                        },
                        icon: Icon(Icons.notifications,
                            color: Colors.white, size: size.width * 0.08),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: size.width * 0.02,
                          top: size.height * 0.015,
                          child: Container(
                            height: size.width * 0.025,
                            width: size.width * 0.025,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _defaultTopBar(Size size) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04, vertical: size.height * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: size.width * 0.06,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          Text(
            'Dashboard',
            style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          Icon(Icons.notifications_none, color: Colors.white, size: size.width * 0.08),
        ],
      ),
    );
  }

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

  Future<int> _getTotalLikesCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    int totalLikes = 0;
    final articlesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('articles')
        .get();

    for (var doc in articlesSnapshot.docs) {
      final data = doc.data();
      if (data['likes'] != null && data['likes'] is int) {
        totalLikes += data['likes'] as int;
      }
    }

    return totalLikes;
  }

  Widget _buildStatsGrid(Size size) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 16) / 2;

      return Wrap(
        spacing: 8,
        runSpacing: 12,
        children: [
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('articles')
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return _StatCard(title: 'Articles Published', value: '...', icon: Icons.list_alt, width: cardWidth);

              final allArticles = snapshot.data!.docs;
              final publishedCount = allArticles.where((a) => a['status'] == 'approved').length;

              return _StatCard(title: 'Articles Published', value: publishedCount.toString(), icon: Icons.list_alt, width: cardWidth);
            },
          ),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('articles')
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return _StatCard(title: 'Pending Submissions', value: '...', icon: Icons.schedule, width: cardWidth);

              final allArticles = snapshot.data!.docs;
              final pendingCount = allArticles.where((a) => a['status'] == 'pending').length;

              return _StatCard(title: 'Pending Submissions', value: pendingCount.toString(), icon: Icons.schedule, width: cardWidth);
            },
          ),
          FutureBuilder<int>(
            future: _getTotalCommentsCount(),
            builder: (context, snapshot) {
              return _StatCard(
                title: 'Comments Received',
                value: snapshot.hasData ? snapshot.data.toString() : '...',
                icon: Icons.comment,
                width: cardWidth,
              );
            },
          ),
          FutureBuilder<int>(
            future: _getTotalLikesCount(),
            builder: (context, snapshot) {
              return _StatCard(
                title: 'Total Likes',
                value: snapshot.hasData ? snapshot.data.toString() : '...',
                icon: Icons.favorite,
                width: cardWidth,
              );
            },
          ),
        ],
      );
    });
  }


  Widget _buildSubmissionsList(Size size) {
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
          return Center(
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: const Text('No articles submitted yet.'),
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
              height: size.height * 0.1,
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

/// 🔹 Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double width;

  const _StatCard(
      {required this.title, required this.value, required this.icon, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final Uint8List? imageBytes;
  final String title;
  final String status;
  final Color statusColor;
  final double height;

  const _SubmissionTile({
    required this.imageBytes,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
                ? Image.memory(imageBytes!, height: height * 0.7, width: height * 0.7, fit: BoxFit.cover)
                : Container(
              height: height * 0.7,
              width: height * 0.7,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
          SizedBox(width: height * 0.2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Reduced Title Font Size
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: height * 0.22, // Previously 0.25
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: height * 0.05),

                /// 🔹 Reduced Status Font Size
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: height * 0.16, // Previously 0.18
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: height * 0.25), // Slightly smaller arrow
        ],
      ),
    );
  }
}
