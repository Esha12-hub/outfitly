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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
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
                // Filter chips
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

          // Content
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
                      .where((a) => a['status']?.toString().toLowerCase() == 'approved')
                      .toList();

                  final filtered = selectedFilter == 'All'
                      ? approved
                      : approved
                      .where((a) => a['tags']
                      .toString()
                      .toLowerCase()
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
                              author: article['author'] ?? '',
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

// ---------------- FILTER CHIP ----------------

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

// ---------------- CONTENT CARD ----------------

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

// ---------------- DETAIL SCREEN ----------------

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
    final bytes = (widget.article['mediaBase64'] != null && widget.article['mediaBase64'] != '')
        ? base64Decode(widget.article['mediaBase64'].split(',').last)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Fashion Content',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 20),
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
                                  ? DateFormat.yMMMd().format(
                                  (widget.article['timestamp'] as Timestamp).toDate())
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
                            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
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
                        const Text('Comments',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'No comments yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            final comments = snapshot.data!.docs;
                            return Column(
                              children: comments.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final time = (data['timestamp'] as Timestamp).toDate();
                                return ListTile(
                                  leading: const Icon(Icons.person, color: Colors.grey),
                                  title: Text(data['text']),
                                  subtitle: Text(DateFormat('MMM d, h:mm a').format(time)),
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

          // Comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
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
