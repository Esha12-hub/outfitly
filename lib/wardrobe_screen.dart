import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_detail.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<String> subcategories = [];
  Map<String, List<Map<String, dynamic>>> wardrobeItemsBySubcategory = {};
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> sectionKeys = {};
  bool _isProgrammaticScroll = false;
  bool isLoading = true;
  String? userProfileImage;

  @override
  void initState() {
    super.initState();
    fetchWardrobeItems();
    fetchUserProfileImage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchWardrobeItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wardrobeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wardrobe');

    final snapshot = await wardrobeRef.get();
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final subcategory = data['subcategory'] ?? 'Other';

      if (!grouped.containsKey(subcategory)) {
        grouped[subcategory] = [];
      }
      grouped[subcategory]!.add(data);
    }

    setState(() {
      wardrobeItemsBySubcategory = grouped;
      subcategories = grouped.keys.toList();
      for (var sub in subcategories) {
        sectionKeys[sub] = GlobalKey();
      }
      isLoading = false;
    });
  }

  Future<void> fetchUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      setState(() {
        userProfileImage = userDoc.data()?['image_base64'];
      });
    }
  }

  void _scrollToSection(String subcategory) async {
    final keyContext = sectionKeys[subcategory]?.currentContext;
    if (keyContext != null) {
      _isProgrammaticScroll = true;
      await Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        _isProgrammaticScroll = false;
      });
    }
  }

  void _onScroll() {
    if (_isProgrammaticScroll) return;

    for (int i = 0; i < subcategories.length; i++) {
      final keyContext = sectionKeys[subcategories[i]]?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;

        if (position >= 0 &&
            position < MediaQuery.of(context).size.height / 2) {
          if (selectedIndex != i) {
            setState(() {
              selectedIndex = i;
            });
          }
          break;
        }
      }
    }
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null) return null;
    try {
      return base64Decode(base64String.contains(",")
          ? base64String.split(',').last
          : base64String);
    } catch (_) {
      return null;
    }
  }

  ImageProvider _getImageProvider(String image) {
    try {
      if (image.startsWith('http')) {
        return NetworkImage(image);
      } else {
        return MemoryImage(base64Decode(
            image.contains(',') ? image.split(',').last : image));
      }
    } catch (_) {
      return const AssetImage('assets/images/user (1).png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildAppBar(),
          _buildCategorySlider(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: subcategories.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_circle,
                        size: 80, color: Colors.black45),
                    SizedBox(height: 10),
                    Text(
                      'No items in your wardrobe yet.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subcategories.map((subcategory) {
                    return _buildSection(
                      subcategory,
                      wardrobeItemsBySubcategory[subcategory]!,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: userProfileImage != null
                      ? _getImageProvider(userProfileImage!)
                      : const AssetImage('assets/images/user (1).png')
                  as ImageProvider,
                ),
                const SizedBox(height: 10),
                const Text(
                  "My Wardrobe",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    "assets/images/white_back_btn.png",
                    height: 30,
                    width: 30,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySlider() {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                _scrollToSection(subcategories[index]);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  subcategories[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    return Container(
      key: sectionKeys[title],
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final imageBytes = decodeBase64Image(item['image_base64']);
              return GestureDetector(
                onTap: () {
                  final itemId = item['id'];
                  if (itemId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailScreen(itemId: itemId),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageBytes != null
                            ? Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                            : const Icon(Icons.image_not_supported),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item["item_name"] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
