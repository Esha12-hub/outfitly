import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'outfit_api.dart';
import 'settings_screen.dart';
import 'saved_outfit_screen.dart';
import 'package:image/image.dart' as img;

Future<String> compressBase64(String base64Str) async {
  final bytes = base64Decode(base64Str);
  img.Image? image = img.decodeImage(bytes);

  final resized = img.copyResize(image!, width: 120);

  final compressed = img.encodeJpg(resized, quality: 70);

  return base64Encode(compressed);
}

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  final ImagePicker _picker = ImagePicker();

  List<File> shirtImages = [];
  List<File> pantImages = [];
  List<File> shoeImages = [];
  List<Map<String, dynamic>> suggestions = [];
  bool loading = false;
  bool outfitSuggestionsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchOutfitPreference();
  }

  Future<void> _fetchOutfitPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          outfitSuggestionsEnabled = doc.data()?['outfitSuggestions'] ?? true;
        });
      }
    } catch (e) {
      print("Error fetching preference: $e");
    }
  }

  Future<void> _pickImages(String type) async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        if (type == "shirt") {
          shirtImages = picked.map((x) => File(x.path)).toList();
        } else if (type == "pant") {
          pantImages = picked.map((x) => File(x.path)).toList();
        } else {
          shoeImages = picked.map((x) => File(x.path)).toList();
        }
      });
    }
  }

  Future<void> _getSuggestions() async {
    if (!outfitSuggestionsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Outfit Suggestions are turned off."),
          action: SnackBarAction(
            label: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            textColor: Colors.pink,
          ),
        ),
      );
      return;
    }

    if (shirtImages.isEmpty || pantImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both shirts and pants.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await OutfitAPI.getSuggestions(
        shirts: shirtImages,
        pants: pantImages,
        shoes: shoeImages,
      );

      final allSuggestions = List<Map<String, dynamic>>.from(result["suggestions"]);

      final Map<String, Map<String, dynamic>> topPerShirt = {};
      for (final s in allSuggestions) {
        final shirtId = s["shirt_name"] ?? "shirt_${allSuggestions.indexOf(s)}";
        if (!topPerShirt.containsKey(shirtId) ||
            (s["score"] ?? 0) > (topPerShirt[shirtId]?["score"] ?? 0)) {
          topPerShirt[shirtId] = s;
        }
      }

      setState(() {
        if (topPerShirt.isNotEmpty) {
          final sorted = topPerShirt.values.toList()
            ..sort((a, b) => (b["score"] ?? 0).compareTo(a["score"] ?? 0));
          suggestions = [sorted.first];
        } else {
          suggestions = [];
        }
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading outfits: $e")),
      );
    }
  }

  Widget _buildImageRow(List<File> images, String label) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: images
                .map(
                  (img) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(img, width: 100, fit: BoxFit.cover),
                ),
              ),
            )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.memory(
                    base64Decode(suggestion["shirt_base64"]),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                  Image.memory(
                    base64Decode(suggestion["pant_base64"]),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  if (suggestion.containsKey("shoe_base64")) ...[
                    const SizedBox(width: 10),
                    Image.memory(
                      base64Decode(suggestion["shoe_base64"]),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Score: ${suggestion["score"]?.toStringAsFixed(2) ?? 'N/A'}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _saveSuggestion(suggestion),
              icon: const Icon(Icons.save,color: Colors.white,),
              label: const Text("Save Outfit",style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _saveSuggestion(Map<String, dynamic> suggestion) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_outfits');

    try {
      // Compress all images BEFORE saving them
      final compressedShirt = await compressBase64(suggestion["shirt_base64"]);
      final compressedPant = await compressBase64(suggestion["pant_base64"]);

      String? compressedShoe;
      if (suggestion.containsKey("shoe_base64")) {
        compressedShoe = await compressBase64(suggestion["shoe_base64"]);
      }

      final dataToSave = {
        "shirt_base64": compressedShirt,
        "pant_base64": compressedPant,
        "score": suggestion["score"],
        "reason": suggestion["reason"],
        "timestamp": DateTime.now(),
      };

      if (compressedShoe != null) {
        dataToSave["shoe_base64"] = compressedShoe;
      }

      await collection.add(dataToSave);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving outfit: $e")),
      );
    }
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
                      "Outfit Suggestions",
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageRow(shirtImages, "Selected Shirts"),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text(
                        "Pick Shirt Images",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _pickImages("shirt"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        minimumSize: Size.fromHeight(height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildImageRow(pantImages, "Selected Pants"),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text(
                        "Pick Pant Images",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _pickImages("pant"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        minimumSize: Size.fromHeight(height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildImageRow(shoeImages, "Selected Shoes"),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text(
                        "Pick Shoe Images (Optional)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _pickImages("shoe"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        minimumSize: Size.fromHeight(height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: loading ? null : _getSuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        minimumSize: Size.fromHeight(height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Get Outfit Suggestions",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedOutfitsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        minimumSize: Size.fromHeight(height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "View Saved Outfits",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (suggestions.isEmpty && !loading)
                      const Center(child: Text("No suggestions yet"))
                    else
                      Column(
                        children: suggestions.map(_buildSuggestionCard).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
