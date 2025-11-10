import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool showUnread = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      _checkAndNotifyMissingItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset("assets/images/white_back_btn.png",
                        height: 30, width: 30),
                  ),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  // Icon with red dot
                  Stack(
                    children: [
                      const Icon(Icons.tune, color: Colors.white, size: 28),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('notifications')
                              .where('read', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final unreadCount = snapshot.data!.docs.length;
                            return unreadCount > 0
                                ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            )
                                : const SizedBox();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
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
                      Expanded(child: _buildNotificationList()),
                    ],
                  ),
                ),
              ),
            )
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
            _toggleButton("All", !showUnread, () => setState(() => showUnread = false)),
            const SizedBox(width: 8),
            _toggleButton("Unread", showUnread, () => setState(() => showUnread = true)),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: _clearAllNotifications,
              child: const Text("Clear all", style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: _addTestNotification,
              child: const Text("Add Test", style: TextStyle(color: Colors.black54)),
            ),
          ],
        )
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD71D5C) : Colors.grey.shade200,
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

  Widget _buildNotificationList() {
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data?.docs ?? [];
        final filtered = showUnread
            ? notifications.where((doc) => doc['read'] != true).toList()
            : notifications;

        if (filtered.isEmpty) {
          return const Center(child: Text("No notifications"));
        }

        final now = DateTime.now();
        final today = <QueryDocumentSnapshot>[];
        final yesterday = <QueryDocumentSnapshot>[];
        final earlier = <QueryDocumentSnapshot>[];

        for (var doc in filtered) {
          final ts = (doc['timestamp'] as Timestamp?)?.toDate();
          if (ts == null) continue;

          if (_isSameDay(ts, now)) {
            today.add(doc);
          } else if (_isSameDay(ts, now.subtract(const Duration(days: 1)))) {
            yesterday.add(doc);
          } else {
            earlier.add(doc);
          }
        }

        return ListView(
          children: [
            if (today.isNotEmpty) ...[
              const Text("Today", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...today.map(_buildCardFromDoc),
              const SizedBox(height: 20),
            ],
            if (yesterday.isNotEmpty) ...[
              const Text("Yesterday", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...yesterday.map(_buildCardFromDoc),
              const SizedBox(height: 20),
            ],
            if (earlier.isNotEmpty) ...[
              const Text("Earlier", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...earlier.map(_buildCardFromDoc),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCardFromDoc(QueryDocumentSnapshot doc) {
    final iconStr = doc['icon'] ?? "info";
    final icon = _iconFromString(iconStr);
    return GestureDetector(
      onTap: () async {
        await doc.reference.update({'read': true});
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _notificationCard(
          icon: icon,
          title: doc['title'] ?? "",
          subtitle: doc['message'] ?? "",
          time: _formatTime(doc['timestamp']),
        ),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 22,
            child: Icon(icon, size: 22, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case "laundry":
        return Icons.local_laundry_service;
      case "shopping":
        return Icons.shopping_cart;
      case "ai":
        return Icons.smart_toy;
      case "style":
        return Icons.style;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    return DateFormat.jm().format(date);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _clearAllNotifications() async {
    final ref = FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications');
    final docs = await ref.get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _addTestNotification() async {
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Sample Notification',
      'message': 'This is a test message',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'icon': 'style',
    });
    print("✅ Test notification added");
  }

  Future<void> _checkAndNotifyMissingItems() async {
    final wardrobeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wardrobe');

    try {
      final snapshot = await wardrobeRef.get();

      if (snapshot.docs.isEmpty) {
        await _addNotificationOnce(
          type: 'empty_wardrobe',
          title: 'Wardrobe Empty',
          message: 'Add some clothes to your wardrobe!',
        );
        return;
      }

      bool hasTop = false;
      bool hasBottom = false;
      bool hasWrap = false;
      bool hasShoes = false;

      for (var doc in snapshot.docs) {
        final categoryRaw = doc['category']?.toString().toLowerCase().trim();
        final subcategoryRaw = doc['subcategory']?.toString().toLowerCase().trim();

        if (categoryRaw == null && subcategoryRaw == null) continue;

        if (['shirt', 'kurti', 'blouse', 'top'].contains(categoryRaw) ||
            ['shirt', 'kurti', 'blouse', 'top'].contains(subcategoryRaw)) {
          hasTop = true;
        }

        if (['trouser', 'jeans', 'shalwar', 'pants'].contains(categoryRaw) ||
            ['trouser', 'jeans', 'shalwar', 'pants'].contains(subcategoryRaw)) {
          hasBottom = true;
        }

        if (['dupatta', 'scarf', 'wrap'].contains(categoryRaw) ||
            ['dupatta', 'scarf', 'wrap'].contains(subcategoryRaw)) {
          hasWrap = true;
        }

        if (['shoes', 'sneakers', 'sandals'].contains(categoryRaw) ||
            ['shoes', 'sneakers', 'sandals'].contains(subcategoryRaw)) {
          hasShoes = true;
        }
      }

      if (hasTop && !hasBottom) {
        await _addNotificationOnce(
          type: 'missing_bottom',
          title: 'Missing Trouser',
          message: 'You added shirts but no trousers in your wardrobe!',
        );
      }

      if (hasTop && !hasWrap) {
        await _addNotificationOnce(
          type: 'missing_wrap',
          title: 'Missing Dupatta',
          message: 'You added shirts but no dupattas or wraps in your wardrobe!',
        );
      }

      if (hasBottom && hasWrap && !hasTop) {
        await _addNotificationOnce(
          type: 'missing_top',
          title: 'Missing Shirt',
          message: 'You added trousers and dupatta but no shirts in your wardrobe!',
        );
      }

      if (!hasShoes) {
        await _addNotificationOnce(
          type: 'missing_shoes',
          title: 'Missing Shoes',
          message: 'You have no shoes in your wardrobe!',
        );
      }
    } catch (e) {
      print("❌ Error checking wardrobe items: $e");
    }
  }


  Future<void> _addNotificationOnce({
    required String type,
    required String title,
    required String message,
  }) async {
    final notifRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');

    final exists = await notifRef.where('type', isEqualTo: type).get();
    if (exists.docs.isEmpty) {
      await notifRef.add({
        'title': title,
        'message': message,
        'timestamp': Timestamp.now(),
        'read': false,
        'icon': 'style',
        'type': type,
      });
      print("✅ Notification added: $title");
    }
  }
}
