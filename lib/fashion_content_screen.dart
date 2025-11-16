import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FashionStylingContentScreen extends StatefulWidget {
  const FashionStylingContentScreen({super.key});

  @override
  State<FashionStylingContentScreen> createState() => _FashionStylingContentScreenState();
}

class _FashionStylingContentScreenState extends State<FashionStylingContentScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Casual', 'Formal', 'Streetwear', 'Trends'];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        "assets/images/white_back_btn.png",
                        height: width * 0.08,
                        width: width * 0.08,
                      ),
                    ),
                    const Text(
                      'Fashion Styling Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((label) {
                      return FilterChipWidget(
                        label: label,
                        selected: selectedFilter == label,
                        onTap: () => setState(() => selectedFilter = label),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchAllArticles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final articles = snapshot.data ?? [];
                  final approved = articles
                      .where((a) => (a['status']?.toString().toLowerCase() ?? '') == 'approved')
                      .toList();

                  final filtered = selectedFilter == 'All'
                      ? approved
                      : approved
                      .where((a) => (a['tags']?.toString().toLowerCase() ?? '')
                      .contains(selectedFilter.toLowerCase()))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No articles found."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final article = filtered[index];
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContentDetailScreen(article: article),
                                ),
                              );
                            },
                            child: ContentCard(
                              imageBase64: article['mediaBase64'] ?? '',
                              title: article['title'] ?? '',
                              author: article['author'] ?? 'Unknown',
                              time: formatTimestamp(article['timestamp']),
                              description: article['caption'] ?? '',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllArticles() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> allArticles = [];

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final articlesSnapshot = await userDoc.reference.collection('articles').get();

      for (var articleDoc in articlesSnapshot.docs) {
        final articleData = articleDoc.data();
        articleData['author'] = userData['name'] ?? 'Unknown';
        articleData['userId'] = userDoc.id;
        articleData['articleId'] = articleDoc.id;
        allArticles.add(articleData);
      }
    }

    return allArticles;
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else if (timestamp is DateTime) {
      time = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(time);
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  final String imageBase64;
  final String title;
  final String author;
  final String time;
  final String description;

  const ContentCard({
    super.key,
    required this.imageBase64,
    required this.title,
    required this.author,
    required this.time,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = (imageBase64.isNotEmpty)
        ? base64Decode(imageBase64.split(',').last)
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bytes != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.memory(
                bytes,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(author, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  const ContentDetailScreen({super.key, required this.article});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool isLiked = false;
  int likeCount = 0;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLikes();
  }

  Future<void> fetchLikes() async {
    final likeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.article['userId'])
        .collection('articles')
        .doc(widget.article['articleId'])
        .get();

    if (likeDoc.exists) {
      final data = likeDoc.data()!;
      setState(() {
        likeCount = (data['likes'] ?? 0);
        isLiked = (data['likedBy'] ?? []).contains(FirebaseAuth.instance.currentUser?.uid);
      });
    }
  }

  Future<void> toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.article['userId'])
        .collection('articles')
        .doc(widget.article['articleId']);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      List likedBy = List.from(data['likedBy'] ?? []);
      int likes = data['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likes--;
      } else {
        likedBy.add(userId);
        likes++;
      }

      transaction.update(docRef, {'likes': likes, 'likedBy': likedBy});
    });

    fetchLikes();
  }

  Future<void> addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || commentController.text.trim().isEmpty) return;

    final comment = {
      'userId': user.uid,
      'text': commentController.text.trim(),
      'timestamp': Timestamp.now(),
      'likedBy': [],
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.article['userId'])
        .collection('articles')
        .doc(widget.article['articleId'])
        .collection('comments')
        .add(comment);

    commentController.clear();
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bytes = (widget.article['mediaBase64'] != null && widget.article['mediaBase64'] != '')
        ? base64Decode(widget.article['mediaBase64'].split(',').last)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Fashion Content',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            "assets/images/white_back_btn.png",
            width: width * 0.08,
            height: width * 0.08,
            fit: BoxFit.contain,
          ),
        ),


      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                        Text(widget.article['title'] ?? '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(widget.article['author'] ?? 'Unknown',
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text(
                              widget.article['timestamp'] != null
                                  ? DateFormat.yMMMd()
                                  .format((widget.article['timestamp'] as Timestamp).toDate())
                                  : '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(widget.article['caption'] ?? '',
                            style: const TextStyle(fontSize: 16, height: 1.5)),
                        const SizedBox(height: 12),
                        if (widget.article['content'] != null &&
                            widget.article['content'].toString().isNotEmpty)
                          Text(
                            widget.article['content'],
                            style:
                            const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
                          )
                        else
                          const Text("No detailed content available.",
                              style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: Colors.pink,
                              ),
                              onPressed: toggleLike,
                            ),
                            Text('$likeCount Likes'),
                          ],
                        ),

                        const Divider(),
                        const Text(
                          'Comments',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.article['userId'])
                              .collection('articles')
                              .doc(widget.article['articleId'])
                              .collection('comments')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text('No comments yet.');
                            }

                            final comments = snapshot.data!.docs;
                            return Column(
                              children: comments.map((commentDoc) {
                                final commentData = commentDoc.data() as Map<String, dynamic>;
                                final commentUserId = commentData['userId'];
                                final commentTime = (commentData['timestamp'] as Timestamp).toDate();
                                final likedBy = List<String>.from(commentData['likedBy'] ?? []);
                                final isLiked = likedBy.contains(FirebaseAuth.instance.currentUser!.uid);

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(commentUserId).get(),
                                  builder: (context, userSnapshot) {
                                    final userData =
                                    (userSnapshot.hasData && userSnapshot.data!.exists)
                                        ? userSnapshot.data!.data() as Map<String, dynamic>
                                        : null;

                                    final authorName = userData?['name'] ?? 'Anonymous';

                                    Widget buildAvatar(Map<String, dynamic>? data) {
                                      if (data == null) return const CircleAvatar(child: Icon(Icons.person));
                                      if (data['photoUrl']?.isNotEmpty ?? false)
                                        return CircleAvatar(backgroundImage: NetworkImage(data['photoUrl']));
                                      if (data['image_base64']?.isNotEmpty ?? false) {
                                        try {
                                          final bytes = base64Decode(data['image_base64'].split(',').last);
                                          return CircleAvatar(backgroundImage: MemoryImage(bytes));
                                        } catch (_) {}
                                      }
                                      return const CircleAvatar(child: Icon(Icons.person));
                                    }

                                    bool showReplies = false;
                                    bool showReplyBox = false;
                                    bool showEditBox = false;
                                    final editController = TextEditingController(text: commentData['text']);

                                    return StatefulBuilder(
                                      builder: (context, setLocalState) {
                                        final replyController = TextEditingController();

                                        return GestureDetector(
                                          onLongPress: () {
                                            if (commentUserId == FirebaseAuth.instance.currentUser!.uid) {
                                              showModalBottomSheet(
                                                context: context,
                                                builder: (context) => Wrap(
                                                  children: [
                                                    ListTile(
                                                      leading: const Icon(Icons.edit, color: Colors.pink),
                                                      title: const Text('Edit'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        setLocalState(() {
                                                          showEditBox = true;
                                                        });
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(Icons.delete, color: Colors.red),
                                                      title: const Text('Delete'),
                                                      onTap: () async {
                                                        Navigator.pop(context);
                                                        await FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(widget.article['userId'])
                                                            .collection('articles')
                                                            .doc(widget.article['articleId'])
                                                            .collection('comments')
                                                            .doc(commentDoc.id)
                                                            .delete();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    buildAvatar(userData),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(authorName,
                                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: 4),

                                                          if (showEditBox)
                                                            TextField(
                                                              controller: editController,
                                                              decoration: InputDecoration(
                                                                suffixIcon: IconButton(
                                                                  icon: const Icon(Icons.check, color: Colors.pink),
                                                                  onPressed: () async {
                                                                    final newText = editController.text.trim();
                                                                    if (newText.isEmpty) return;
                                                                    await FirebaseFirestore.instance
                                                                        .collection('users')
                                                                        .doc(widget.article['userId'])
                                                                        .collection('articles')
                                                                        .doc(widget.article['articleId'])
                                                                        .collection('comments')
                                                                        .doc(commentDoc.id)
                                                                        .update({'text': newText});
                                                                    setLocalState(() {
                                                                      showEditBox = false;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            Text(commentData['text'] ?? ''),
                                                          const SizedBox(height: 6),

                                                          Wrap(
                                                            spacing: 12,
                                                            crossAxisAlignment: WrapCrossAlignment.center,
                                                            children: [
                                                              Text(
                                                                DateFormat('MMM d, h:mm a').format(commentTime),
                                                                style: const TextStyle(
                                                                    fontSize: 12, color: Colors.grey),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () async {
                                                                  final commentRef = FirebaseFirestore.instance
                                                                      .collection('users')
                                                                      .doc(widget.article['userId'])
                                                                      .collection('articles')
                                                                      .doc(widget.article['articleId'])
                                                                      .collection('comments')
                                                                      .doc(commentDoc.id);

                                                                  if (isLiked) {
                                                                    await commentRef.update({
                                                                      'likedBy': FieldValue.arrayRemove([
                                                                        FirebaseAuth.instance.currentUser!.uid
                                                                      ])
                                                                    });
                                                                  } else {
                                                                    await commentRef.update({
                                                                      'likedBy': FieldValue.arrayUnion([
                                                                        FirebaseAuth.instance.currentUser!.uid
                                                                      ])
                                                                    });
                                                                  }
                                                                },
                                                                child: Text(
                                                                  isLiked ? "Liked" : "Like",
                                                                  style: TextStyle(
                                                                    color: isLiked ? Colors.pink : Colors.grey[700],
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setLocalState(() {
                                                                    showReplyBox = !showReplyBox;
                                                                  });
                                                                },
                                                                child: Text(
                                                                  "Reply",
                                                                  style: TextStyle(
                                                                    color: Colors.grey[700],
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),

                                                          if (likedBy.isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Icon(Icons.favorite,
                                                                      color: Colors.pink, size: 14),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    '${likedBy.length}',
                                                                    style: const TextStyle(
                                                                        color: Colors.pink, fontSize: 13),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                if (showReplyBox)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 40, top: 8),
                                                    child: TextField(
                                                      controller: replyController,
                                                      decoration: InputDecoration(
                                                        hintText: "Write a reply...",
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        suffixIcon: IconButton(
                                                          icon: const Icon(Icons.send, color: Colors.pink),
                                                          onPressed: () async {
                                                            final replyText = replyController.text.trim();
                                                            if (replyText.isEmpty) return;

                                                            await FirebaseFirestore.instance
                                                                .collection('users')
                                                                .doc(widget.article['userId'])
                                                                .collection('articles')
                                                                .doc(widget.article['articleId'])
                                                                .collection('comments')
                                                                .doc(commentDoc.id)
                                                                .collection('replies')
                                                                .add({
                                                              'replyText': replyText,
                                                              'replyUserId':
                                                              FirebaseAuth.instance.currentUser!.uid,
                                                              'timestamp': FieldValue.serverTimestamp(),
                                                              'likedBy': [],
                                                            });

                                                            replyController.clear();
                                                            setLocalState(() {
                                                              showReplyBox = false;
                                                              showReplies = true;
                                                            });
                                                          },
                                                        ),
                                                        contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 12, vertical: 10),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                          borderSide:
                                                          const BorderSide(color: Colors.pinkAccent),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                StreamBuilder<QuerySnapshot>(
                                                  stream: FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(widget.article['userId'])
                                                      .collection('articles')
                                                      .doc(widget.article['articleId'])
                                                      .collection('comments')
                                                      .doc(commentDoc.id)
                                                      .collection('replies')
                                                      .orderBy('timestamp', descending: false)
                                                      .snapshots(),
                                                  builder: (context, replySnapshot) {
                                                    if (!replySnapshot.hasData) return const SizedBox.shrink();
                                                    final replies = replySnapshot.data!.docs;
                                                    if (replies.isEmpty) return const SizedBox.shrink();

                                                    return Padding(
                                                      padding: const EdgeInsets.only(left: 40, top: 6),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () => setLocalState(
                                                                    () => showReplies = !showReplies),
                                                            child: Text(
                                                              showReplies
                                                                  ? "Hide replies"
                                                                  : "View ${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}",
                                                              style: const TextStyle(
                                                                  color: Colors.grey,
                                                                  fontWeight: FontWeight.w500),
                                                            ),
                                                          ),

                                                          if (showReplies)
                                                            Column(
                                                              children: replies.map((replyDoc) {
                                                                final replyData = replyDoc.data() as Map<String, dynamic>;
                                                                final replyLikes = List<String>.from(replyData['likedBy'] ?? []);
                                                                final isReplyLiked = replyLikes.contains(
                                                                    FirebaseAuth.instance.currentUser!.uid);
                                                                final replyTime =
                                                                (replyData['timestamp'] as Timestamp?)?.toDate();
                                                                final replyUserId = replyData['replyUserId'];

                                                                bool showNestedReplyBox = false;
                                                                final nestedReplyController = TextEditingController();

                                                                return StatefulBuilder(
                                                                  builder: (context, setNestedState) {
                                                                    return FutureBuilder<DocumentSnapshot>(
                                                                      future: FirebaseFirestore.instance
                                                                          .collection('users')
                                                                          .doc(replyUserId)
                                                                          .get(),
                                                                      builder: (context, replyUserSnap) {
                                                                        final replyUser = replyUserSnap.data?.data()
                                                                        as Map<String, dynamic>?;

                                                                        return Container(
                                                                          margin: const EdgeInsets.only(top: 6),
                                                                          padding: const EdgeInsets.all(8),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.white,
                                                                            borderRadius: BorderRadius.circular(8),
                                                                          ),
                                                                          child: Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  buildAvatar(replyUser),
                                                                                  const SizedBox(width: 8),
                                                                                  Expanded(
                                                                                    child: Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          replyUser?['name'] ?? 'Anonymous',
                                                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                                                        ),
                                                                                        const SizedBox(height: 4),
                                                                                        Text(replyData['replyText'] ?? ''),
                                                                                        const SizedBox(height: 4),
                                                                                        Wrap(
                                                                                          spacing: 10,
                                                                                          runSpacing: 4,
                                                                                          crossAxisAlignment: WrapCrossAlignment.center,
                                                                                          children: [
                                                                                            Text(
                                                                                              replyTime != null
                                                                                                  ? DateFormat('MMM d, h:mm a').format(replyTime)
                                                                                                  : '',
                                                                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                                                            ),
                                                                                            GestureDetector(
                                                                                              onTap: () async {
                                                                                                final replyRef = FirebaseFirestore.instance
                                                                                                    .collection('users')
                                                                                                    .doc(widget.article['userId'])
                                                                                                    .collection('articles')
                                                                                                    .doc(widget.article['articleId'])
                                                                                                    .collection('comments')
                                                                                                    .doc(commentDoc.id)
                                                                                                    .collection('replies')
                                                                                                    .doc(replyDoc.id);

                                                                                                if (isReplyLiked) {
                                                                                                  await replyRef.update({
                                                                                                    'likedBy': FieldValue.arrayRemove(
                                                                                                        [FirebaseAuth.instance.currentUser!.uid]),
                                                                                                  });
                                                                                                } else {
                                                                                                  await replyRef.update({
                                                                                                    'likedBy': FieldValue.arrayUnion(
                                                                                                        [FirebaseAuth.instance.currentUser!.uid]),
                                                                                                  });
                                                                                                }
                                                                                              },
                                                                                              child: Text(
                                                                                                isReplyLiked ? 'Liked' : 'Like',
                                                                                                style: TextStyle(
                                                                                                  color: isReplyLiked ? Colors.pink : Colors.grey[700],
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            GestureDetector(
                                                                                              onTap: () {
                                                                                                setNestedState(() {
                                                                                                  showNestedReplyBox = !showNestedReplyBox;
                                                                                                });
                                                                                              },
                                                                                              child: Text(
                                                                                                "Reply",
                                                                                                style: TextStyle(
                                                                                                  color: Colors.grey[700],
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            if (replyLikes.isNotEmpty)
                                                                                              Row(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                children: [
                                                                                                  const Icon(Icons.favorite, color: Colors.pink, size: 14),
                                                                                                  const SizedBox(width: 4),
                                                                                                  Text(
                                                                                                    '${replyLikes.length}',
                                                                                                    style: const TextStyle(color: Colors.pink, fontSize: 13),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),

                                                                              if (showNestedReplyBox)
                                                                                Padding(
                                                                                  padding: const EdgeInsets.only(left: 40, top: 8),
                                                                                  child: TextField(
                                                                                    controller: nestedReplyController,
                                                                                    decoration: InputDecoration(
                                                                                      hintText: "Write a reply...",
                                                                                      filled: true,
                                                                                      fillColor: Colors.grey[50],
                                                                                      suffixIcon: IconButton(
                                                                                        icon: const Icon(Icons.send, color: Colors.pink),
                                                                                        onPressed: () async {
                                                                                          final text = nestedReplyController.text.trim();
                                                                                          if (text.isEmpty) return;

                                                                                          await FirebaseFirestore.instance
                                                                                              .collection('users')
                                                                                              .doc(widget.article['userId'])
                                                                                              .collection('articles')
                                                                                              .doc(widget.article['articleId'])
                                                                                              .collection('comments')
                                                                                              .doc(commentDoc.id)
                                                                                              .collection('replies')
                                                                                              .add({
                                                                                            'replyText': text,
                                                                                            'replyUserId': FirebaseAuth.instance.currentUser!.uid,
                                                                                            'timestamp': FieldValue.serverTimestamp(),
                                                                                            'likedBy': [],
                                                                                          });

                                                                                          nestedReplyController.clear();
                                                                                          setNestedState(() {
                                                                                            showNestedReplyBox = false;
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                                                      border: OutlineInputBorder(
                                                                                        borderRadius: BorderRadius.circular(10),
                                                                                        borderSide: const BorderSide(color: Colors.pinkAccent),
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
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------- COMMENT INPUT --------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
