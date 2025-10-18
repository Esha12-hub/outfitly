import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool isWearTapped = false;
  bool isEditTapped = false;
  bool isFavorite = false;

  Map<String, dynamic>? itemData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItemData();
  }

  Future<void> fetchItemData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .doc(widget.itemId);

    final doc = await docRef.get();
    if (doc.exists) {
      setState(() {
        itemData = doc.data();
        isFavorite = itemData?['isFavorite'] ?? false;
        isLoading = false;
      });
    }
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  Future<void> deleteItem() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text(
            "Are you sure you want to delete this item? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wardrobe')
            .doc(widget.itemId)
            .delete();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item deleted successfully")),
          );
        }
      }
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || itemData == null) return;

    setState(() => isFavorite = !isFavorite);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .doc(widget.itemId)
        .update({'isFavorite': isFavorite});
  }

  Future<void> markAsWorn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || itemData == null) return;

    final currentCount = (itemData?['times_worn'] ?? 0) as int;
    final newCount = currentCount + 1;

    setState(() {
      isWearTapped = true;
      itemData?['times_worn'] = newCount;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .doc(widget.itemId)
        .update({'times_worn': newCount});
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Fix: support both "colors" (array) and "color" (single number)
    final List<int> colors = (itemData?['colors'] as List?)
        ?.map((e) => e as int)
        .toList() ??
        (itemData?['color'] != null ? [itemData?['color'] as int] : []);

    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 30),
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
                    "Item Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  GestureDetector(
                    onTap: toggleFavorite,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Image
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: itemData?['image_base64'] != null
                                ? MemoryImage(
                              const Base64Decoder().convert(
                                itemData!['image_base64']
                                    .split(',')
                                    .last,
                              ),
                            )
                                : const AssetImage(
                                "assets/images/sweater1.png")
                            as ImageProvider,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        itemData?['item_name'] ?? 'Unknown Item',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Info Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _InfoTile(
                                    label: "Category",
                                    value: itemData?['category'] ?? '-',
                                    icon: Icons.local_offer),
                                _InfoTile(
                                    label: "Fabric",
                                    value: itemData?['fabric'] ?? '-',
                                    icon: Icons.texture),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _InfoTile(
                                    label: "Season",
                                    value: itemData?['season'] ?? '-',
                                    icon: Icons.wb_cloudy),
                                _InfoTile(
                                    label: "Occasion",
                                    value: itemData?['occasion'] ?? '-',
                                    icon: Icons.person),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Colors
                      const Text("COLORS:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(height: 10),
                      colors.isNotEmpty
                          ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors
                            .map((c) => CircleAvatar(
                          backgroundColor: Color(c),
                          radius: 14,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.black12,
                                  width: 1),
                            ),
                          ),
                        ))
                            .toList(),
                      )
                          : const Text("No colors added"),
                      const SizedBox(height: 24),

                      // Care Instructions
                      const Text("CARE INSTRUCTIONS",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _CareCard(
                              icon: Icons.local_laundry_service,
                              label: "Hand Wash"),
                          _CareCard(icon: Icons.air, label: "Line Dry"),
                          _CareCard(icon: Icons.iron, label: "Low Iron"),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Times Worn + Added On
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text("Times Worn",
                                        style:
                                        TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${itemData?['times_worn'] ?? 0}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    const Text("Added On",
                                        style:
                                        TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatTimestamp(
                                          itemData?['createdAt']),
                                      style: const TextStyle(
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                Icon(Icons.schedule,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 6),
                                Text("Laundry due in 2 days",
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Smart Suggestions
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Smart Suggestions",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.timelapse, size: 16),
                                SizedBox(width: 8),
                                Text("Not worn in 28 days."),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.checkroom, size: 16),
                                SizedBox(width: 8),
                                Text("Pairs well with White Sneakers"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      ActionButton(
                          label: 'Wear This Today',
                          isTapped: isWearTapped,
                          onTap: markAsWorn),
                      const SizedBox(height: 12),
                      ActionButton(
                        label: 'Edit Item',
                        isTapped: isEditTapped,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditItemScreen(
                                itemId: widget.itemId,
                                itemData: itemData ?? {},
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ActionButton(
                        label: 'Delete Item',
                        isTapped: false,
                        onTap: deleteItem,
                        destructive: true,
                      ),
                      const SizedBox(height: 30),
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
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                const TextStyle(fontSize: 10, color: Colors.black54)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ],
        ),
      ],
    );
  }
}

class _CareCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CareCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final bool isTapped;
  final VoidCallback onTap;
  final bool destructive;

  const ActionButton(
      {super.key,
        required this.label,
        required this.isTapped,
        required this.onTap,
        this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
    destructive ? Colors.red : const Color(0xFFD71D5C);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
              color: isTapped
                  ? activeColor
                  : (destructive ? Colors.red : Colors.black)),
          backgroundColor: isTapped ? activeColor : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
              color: isTapped
                  ? Colors.white
                  : (destructive ? Colors.red : Colors.black),
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
