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
                "Delete Item?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to permanently delete this item? This action cannot be undone.",
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
    if (user == null) return;

    final userWardrobeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe')
        .doc(widget.itemId);

    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.itemId);

    setState(() {
      isFavorite = !isFavorite; // Toggle UI immediately
    });

    try {
      if (isFavorite) {
        await userWardrobeRef.update({'isFavorite': true});
        await userFavoritesRef.set({
          'itemData': {
            'itemId': widget.itemId,
            'item_name': itemData?['item_name'],
            'image_base64': itemData?['image_base64'],
            'subcategory': itemData?['subcategory'] ?? 'Other',
            'type': itemData?['type'],
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await userWardrobeRef.update({'isFavorite': false});
        await userFavoritesRef.delete();
      }
    } catch (e) {
      setState(() {
        isFavorite = !isFavorite;
      });
      print("Error updating favorites: $e");
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: screenWidth * 0.08,
                      width: screenWidth * 0.08,
                    ),
                  ),
                  Text(
                    "Item Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045),
                  ),
                  GestureDetector(
                    onTap: toggleFavorite,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: screenWidth * 0.07,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Image
                      Container(
                        height: screenHeight * 0.3,
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
                      SizedBox(height: screenHeight * 0.02),

                      Text(
                        itemData?['item_name'] ?? 'Unknown Item',
                        style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Info Section
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
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
                                    icon: Icons.local_offer,
                                    screenWidth: screenWidth),
                                _InfoTile(
                                    label: "Fabric",
                                    value: itemData?['fabric'] ?? '-',
                                    icon: Icons.texture,
                                    screenWidth: screenWidth),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _InfoTile(
                                    label: "Season",
                                    value: itemData?['season'] ?? '-',
                                    icon: Icons.wb_cloudy,
                                    screenWidth: screenWidth),
                                _InfoTile(
                                    label: "Occasion",
                                    value: itemData?['occasion'] ?? '-',
                                    icon: Icons.person,
                                    screenWidth: screenWidth),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Colors
                      Text("COLORS:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.035)),
                      SizedBox(height: screenHeight * 0.01),
                      colors.isNotEmpty
                          ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors
                            .map((c) => CircleAvatar(
                          backgroundColor: Color(c),
                          radius: screenWidth * 0.035,
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
                      SizedBox(height: screenHeight * 0.03),

                      // Care Instructions
                      Text("CARE INSTRUCTIONS",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035)),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CareCard(
                              icon: Icons.local_laundry_service,
                              label: "Hand Wash",
                              screenWidth: screenWidth),
                          _CareCard(
                              icon: Icons.air,
                              label: "Line Dry",
                              screenWidth: screenWidth),
                          _CareCard(
                              icon: Icons.iron,
                              label: "Low Iron",
                              screenWidth: screenWidth),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Times Worn + Added On
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(screenWidth * 0.04),
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
                                    Text("Times Worn",
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.03)),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      "${itemData?['times_worn'] ?? 0}",
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    Text("Added On",
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.03)),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      formatTimestamp(itemData?['createdAt']),
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.035),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.015),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Buttons
                      ActionButton(
                        label: 'Wear This Today',
                        isTapped: isWearTapped,
                        onTap: markAsWorn,
                        screenWidth: screenWidth,
                        backgroundColor: const Color(0xFFD71D5C),
                        textColor: Colors.white,
                      ),
                      SizedBox(height: screenHeight * 0.015),
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
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      ActionButton(
                        label: 'Delete Item',
                        isTapped: false,
                        onTap: deleteItem,
                        destructive: true,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.03),
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
  final double screenWidth;

  const _InfoTile(
      {required this.label,
        required this.value,
        required this.icon,
        required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.05, color: Colors.black),
        SizedBox(width: screenWidth * 0.02),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: screenWidth * 0.025, color: Colors.black54)),
            Text(value,
                style: TextStyle(
                    fontSize: screenWidth * 0.035,
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
  final double screenWidth;

  const _CareCard({required this.icon, required this.label, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth * 0.25,
      height: screenWidth * 0.22,
      padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.02, horizontal: screenWidth * 0.015),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: screenWidth * 0.07, color: Colors.black),
          SizedBox(height: screenWidth * 0.015),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: screenWidth * 0.027, color: Colors.black87)),
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
  final double screenWidth;
  final Color? backgroundColor; // optional background color
  final Color? textColor;       // optional text color

  const ActionButton({
    super.key,
    required this.label,
    required this.isTapped,
    required this.onTap,
    required this.screenWidth,
    this.destructive = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color defaultActiveColor = destructive ? Colors.red : const Color(0xFFD71D5C);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
          side: BorderSide(
            color: backgroundColor ?? (isTapped ? defaultActiveColor : (destructive ? Colors.red : Colors.black)),
          ),
          backgroundColor: backgroundColor ?? (isTapped ? defaultActiveColor : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? (isTapped ? Colors.white : (destructive ? Colors.red : Colors.black)),
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }
}
