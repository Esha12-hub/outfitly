import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_detail.dart';

class WeatherClothesScreen extends StatefulWidget {
  final double temperature;

  const WeatherClothesScreen({super.key, required this.temperature});

  @override
  State<WeatherClothesScreen> createState() => _WeatherClothesScreenState();
}

class _WeatherClothesScreenState extends State<WeatherClothesScreen> {
  List<String> subcategories = [];
  Map<String, List<Map<String, dynamic>>> itemsBySubcategory = {};
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> sectionKeys = {};
  bool _isProgrammaticScroll = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWardrobeItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<String> getSeasonsFromTemperature(double temp) {
    if (temp >= 25) return ['summer', 'spring'];
    if (temp >= 20) return ['spring', 'summer'];
    return ['winter'];
  }

  Future<void> fetchWardrobeItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No logged-in user found');
        setState(() => isLoading = false);
        return;
      }

      final seasons = getSeasonsFromTemperature(widget.temperature);
      print('🌤️ Fetching wardrobe for seasons: $seasons');

      final wardrobeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe');

      final snapshot = await wardrobeRef.get();

      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final seasonField = (data['season'] ?? '').toString().toLowerCase();
        return seasons.contains(seasonField);
      }).toList();

      print('👚 Found ${filteredDocs.length} items for seasons $seasons');

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var doc in filteredDocs) {
        final data = doc.data();
        data['id'] = doc.id;
        final subcategory = data['subcategory'] ?? 'Other';

        grouped.putIfAbsent(subcategory, () => []);
        grouped[subcategory]!.add(data);
      }

      setState(() {
        itemsBySubcategory = grouped;
        subcategories = grouped.keys.toList();
        for (var sub in subcategories) {
          sectionKeys[sub] = GlobalKey();
        }
        isLoading = false;
      });
    } catch (e, stack) {
      print('❌ Error fetching wardrobe items: $e');
      print(stack);
      setState(() => isLoading = false);
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

        if (position >= 0 && position < MediaQuery.of(context).size.height / 2) {
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
      return base64Decode(
        base64String.contains(",") ? base64String.split(',').last : base64String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final double baseWidth = 390;
    final scale = size.width / baseWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildAppBar(scale),
          _buildCategorySlider(scale),
          SizedBox(height: 20 * scale),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: subcategories.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 80, color: Colors.black45),
                    SizedBox(height: 10),
                    Text(
                      'No items found for this season.',
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
                      itemsBySubcategory[subcategory]!,
                      scale,
                      isTablet,
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

  Widget _buildAppBar(double scale) {
    final seasonLabel = getSeasonsFromTemperature(widget.temperature)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' & ');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 20 * scale),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                "$seasonLabel Wardrobe",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18 * scale,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  height: 35 * scale,
                  width: 35 * scale,
                  child: Image.asset(
                    "assets/images/white_back_btn.png",
                    height: 15 * scale,
                    width: 15 * scale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategorySlider(double scale) {
    return SizedBox(
      height: 30 * scale,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: 8.0 * scale),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                _scrollToSection(subcategories[index]);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink : Colors.transparent,
                  borderRadius: BorderRadius.circular(20 * scale),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  subcategories[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, double scale, bool isTablet) {
    final crossAxisCount = isTablet ? 4 : 2;
    return Container(
      key: sectionKeys[title],
      margin: EdgeInsets.only(bottom: 24 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10 * scale),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16 * scale,
              crossAxisSpacing: 16 * scale,
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
                      height: 160 * scale,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10 * scale),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10 * scale),
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
                    SizedBox(height: 5 * scale),
                    Text(
                      item["item_name"] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14 * scale,
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
