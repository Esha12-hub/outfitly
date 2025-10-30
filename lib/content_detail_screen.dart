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
  String? writerId;

  /// ✅ Cache user data (name, photoUrl, base64)
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    writerId = FirebaseAuth.instance.currentUser?.uid;
  }

  /// ✅ Add reply to a specific comment
  Future<void> replyToComment(String commentId, String replyText) async {
    if (writerId == null || replyText.trim().isEmpty) return;

    final replyData = {
      'replyText': replyText.trim(),
      'replyUserId': writerId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(writerId)
        .collection('articles')
        .doc(widget.article['articleId'])
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add(replyData);
  }

  /// ✅ Format Firestore Timestamp or DateTime
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

  /// ✅ Fetch and cache user data
  Future<Map<String, dynamic>> getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = doc.data() ?? {};
      final name = data['name'] ?? 'Anonymous';
      final photoUrl = data['photoUrl'] ?? '';
      final imageBase64 = data['image_base64'] ?? '';

      final userData = {
        'name': name,
        'photoUrl': photoUrl,
        'image_base64': imageBase64,
      };

      _userCache[userId] = userData;
      return userData;
    } catch (_) {
      final fallback = {
        'name': 'Anonymous',
        'photoUrl': '',
        'image_base64': '',
      };
      _userCache[userId] = fallback;
      return fallback;
    }
  }

  /// ✅ Delete article with confirmation
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
      await deleteArticle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = (widget.article['mediaBase64'] != null &&
        widget.article['mediaBase64'].toString().isNotEmpty)
        ? base64Decode(widget.article['mediaBase64'].split(',').last)
        : null;

    final status =
        widget.article['status']?.toString().toLowerCase() ?? 'pending';
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
              height: 20,
              width: 20,
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
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 16),

                  /// Title + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.article['title'] ?? '',
                          style: TextStyle(
                              fontSize: width * 0.055,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  /// Category + Date
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
                            style: TextStyle(
                                color: Colors.grey, fontSize: width * 0.03)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// Rejection Reason
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
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rejectionReason,
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: width * 0.035),
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// Likes
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
                        final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                        totalLikes = data['likes'] ?? 0;
                      }
                      return Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.pink, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$totalLikes Likes Received',
                            style: TextStyle(
                                color: Colors.pink, fontSize: width * 0.035),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 30),
                  const SizedBox(height: 10),

                  /// Article Description
                  Text(
                    widget.article['content'] ?? '',
                    style: TextStyle(fontSize: width * 0.04, height: 1.5),
                  ),

                  const Divider(height: 30),
                  const Text('Comments & Replies',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  /// Comments List
                  /// Comments List
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
                              style: TextStyle(color: Colors.grey, fontSize: width * 0.035)),
                        );
                      }

                      final comments = snapshot.data!.docs;

                      return Column(
                        children: comments.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final commentText = data['text'] ?? '';
                          final userId = data['userId'] ?? '';
                          final timestamp = data['timestamp'];
                          final likes = List<String>.from(data['likedBy'] ?? []);
                          final isLiked = likes.contains(writerId);
                          bool showReplyField = false;
                          final replyController = TextEditingController();

                          return StatefulBuilder(
                            builder: (context, setLocalState) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future: getUserData(userId),
                                builder: (context, userSnapshot) {
                                  final userData = userSnapshot.data ?? {};
                                  final userName = userData['name'] ?? 'Anonymous';
                                  final photoUrl = userData['photoUrl'] ?? '';
                                  final imageBase64 = userData['image_base64'] ?? '';

                                  ImageProvider? avatar;
                                  if (photoUrl.isNotEmpty) {
                                    avatar = NetworkImage(photoUrl);
                                  } else if (imageBase64.isNotEmpty) {
                                    avatar = MemoryImage(base64Decode(imageBase64.split(',').last));
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        /// Profile + Name + Comment
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage: avatar,
                                              backgroundColor: Colors.grey[300],
                                              child: avatar == null
                                                  ? const Icon(Icons.person, color: Colors.white)
                                                  : null,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(userName,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87)),
                                                  const SizedBox(height: 4),
                                                  Text(commentText,
                                                      style: TextStyle(
                                                          fontSize: width * 0.035,
                                                          height: 1.4)),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Text(formatTimestamp(timestamp),
                                                          style: TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: width * 0.028)),
                                                      const SizedBox(width: 10),
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final commentRef = FirebaseFirestore.instance
                                                              .collection('users')
                                                              .doc(writerId)
                                                              .collection('articles')
                                                              .doc(widget.article['articleId'])
                                                              .collection('comments')
                                                              .doc(doc.id);
                                                          if (isLiked) {
                                                            await commentRef.update({
                                                              'likedBy': FieldValue.arrayRemove([writerId])
                                                            });
                                                          } else {
                                                            await commentRef.update({
                                                              'likedBy': FieldValue.arrayUnion([writerId])
                                                            });
                                                          }
                                                        },
                                                        child: Text(
                                                          isLiked ? 'Liked' : 'Like',
                                                          style: TextStyle(
                                                            color: isLiked ? Colors.pink : Colors.grey[700],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      GestureDetector(
                                                        onTap: () {
                                                          setLocalState(() {
                                                            showReplyField = !showReplyField;
                                                          });
                                                        },
                                                        child: Text(
                                                          'Reply',
                                                          style: TextStyle(
                                                              color: Colors.grey[700],
                                                              fontWeight: FontWeight.w500),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (likes.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.favorite,
                                                              color: Colors.pink, size: 14),
                                                          const SizedBox(width: 4),
                                                          Text('${likes.length}',
                                                              style: const TextStyle(
                                                                  color: Colors.pink,
                                                                  fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        /// Replies
                                        /// Replies (hidden by default, expandable like Facebook)
                                        StatefulBuilder(
                                          builder: (context, setLocalState) {
                                            bool showReplies = false; // persistent toggle for this comment

                                            return StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(writerId)
                                                  .collection('articles')
                                                  .doc(widget.article['articleId'])
                                                  .collection('comments')
                                                  .doc(doc.id)
                                                  .collection('replies')
                                                  .orderBy('timestamp', descending: false)
                                                  .snapshots(),
                                              builder: (context, replySnapshot) {
                                                if (!replySnapshot.hasData) return const SizedBox.shrink();
                                                final replies = replySnapshot.data!.docs;
                                                if (replies.isEmpty) return const SizedBox.shrink();

                                                return StatefulBuilder(
                                                  builder: (context, setReplyListState) {
                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        /// View/Hide replies toggle
                                                        GestureDetector(
                                                          onTap: () {
                                                            setReplyListState(() {
                                                              showReplies = !showReplies;
                                                            });
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets.only(left: 45, top: 6),
                                                            child: Text(
                                                              showReplies
                                                                  ? "Hide replies"
                                                                  : "View ${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}",
                                                              style: const TextStyle(
                                                                color: Colors.grey,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        /// Replies (only shown when expanded)
                                                        if (showReplies)
                                                          Column(
                                                            children: replies.map((replyDoc) {
                                                              final replyData = replyDoc.data() as Map<String, dynamic>;
                                                              final replyText = replyData['replyText'] ?? '';
                                                              final replyUserId = replyData['replyUserId'] ?? '';
                                                              final replyTime = replyData['timestamp'];
                                                              final replyLikes =
                                                              List<String>.from(replyData['likedBy'] ?? []);
                                                              final isReplyLiked = replyLikes.contains(writerId);

                                                              bool showNestedReplyField = false;
                                                              final nestedReplyController = TextEditingController();

                                                              return StatefulBuilder(
                                                                builder: (context, setReplyState) {
                                                                  return FutureBuilder<Map<String, dynamic>>(
                                                                    future: getUserData(replyUserId),
                                                                    builder: (context, replyUserSnapshot) {
                                                                      if (!replyUserSnapshot.hasData) {
                                                                        return const SizedBox.shrink();
                                                                      }

                                                                      final rData = replyUserSnapshot.data ?? {};
                                                                      final replierName = rData['name'] ?? 'Anonymous';
                                                                      final photoUrl = rData['photoUrl'] ?? '';
                                                                      final imageBase64 = rData['image_base64'] ?? '';

                                                                      ImageProvider? replyAvatar;
                                                                      if (photoUrl.isNotEmpty) {
                                                                        replyAvatar = NetworkImage(photoUrl);
                                                                      } else if (imageBase64.isNotEmpty) {
                                                                        replyAvatar = MemoryImage(
                                                                            base64Decode(imageBase64.split(',').last));
                                                                      }

                                                                      return Container(
                                                                        margin: const EdgeInsets.only(
                                                                            left: 45, top: 8, right: 8),
                                                                        padding: const EdgeInsets.all(10),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.grey[100],

                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            /// Reply content
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                              children: [
                                                                                CircleAvatar(
                                                                                  radius: 14,
                                                                                  backgroundImage: replyAvatar,
                                                                                  backgroundColor: Colors.grey[300],
                                                                                  child: replyAvatar == null
                                                                                      ? const Icon(Icons.person,
                                                                                      size: 16,
                                                                                      color: Colors.white)
                                                                                      : null,
                                                                                ),
                                                                                const SizedBox(width: 8),

                                                                                /// Reply text and info
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    crossAxisAlignment:
                                                                                    CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        replierName,
                                                                                        style: const TextStyle(
                                                                                          fontWeight: FontWeight.bold,
                                                                                          color: Colors.black87,
                                                                                        ),
                                                                                        overflow:
                                                                                        TextOverflow.ellipsis, // ✅ responsive
                                                                                      ),
                                                                                      const SizedBox(height: 4),
                                                                                      Text(
                                                                                        replyText,
                                                                                        style: const TextStyle(
                                                                                          color: Colors.black87,
                                                                                        ),
                                                                                        softWrap: true, // ✅ wrap text
                                                                                      ),
                                                                                      const SizedBox(height: 6),

                                                                                      /// Like + Reply buttons (responsive)
                                                                                      Wrap(
                                                                                        crossAxisAlignment:
                                                                                        WrapCrossAlignment.center,
                                                                                        spacing: 10,
                                                                                        runSpacing: 4,
                                                                                        children: [
                                                                                          Text(
                                                                                            formatTimestamp(replyTime),
                                                                                            style: const TextStyle(
                                                                                              color: Colors.grey,
                                                                                              fontSize: 12,
                                                                                            ),
                                                                                          ),
                                                                                          GestureDetector(
                                                                                            onTap: () async {
                                                                                              final replyRef =
                                                                                              FirebaseFirestore
                                                                                                  .instance
                                                                                                  .collection(
                                                                                                  'users')
                                                                                                  .doc(writerId)
                                                                                                  .collection(
                                                                                                  'articles')
                                                                                                  .doc(widget.article[
                                                                                              'articleId'])
                                                                                                  .collection(
                                                                                                  'comments')
                                                                                                  .doc(doc.id)
                                                                                                  .collection(
                                                                                                  'replies')
                                                                                                  .doc(replyDoc.id);
                                                                                              if (isReplyLiked) {
                                                                                                await replyRef.update({
                                                                                                  'likedBy': FieldValue
                                                                                                      .arrayRemove(
                                                                                                      [writerId])
                                                                                                });
                                                                                              } else {
                                                                                                await replyRef.update({
                                                                                                  'likedBy': FieldValue
                                                                                                      .arrayUnion(
                                                                                                      [writerId])
                                                                                                });
                                                                                              }
                                                                                            },
                                                                                            child: Text(
                                                                                              isReplyLiked
                                                                                                  ? 'Liked'
                                                                                                  : 'Like',
                                                                                              style: TextStyle(
                                                                                                color: isReplyLiked
                                                                                                    ? Colors.pink
                                                                                                    : Colors.grey[700],
                                                                                                fontWeight:
                                                                                                FontWeight.w500,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          GestureDetector(
                                                                                            onTap: () {
                                                                                              setReplyState(() {
                                                                                                showNestedReplyField =
                                                                                                !showNestedReplyField;
                                                                                              });
                                                                                            },
                                                                                            child: Text(
                                                                                              'Reply',
                                                                                              style: TextStyle(
                                                                                                color: Colors.grey[700],
                                                                                                fontWeight:
                                                                                                FontWeight.w500,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),

                                                                                      /// Like count
                                                                                      if (replyLikes.isNotEmpty)
                                                                                        Padding(
                                                                                          padding:
                                                                                          const EdgeInsets.only(
                                                                                              top: 4),
                                                                                          child: Row(
                                                                                            mainAxisSize:
                                                                                            MainAxisSize.min,
                                                                                            children: [
                                                                                              const Icon(
                                                                                                  Icons.favorite,
                                                                                                  color: Colors.pink,
                                                                                                  size: 14),
                                                                                              const SizedBox(width: 4),
                                                                                              Text(
                                                                                                '${replyLikes.length}',
                                                                                                style: const TextStyle(
                                                                                                  color: Colors.pink,
                                                                                                  fontSize: 13,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),

                                                                            /// Nested reply field
                                                                            if (showNestedReplyField)
                                                                              Padding(
                                                                                padding: const EdgeInsets.only(
                                                                                    left: 40, top: 8),
                                                                                child: TextField(
                                                                                  controller: nestedReplyController,
                                                                                  decoration: InputDecoration(
                                                                                    hintText: "Write a reply...",
                                                                                    filled: true,
                                                                                    fillColor: Colors.white,
                                                                                    suffixIcon: IconButton(
                                                                                      icon: const Icon(Icons.send,
                                                                                          color: Colors.pink),
                                                                                      onPressed: () async {
                                                                                        final replyText =
                                                                                        nestedReplyController.text
                                                                                            .trim();
                                                                                        if (replyText.isEmpty) return;

                                                                                        await FirebaseFirestore.instance
                                                                                            .collection('users')
                                                                                            .doc(writerId)
                                                                                            .collection('articles')
                                                                                            .doc(widget.article[
                                                                                        'articleId'])
                                                                                            .collection('comments')
                                                                                            .doc(doc.id)
                                                                                            .collection('replies')
                                                                                            .add({
                                                                                          'replyText': replyText,
                                                                                          'replyUserId': writerId,
                                                                                          'timestamp': FieldValue
                                                                                              .serverTimestamp(),
                                                                                        });

                                                                                        nestedReplyController.clear();
                                                                                        setReplyState(() {
                                                                                          showNestedReplyField = false;
                                                                                        });
                                                                                      },
                                                                                    ),
                                                                                    contentPadding:
                                                                                    const EdgeInsets.symmetric(
                                                                                        horizontal: 12,
                                                                                        vertical: 10),
                                                                                    border: OutlineInputBorder(
                                                                                      borderRadius:
                                                                                      BorderRadius.circular(10),
                                                                                      borderSide: const BorderSide(
                                                                                        color: Colors.pinkAccent,
                                                                                        width: 0.8,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            }).toList(),
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),




                                        /// Reply Input (only when tapped)
                                        if (showReplyField)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 45, top: 8),
                                            child: TextField(
                                              controller: replyController,
                                              decoration: InputDecoration(
                                                hintText: "Write a reply...",
                                                filled: true,
                                                fillColor: Colors.white,
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.send, color: Colors.pink),
                                                  onPressed: () async {
                                                    await replyToComment(doc.id, replyController.text.trim());
                                                    replyController.clear();
                                                    setLocalState(() {
                                                      showReplyField = false;
                                                    });
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("Reply sent successfully")),
                                                    );
                                                  },
                                                ),
                                                contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide:
                                                  const BorderSide(color: Colors.pinkAccent, width: 0.8),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),


                  const SizedBox(height: 20),

                  /// Edit & Delete Buttons
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
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                          icon:
                          const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            "Delete Article",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
