import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../widgets/notification_card.dart';
import 'dashboard_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool showUnread = false;
  List<QueryDocumentSnapshot>? _previousDocs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                    child: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: 30,
                      width: 30,
                    ),
                  ),

                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _previousDocs = null;
                      });
                    },
                    child: const Icon(Icons.refresh, color: Colors.white, size: 28),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildToggleBar(),
                      const SizedBox(height: 12),
                      Expanded(child: _buildNotificationsList()),
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

  Widget _buildToggleBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _toggleButton("All", !showUnread, () {
              setState(() => showUnread = false);
            }),
            const SizedBox(width: 8),
            _toggleButton("Unread", showUnread, () {
              setState(() => showUnread = true);
            }),
          ],
        ),
        TextButton(
          onPressed: () {
          },
          child:
          const Text("Clear all", style: TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('articles')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _previousDocs == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _previousDocs = snapshot.data!.docs;
        }

        final docs = _previousDocs;
        if (docs == null || docs.isEmpty) {
          return const Center(
              child: Text("No new notifications",
                  style: TextStyle(color: Colors.black54)));
        }

        final now = DateTime.now();
        final today = <QueryDocumentSnapshot>[];
        final yesterday = <QueryDocumentSnapshot>[];
        final earlier = <QueryDocumentSnapshot>[];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final submittedAt =
              (data['submittedAt'] as Timestamp?)?.toDate() ?? now;
          if (_isSameDay(submittedAt, now)) {
            today.add(doc);
          } else if (_isSameDay(
              submittedAt, now.subtract(const Duration(days: 1)))) {
            yesterday.add(doc);
          } else {
            earlier.add(doc);
          }
        }

        return ListView(
          children: [
            if (today.isNotEmpty) ...[
              const Text("Today",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              ...today.map(_buildNotificationCard),
              const SizedBox(height: 20),
            ],
            if (yesterday.isNotEmpty) ...[
              const Text("Yesterday",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              ...yesterday.map(_buildNotificationCard),
              const SizedBox(height: 20),
            ],
            if (earlier.isNotEmpty) ...[
              const Text("Earlier",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              ...earlier.map(_buildNotificationCard),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled Article';
    final writerName = data['writerName'] ?? 'Unknown Writer';
    final submittedAt =
        (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 22,
              child: Icon(Icons.article, size: 22, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Article Submitted",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("$writerName submitted \"$title\" for approval.",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(_formatTime(submittedAt),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
