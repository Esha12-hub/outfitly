import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedOutfitsScreen extends StatefulWidget {
  const SavedOutfitsScreen({super.key});

  @override
  State<SavedOutfitsScreen> createState() => _SavedOutfitsScreenState();
}

class _SavedOutfitsScreenState extends State<SavedOutfitsScreen> {
  List<Map<String, dynamic>> savedOutfits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_outfits')
          .get();

      setState(() {
        savedOutfits = snapshot.docs.map((d) {
          final data = d.data();
          data["id"] = d.id; // store Firestore ID
          return data;
        }).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading saved outfits: $e")),
      );
    }
  }

  Future<void> _deleteOutfit(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_outfits')
          .doc(docId)
          .delete();

      setState(() {
        savedOutfits.removeWhere((item) => item["id"] == docId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit removed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting outfit: $e")),
      );
    }
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit, double width) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Saved Outfit",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteOutfit(outfit["id"]);
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Image.memory(
                  base64Decode(outfit["shirt_base64"]),
                  width: width * 0.23,
                  height: width * 0.23,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
                Image.memory(
                  base64Decode(outfit["pant_base64"]),
                  width: width * 0.23,
                  height: width * 0.23,
                  fit: BoxFit.cover,
                ),
                if (outfit.containsKey("shoe_base64")) ...[
                  const SizedBox(width: 12),
                  Image.memory(
                    base64Decode(outfit["shoe_base64"]),
                    width: width * 0.23,
                    height: width * 0.23,
                    fit: BoxFit.cover,
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Score: ${outfit["score"]?.toStringAsFixed(2) ?? 'N/A'}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: height * 0.07),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: width * 0.07,
                      width: width * 0.07,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Saved Outfits",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0,
                  child: IconButton(
                    onPressed: () {},
                    icon: Image.asset(
                      "assets/images/white_back_btn.png",
                      height: width * 0.07,
                      width: width * 0.07,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.02),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.06,
                vertical: height * 0.03,
              ),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : savedOutfits.isEmpty
                  ? Center(
                child: Text(
                  "No saved outfits yet.",
                  style: TextStyle(
                      fontSize: 16 * textScale,
                      fontWeight: FontWeight.w600),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: savedOutfits.length,
                itemBuilder: (context, index) =>
                    _buildOutfitCard(savedOutfits[index], width),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
