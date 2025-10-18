import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WriterNotificationScreen extends StatefulWidget {
  const WriterNotificationScreen({super.key});

  @override
  State<WriterNotificationScreen> createState() =>
      _WriterNotificationScreenState();
}

class _WriterNotificationScreenState extends State<WriterNotificationScreen>
    with WidgetsBindingObserver {
  bool showUnread = false;
  String? userId;
  bool isContentWriter = false;
  bool _initialLoadComplete = false;
  bool submissionAlerts = true;
  bool feedbackNotifications = false;

  StreamSubscription<QuerySnapshot>? _articleListener;
  final List<StreamSubscription> _commentListeners = [];

  final Map<String, String?> _articleStatusCache = {};
  final Set<String> _notifiedArticles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _articleListener?.cancel();
    for (var listener in _commentListeners) {
      listener.cancel();
    }
    _commentListeners.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationPreferences();
    }
  }

  Future<void> _initialize() async {
    await _loadNotificationPreferences();
    await _checkUserRole();
  }

  // ---------------- Preferences ----------------

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final newFeedback = prefs.getBool('feedbackNotifications') ?? false;
    final newSubmission = prefs.getBool('submissionAlerts') ?? true;

    setState(() {
      feedbackNotifications = newFeedback;
      submissionAlerts = newSubmission;
    });

    // If feedback notifications turned off, stop listening to comments
    if (!feedbackNotifications) {
      for (var listener in _commentListeners) {
        listener.cancel();
      }
      _commentListeners.clear();
    } else {
      // Reattach comment listeners if turned on again
      if (isContentWriter && userId != null) {
        _listenToArticleUpdates();
      }
    }
  }

  Future<void> _saveNotificationPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ---------------- User Role ----------------

  Future<void> _checkUserRole() async {
    userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;

      setState(() {
        isContentWriter = (userDoc['role'] == 'Content Writer');
      });

      if (isContentWriter) {
        _listenToArticleUpdates();
      }
    }
  }

  // ---------------- Article & Comment Listeners ----------------

  void _listenToArticleUpdates() {
    if (userId == null) return;

    _articleListener?.cancel();
    _articleListener = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('articles')
        .snapshots()
        .listen((snapshot) async {
      if (!_initialLoadComplete) _initialLoadComplete = true;

      for (var change in snapshot.docChanges) {
        final articleId = change.doc.id;
        final data = change.doc.data() as Map<String, dynamic>?;

        if (data == null) continue;
        final title = data['title'] ?? 'Untitled';
        final newStatus = data['status'] as String?;
        final oldStatus = _articleStatusCache[articleId];

        final hasStatusChanged = newStatus != null && newStatus != oldStatus;

        if (hasStatusChanged) {
          _articleStatusCache[articleId] = newStatus;

          if (submissionAlerts && newStatus != null) {
            final notificationKey = '$articleId-$newStatus';
            if (!_notifiedArticles.contains(notificationKey)) {
              _notifiedArticles.add(notificationKey);

              if (newStatus == 'approved') {
                await _createNotificationIfNotExists(
                  title: "Article Approved",
                  message:
                  "Your article '$title' has been approved and will be published soon.",
                  type: "content_approved",
                  articleId: articleId,
                );
              } else if (newStatus == 'rejected') {
                await _createNotificationIfNotExists(
                  title: "Article Rejected",
                  message:
                  "Your article '$title' was rejected. Reason: ${data['rejectionReason'] ?? 'Not specified'}.",
                  type: "content_rejected",
                  articleId: articleId,
                );
              }
            }
          }
        }

        // ✅ Attach comment listener only if feedback notifications are enabled
        if (feedbackNotifications) {
          final alreadyListening = _commentListeners
              .any((sub) => sub.hashCode == articleId.hashCode);
          if (!alreadyListening) {
            _listenToComments(articleId, title);
          }
        }
      }
    });
  }

  void _listenToComments(String articleId, String title) {
    if (!feedbackNotifications) return;

    final commentStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) async {
      if (!feedbackNotifications) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final commentText = data['text'] ?? '';
          final commenterId = data['userId'];

          String commenterName = "Someone";
          if (commenterId != null) {
            final commenterDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(commenterId)
                .get();
            if (commenterDoc.exists) {
              commenterName = commenterDoc['name'] ?? "Someone";
            }
          }

          await _createNotificationIfNotExists(
            title: "New Comment Received",
            message:
            "New comment from $commenterName on your article '$title': $commentText",
            type: "new_comment",
            articleId: articleId,
          );
        }
      }
    });

    _commentListeners.add(commentStream);
  }

  // ---------------- Notifications ----------------

  Future<void> _createNotificationIfNotExists({
    required String title,
    required String message,
    required String type,
    required String articleId,
  }) async {
    if (userId == null) return;

    // ✅ Block notification creation based on user preferences
    if (!submissionAlerts &&
        (type == "content_approved" || type == "content_rejected")) {
      return;
    }
    if (!feedbackNotifications && type == "new_comment") {
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');

    final existing = await ref
        .where('articleId', isEqualTo: articleId)
        .where('type', isEqualTo: type)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await ref.add({
      'title': title,
      'message': message,
      'type': type,
      'articleId': articleId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _clearAllNotifications() async {
    if (userId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');
    final docs = await ref.get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }

    _articleStatusCache.clear();
    _notifiedArticles.clear();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isContentWriter
            ? Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        )
            : const Center(
          child: Text(
            "Access denied! Only Content Writers can view notifications.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              "assets/images/white_back_btn.png",
              height: 30,
              width: 30,
            ),
          ),
          const Text(
            "Writer Notifications",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 26),
            onPressed: () async {
              await _loadNotificationPreferences();
              setState(() {
                _initialLoadComplete = false;
              });
              _articleListener?.cancel();
              for (var listener in _commentListeners) {
                listener.cancel();
              }
              _commentListeners.clear();
              _articleStatusCache.clear();
              _notifiedArticles.clear();
              _listenToArticleUpdates();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Container(
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
    );
  }

  Widget _buildToggleBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _toggleButton(
                "All", !showUnread, () => setState(() => showUnread = false)),
            const SizedBox(width: 8),
            _toggleButton(
                "Unread", showUnread, () => setState(() => showUnread = true)),
          ],
        ),
        TextButton(
          onPressed: _clearAllNotifications,
          child:
          const Text("Clear all", style: TextStyle(color: Colors.black54)),
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
            ? notifications
            .where((doc) => (doc['read'] ?? false) == false)
            .toList()
            : notifications;

        if (filtered.isEmpty) {
          return const Center(child: Text("No notifications"));
        }

        return ListView(children: filtered.map(_buildCardFromDoc).toList());
      },
    );
  }

  Widget _buildCardFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final icon = _iconFromType(data['type'] ?? "info");

    return GestureDetector(
      onTap: () async {
        await doc.reference.update({'read': true});
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
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
                    Text(
                      data['title'] ?? "No Title",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['message'] ?? "No message available",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    if (data['timestamp'] != null)
                      Text(
                        _formatTime(data['timestamp']),
                        style:
                        const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'new_comment':
        return Icons.comment;
      case 'content_approved':
        return Icons.check_circle;
      case 'content_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    return DateFormat.jm().format(date);
  }
}
