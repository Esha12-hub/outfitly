import 'package:flutter/material.dart';
import 'dart:math';
import 'outfit_detail_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AiOutfitSuggestionsScreen extends StatefulWidget {
  const AiOutfitSuggestionsScreen({super.key});

  @override
  State<AiOutfitSuggestionsScreen> createState() => _AiOutfitSuggestionsScreenState();
}

class _AiOutfitSuggestionsScreenState extends State<AiOutfitSuggestionsScreen> {
  late List<Outfit> outfits;
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    _generateOutfits();
  }

  void _generateOutfits() {
    final random = Random();
    outfits = [
      Outfit(
        image: 'assets/images/outfit1.png',
        title: 'Casual | Winter',
        description: 'Stay warm and stylish with layered basics and a cozy coat.',
        score: '${70 + random.nextInt(30)}%',
      ),
      Outfit(
        image: 'assets/images/outfit2.png',
        title: 'Casual | Autumn',
        description: 'Light jacket paired with denim and boots for crisp days.',
        score: '${70 + random.nextInt(30)}%',
      ),
      Outfit(
        image: 'assets/images/outfit3.png',
        title: 'Party wear | Winter',
        description: 'Elegant layers with bold accessories for cold-weather parties.',
        score: '${70 + random.nextInt(30)}%',
      ),
      Outfit(
        image: 'assets/images/outfit4.png',
        title: 'Casual | Summer',
        description: 'Breathable fabrics and relaxed silhouettes for sunny days.',
        score: '${70 + random.nextInt(30)}%',
      ),
    ];

  }

  void _refreshOutfits() => setState(() => _generateOutfits());

  void _toggleFilterOverlay() => setState(() => showFilters = !showFilters);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Image.asset("assets/images/white_back_btn.png", height: 30, width: 30),
                        ),
                      ),
                      const Text("AI Outfit Suggestions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          GestureDetector(onTap: _toggleFilterOverlay, child: const Icon(Icons.filter_alt_outlined, color: Colors.white)),
                          const SizedBox(width: 12),
                          GestureDetector(onTap: _refreshOutfits, child: const Icon(Icons.refresh, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: outfits.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutfitCard(
                            outfit: outfits[index],
                            onToggleFavorite: () {
                              setState(() => outfits[index].isFavorite = !outfits[index].isFavorite);
                            },
                            onToggleBookmark: () {
                              setState(() => outfits[index].isBookmarked = !outfits[index].isBookmarked);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (showFilters)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFilterOverlay,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FilterOverlay(onClose: _toggleFilterOverlay),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Outfit {
  final String image;
  final String title;
  final String description;
  final String score;
  bool isFavorite;
  bool isBookmarked;

  Outfit({
    required this.image,
    required this.title,
    required this.description,
    required this.score,
    this.isFavorite = false,
    this.isBookmarked = false,
  });
}

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutfitDetailScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: outfit.image.isNotEmpty
                    ? Image.asset(
                  outfit.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons
                          .image_not_supported)),
                    );
                  },
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.image)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(outfit.title, style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    outfit.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Icon(
                          outfit.isFavorite ? Icons.favorite : Icons
                              .favorite_border,
                          color: outfit.isFavorite ? Colors.red : Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onToggleBookmark,
                        child: Icon(
                          outfit.isBookmarked ? Icons.bookmark : Icons
                              .bookmark_border,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Share tapped")),
                          );
                        },
                        child: const Icon(
                            Icons.share, color: Colors.black, size: 20),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD71D5C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            outfit.score, style: const TextStyle(color: Colors
                            .white, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }}

class FilterOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const FilterOverlay({super.key, required this.onClose});

  @override
  State<FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<FilterOverlay> {
  List<String> occasions = ['Casual', 'Formal', 'Work', 'Vacation'];
  List<String> moods = ['Bold', 'Minimalist', 'Sad', 'Happy'];
  List<String> seasons = ['Spring', 'Summer', 'Fall', 'Winter'];
  List<Color> colors = [Colors.pink, Colors.purple, Colors.white, Colors.yellow, Colors.green];

  Set<String> selectedOccasions = {'Casual'};
  Set<String> selectedMoods = {'Minimalist'};
  Set<String> selectedSeasons = {'Winter'};
  Set<Color> selectedColors = {};

  void _addTag(List<String> targetList, Function(String) onAdded) {
    String newTag = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Tag"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter tag name"),
          onChanged: (val) => newTag = val,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (newTag.isNotEmpty && !targetList.contains(newTag)) {
                onAdded(newTag);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _addColor() {
    Color newColor = Colors.grey;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Color"),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: Colors.grey,
            onColorChanged: (color) => newColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                colors.add(newColor);
              });
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Widget _buildTag(String label, Set<String> selectedSet, List<String> sourceList, VoidCallback onDelete) {
    final isSelected = selectedSet.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? selectedSet.remove(label) : selectedSet.add(label);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD71D5C) : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white)),
            if (!['Casual', 'Formal', 'Work', 'Vacation', 'Bold', 'Minimalist', 'Sad', 'Happy'].contains(label))
              GestureDetector(
                onTap: () {
                  setState(() {
                    sourceList.remove(label);
                    selectedSet.remove(label);
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _colorCircle(Color color) {
    final isSelected = selectedColors.contains(color);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? selectedColors.remove(color) : selectedColors.add(color);
        });
      },
      onLongPress: () {
        setState(() {
          colors.remove(color);
          selectedColors.remove(color);
        });
      },
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(right: 10, bottom: 10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.grey, width: 2),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Set<String> selectedSet, VoidCallback onAddPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add, color: Colors.white, size: 18), onPressed: onAddPressed),
          ],
        ),
        Wrap(children: items.map((item) => _buildTag(item, selectedSet, items, () {})).toList()),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildSection("Occasion", occasions, selectedOccasions, () => _addTag(occasions, (val) => setState(() => occasions.add(val)))),
              _buildSection("Mood", moods, selectedMoods, () => _addTag(moods, (val) => setState(() => moods.add(val)))),
              _buildSection("Season", seasons, selectedSeasons, () {}),
              const Text("Color", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                children: [
                  ...colors.map(_colorCircle),
                  GestureDetector(
                    onTap: _addColor,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 10, bottom: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}