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
  bool _loading = true; // 🔹 Loading state added

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

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final newFeedback = prefs.getBool('feedbackNotifications') ?? false;
    final newSubmission = prefs.getBool('submissionAlerts') ?? true;

    setState(() {
      feedbackNotifications = newFeedback;
      submissionAlerts = newSubmission;
    });

    if (!feedbackNotifications) {
      for (var listener in _commentListeners) {
        listener.cancel();
      }
      _commentListeners.clear();
    } else {
      if (isContentWriter && userId != null) {
        _listenToArticleUpdates();
      }
    }
  }

  Future<void> _saveNotificationPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

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
        _loading = false; // 🔹 Finished loading
      });

      if (isContentWriter) {
        _listenToArticleUpdates();
      }
    } else {
      setState(() {
        _loading = false; // 🔹 Done loading even if no user
      });
    }
  }

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

  Future<void> _createNotificationIfNotExists({
    required String title,
    required String message,
    required String type,
    required String articleId,
  }) async {
    if (userId == null) return;

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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final fontSize = screenWidth * 0.05;
    final iconSize = screenWidth * 0.06;
    final backBtnSize = screenWidth * 0.07;

    // 🔹 Show loader while determining role
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isContentWriter
            ? Column(
          children: [
            _buildHeader(fontSize, backBtnSize, iconSize),
            Expanded(
                child: _buildBody(screenWidth, screenHeight, fontSize)),
          ],
        )
            : Center(
          child: Text(
            "Access denied! Only Content Writers can view notifications.",
            style: TextStyle(color: Colors.white, fontSize: fontSize),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double fontSize, double backBtnSize, double iconSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: backBtnSize * 0.5, vertical: backBtnSize * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              "assets/images/white_back_btn.png",
              height: backBtnSize,
              width: backBtnSize,
            ),
          ),
          Text(
            "Writer Notifications",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: iconSize),
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

  Widget _buildBody(double screenWidth, double screenHeight, double fontSize) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            _buildToggleBar(fontSize),
            SizedBox(height: screenHeight * 0.015),
            Expanded(child: _buildNotificationList(fontSize, screenWidth)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBar(double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _toggleButton(
                "All", !showUnread, () => setState(() => showUnread = false), fontSize),
            SizedBox(width: fontSize * 0.5),
            _toggleButton(
                "Unread", showUnread, () => setState(() => showUnread = true), fontSize),
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

  Widget _toggleButton(
      String label, bool selected, VoidCallback onTap, double fontSize) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: fontSize * 0.35),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD71D5C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: fontSize * 0.85,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(double fontSize, double screenWidth) {
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('articles')
          .snapshots(),
      builder: (context, articleSnapshot) {
        if (articleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final articles = articleSnapshot.data?.docs ?? [];

        if (articles.isEmpty) {
          return Center(
            child: Text(
              "No articles published yet",
              style: TextStyle(color: Colors.black54, fontSize: fontSize * 0.8),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, notifSnapshot) {
            if (notifSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allNotifs = notifSnapshot.data?.docs ?? [];

            // Filter notifications based on user settings
            final filtered = allNotifs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? '';
              if (!feedbackNotifications && type == 'new_comment') return false;
              if (!submissionAlerts &&
                  (type == 'content_approved' || type == 'content_rejected')) {
                return false;
              }
              if (showUnread && (data['read'] ?? true)) return false;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  "No notifications",
                  style: TextStyle(color: Colors.black54, fontSize: fontSize * 0.8),
                ),
              );
            }

            return ListView(
              children: filtered
                  .map((doc) => _buildCardFromDoc(doc, fontSize, screenWidth))
                  .toList(),
            );
          },
        );
      },
    );
  }


  Widget _buildCardFromDoc(QueryDocumentSnapshot doc, double fontSize, double screenWidth) {
    final data = doc.data() as Map<String, dynamic>;
    final icon = _iconFromType(data['type'] ?? "info");
    final iconSize = screenWidth * 0.12;

    return GestureDetector(
      onTap: () async {
        await doc.reference.update({'read': true});
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: fontSize * 0.7),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(fontSize * 0.7),
          ),
          padding: EdgeInsets.all(fontSize * 0.7),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: iconSize * 0.45,
                child: Icon(icon, size: iconSize * 0.45, color: Colors.black),
              ),
              SizedBox(width: fontSize * 0.6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "No Title",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: fontSize * 0.75),
                    ),
                    SizedBox(height: fontSize * 0.2),
                    Text(
                      data['message'] ?? "No message available",
                      style: TextStyle(
                          fontSize: fontSize * 0.6, color: Colors.black54),
                    ),
                    SizedBox(height: fontSize * 0.2),
                    if (data['timestamp'] != null)
                      Text(
                        _formatTime(data['timestamp']),
                        style: TextStyle(fontSize: fontSize * 0.55, color: Colors.grey),
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
