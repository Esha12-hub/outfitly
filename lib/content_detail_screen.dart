import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'article_edit.dart';

class WriterContentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const WriterContentDetailScreen({super.key, required this.article});

  @override
  State<WriterContentDetailScreen> createState() =>
      _WriterContentDetailScreenState();
}

class _WriterContentDetailScreenState extends State<WriterContentDetailScreen> {
  final TextEditingController replyController = TextEditingController();
  String? writerId;
  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    writerId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> replyToComment(String commentId, String replyText) async {
    if (writerId == null || replyText.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(writerId)
        .collection('articles')
        .doc(widget.article['articleId'])
        .collection('comments')
        .doc(commentId)
        .update({
      'reply': replyText.trim(),
      'replyTimestamp': FieldValue.serverTimestamp(),
    });
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime time;
      if (timestamp is Timestamp) {
        time = timestamp.toDate();
      } else if (timestamp is DateTime) {
        time = timestamp;
      } else {
        return '';
      }
      return DateFormat('MMM d, yyyy • h:mm a').format(time);
    } catch (_) {
      return '';
    }
  }

  Future<String> getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final name = doc.data()?['name'] ?? 'Anonymous';
      _userNameCache[userId] = name;
      return name;
    } catch (_) {
      return 'Anonymous';
    }
  }

  Future<void> deleteArticle() async {
    if (writerId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(writerId)
        .collection('articles')
        .doc(widget.article['articleId'])
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Article deleted successfully")),
      );
      Navigator.pop(context);
    }
  }

  void showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.pink),
              const SizedBox(height: 15),
              const Text(
                "Delete Article?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to permanently delete this article? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await deleteArticle(); // Call your existing deleteArticle() method
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = (widget.article['mediaBase64'] != null &&
        widget.article['mediaBase64'].toString().isNotEmpty)
        ? base64Decode(widget.article['mediaBase64'].split(',').last)
        : null;

    final status = widget.article['status']?.toString().toLowerCase() ?? 'pending';
    final color = status == 'accepted'
        ? Colors.green
        : status == 'rejected'
        ? Colors.red
        : Colors.orange;

    final rejectionReason = widget.article['rejectionReason'] ?? '';

    final width = MediaQuery.of(context).size.width;
    final padding = width * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'My Article Details',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/white_back_btn.png",
              height: 24,
              width: 24,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(bytes,
                          width: double.infinity, height: 220, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 16),

                  // Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.article['title'] ?? '',
                          style: TextStyle(
                              fontSize: width * 0.055, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category & Date
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.article['category'] ?? '',
                            style: TextStyle(
                                color: Colors.pink, fontSize: width * 0.035)),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(formatTimestamp(widget.article['timestamp']),
                            style:
                            TextStyle(color: Colors.grey, fontSize: width * 0.03)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rejection Reason
                  if (status == 'rejected' && rejectionReason.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rejectionReason,
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: width * 0.035),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Real-time Likes Counter
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(writerId)
                        .collection('articles')
                        .doc(widget.article['articleId'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalLikes = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        totalLikes = data['likes'] ?? 0;
                      }
                      return Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.pink, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$totalLikes Likes Received',
                            style: TextStyle(color: Colors.pink, fontSize: width * 0.035),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 30),
                  const SizedBox(height: 10),

                  // Article Content
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(writerId)
                        .collection('articles')
                        .doc(widget.article['articleId'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      String content = widget.article['description'] ?? '';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        content = data['content'] ?? content;
                      }
                      return Text(
                        content,
                        style: TextStyle(fontSize: width * 0.04, height: 1.5),
                      );
                    },
                  ),
                  const Divider(height: 30),

                  const Text('Comments & Replies',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Comments Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(writerId)
                        .collection('articles')
                        .doc(widget.article['articleId'])
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No comments yet.',
                              style:
                              TextStyle(color: Colors.grey, fontSize: width * 0.035)),
                        );
                      }

                      final comments = snapshot.data!.docs;

                      return Column(
                        children: comments.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final commentText = data['text'] ?? '';
                          final reply = data['reply'] ?? '';
                          final userId = data['userId'] ?? '';
                          final timestamp = data['timestamp'];
                          final controller = TextEditingController(text: reply);

                          return FutureBuilder<String>(
                            future: getUserName(userId),
                            builder: (context, nameSnapshot) {
                              final userName = nameSnapshot.data ?? 'Anonymous';

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(commentText,
                                        style: TextStyle(
                                            fontSize: width * 0.035, height: 1.4)),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("By: $userName",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: width * 0.03)),
                                        Text(
                                          formatTimestamp(timestamp),
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: width * 0.028),
                                        ),
                                      ],
                                    ),
                                    if (reply.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        margin: const EdgeInsets.only(left: 20),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.pink.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.reply,
                                                color: Colors.pink, size: 18),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                reply,
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: width * 0.035),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        hintText: "Write a reply...",
                                        filled: true,
                                        fillColor: Colors.white,
                                        suffixIcon: IconButton(
                                          icon:
                                          const Icon(Icons.send, color: Colors.pink),
                                          onPressed: () async {
                                            await replyToComment(
                                                doc.id, controller.text.trim());
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content:
                                                  Text("Reply sent successfully")),
                                            );
                                          },
                                        ),
                                        contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide:
                                          const BorderSide(color: Colors.pinkAccent),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Edit & Delete Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArticleEditScreen(
                                  articleId: widget.article['articleId'],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            "Edit Article",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: showDeleteConfirmation,
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            "Delete Article",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
