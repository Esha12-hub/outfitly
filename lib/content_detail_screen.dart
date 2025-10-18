import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WriterContentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const WriterContentDetailScreen({super.key, required this.article});

  @override
  State<WriterContentDetailScreen> createState() => _WriterContentDetailScreenState();
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final name = doc.data()?['name'] ?? 'Anonymous';
      _userNameCache[userId] = name;
      return name;
    } catch (_) {
      return 'Anonymous';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'My Article Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bytes != null)
              Image.memory(bytes, width: double.infinity, height: 220, fit: BoxFit.cover),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.article['title'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                  // 🔹 Category & Date
                  Row(
                    children: [
                      Text(widget.article['category'] ?? '',
                          style: const TextStyle(color: Colors.pink, fontSize: 14)),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(formatTimestamp(widget.article['timestamp']),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Real-time Likes Counter
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(writerId)
                        .collection('articles')
                        .doc(widget.article['articleId'])
                        .collection('likes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('0 Likes Received',
                            style: TextStyle(color: Colors.pink, fontSize: 14));
                      }
                      final totalLikes = snapshot.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.pink, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$totalLikes Likes Received',
                            style: const TextStyle(color: Colors.pink, fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),

                  const Divider(height: 30),

                  const Text('Styling Tips',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    widget.article['description'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const Divider(height: 30),

                  const Text('Comments & Replies',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // 🔹 Comments Stream
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No comments yet.',
                              style: TextStyle(color: Colors.grey)),
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
                                        style: const TextStyle(fontSize: 15, height: 1.4)),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("By: $userName",
                                            style: const TextStyle(
                                                color: Colors.grey, fontSize: 12)),
                                        Text(
                                          formatTimestamp(timestamp),
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 11),
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
                                                style: const TextStyle(
                                                    color: Colors.black87, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 10),

                                    // 🔹 Reply Field
                                    TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        hintText: "Write a reply...",
                                        filled: true,
                                        fillColor: Colors.white,
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.send,
                                              color: Colors.pink),
                                          onPressed: () async {
                                            await replyToComment(
                                                doc.id, controller.text.trim());
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text("Reply sent successfully")),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
