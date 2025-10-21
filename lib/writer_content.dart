import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'content_detail_screen.dart';
import 'writer_login_screen.dart';

class WriterContentScreen extends StatefulWidget {
  const WriterContentScreen({super.key});

  @override
  State<WriterContentScreen> createState() => _WriterContentScreenState();
}

class _WriterContentScreenState extends State<WriterContentScreen> {
  String selectedFilter = 'All';
  String selectedStatus = 'Accepted';
  String? writerId;

  final List<String> filters = ['All', 'Casual', 'Formal', 'Streetwear', 'Trends'];
  final List<String> statuses = ['Accepted', 'Pending', 'Rejected'];

  @override
  void initState() {
    super.initState();
    writerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 🔹 HEADER + FILTER CHIPS
          Container(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 8),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Title + Refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Image.asset(
                        "assets/images/white_back_btn.png",
                        height: 26,
                        width: 26,
                      ),
                    ),
                    const Text(
                      'My Submitted Styles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

          // 🔹 WHITE CONTENT AREA
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // 🔸 STATUS SELECTOR (Accepted / Pending / Rejected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: statuses.map((status) {
                      final bool isSelected = selectedStatus == status;
                      return GestureDetector(
                        onTap: () => setState(() => selectedStatus = status),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.pink : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.pink : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // 🔸 CONTENT LIST
                  Expanded(
                    child: writerId == null
                        ? const Center(child: Text("Not signed in"))
                        : FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchWriterArticles(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final articles = snapshot.data ?? [];
                        final filteredByCategory = selectedFilter == 'All'
                            ? articles
                            : articles
                            .where((a) =>
                        a['category']
                            ?.toString()
                            .toLowerCase()
                            .contains(selectedFilter.toLowerCase()) ?? false)
                            .toList();

                        final filtered = filteredByCategory.where((a) {
                          if (selectedStatus == 'Accepted') return a['status'] == 'approved';
                          if (selectedStatus == 'Rejected') return a['status'] == 'rejected';
                          return a['status'] != 'approved' && a['status'] != 'rejected';
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              "No ${selectedStatus.toLowerCase()} content found.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
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
                                        builder: (_) => WriterContentDetailScreen(article: article),
                                      ),
                                    );
                                  },
                                  child: ContentCard(
                                    imageBase64: article['mediaBase64'] ?? '',
                                    title: article['title'] ?? '',
                                    author: 'You',
                                    time: formatTimestamp(article['timestamp']),
                                    description: article['description'] ?? '',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Logout confirmation dialog
  Future<void> _handleLogout() async {
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
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  // 🔹 Fetch current writer’s articles
  Future<List<Map<String, dynamic>>> fetchWriterArticles() async {
    if (writerId == null) return [];
    final articlesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(writerId)
        .collection('articles')
        .orderBy('timestamp', descending: true)
        .get();

    return articlesSnapshot.docs.map((doc) {
      final data = doc.data();
      data['articleId'] = doc.id;
      return data;
    }).toList();
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
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
