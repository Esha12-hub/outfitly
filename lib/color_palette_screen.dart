import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

class SkinColorPalettePage extends StatefulWidget {
  const SkinColorPalettePage({super.key});

  @override
  State<SkinColorPalettePage> createState() => _SkinColorPalettePageState();
}

class _SkinColorPalettePageState extends State<SkinColorPalettePage> {
  File? _image;
  List<Color> _colors = [];
  String? _skinToneType;
  List<Map<String, dynamic>> _suggestedColors = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final imageProvider = FileImage(file);

      final palette = await PaletteGeneratorMaster.fromImageProvider(
        imageProvider,
        maximumColorCount: 12,
        generateHarmony: true,
      );

      final extractedColors = [
        palette.dominantColor?.color,
        palette.vibrantColor?.color,
        palette.mutedColor?.color,
        palette.darkVibrantColor?.color,
        palette.lightVibrantColor?.color,
      ].whereType<Color>().toList();

      if (extractedColors.isNotEmpty) {
        final dominant = extractedColors.first;
        _analyzeSkinTone(dominant);
      }

      setState(() {
        _image = file;
        _colors = extractedColors;
      });
    }
  }

  void _analyzeSkinTone(Color color) {
    final r = color.red.toDouble();
    final g = color.green.toDouble();
    final b = color.blue.toDouble();

    if (r > g && r > b && (r - b) > 15) {
      _skinToneType = "Warm Tone";
      _suggestedColors = [
        {"name": "Light Salmon", "color": const Color(0xFFFFA07A)},
        {"name": "Chocolate", "color": const Color(0xFFD2691E)},
        {"name": "Gold", "color": const Color(0xFFFFD700)},
        {"name": "Peru", "color": const Color(0xFFCD853F)},
        {"name": "Coral", "color": const Color(0xFFFF7F50)},
        {"name": "Sandy Brown", "color": const Color(0xFFF4A460)},
        {"name": "Olive", "color": const Color(0xFF6B8E23)},
        {"name": "Forest Green", "color": const Color(0xFF228B22)},
      ];
    } else if (b > r && b > g) {
      _skinToneType = "Cool Tone";
      _suggestedColors = [
        {"name": "Royal Blue", "color": const Color(0xFF4169E1)},
        {"name": "Medium Purple", "color": const Color(0xFF9370DB)},
        {"name": "Steel Blue", "color": const Color(0xFF4682B4)},
        {"name": "Turquoise", "color": const Color(0xFF40E0D0)},
        {"name": "Light Sea Green", "color": const Color(0xFF20B2AA)},
        {"name": "Orchid", "color": const Color(0xFFBA55D3)},
      ];
    } else {
      _skinToneType = "Neutral Tone";
      _suggestedColors = [
        {"name": "Wheat", "color": const Color(0xFFF5DEB3)},
        {"name": "Lavender", "color": const Color(0xFFE6E6FA)},
        {"name": "Tan", "color": const Color(0xFFD2B48C)},
        {"name": "Khaki", "color": const Color(0xFFF0E68C)},
        {"name": "Silver", "color": const Color(0xFFC0C0C0)},
        {"name": "Beige", "color": const Color(0xFFF5F5DC)},
      ];
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.pink),
              title: const Text("Pick from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.pink),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid(List<Color> colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors
          .map(
            (color) => Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 1))
            ],
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildSuggestionGrid(List<Map<String, dynamic>> colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: colors
          .map(
            (item) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: item["color"],
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 1))
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item["name"],
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Custom App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    "Skin Color Palette",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        "assets/images/white_back_btn.png",
                        height: 30,
                        width: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded white section (fixed layout)
          Expanded(
            child: Container(
              width: double.infinity, // ✅ ensures full width
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                      )
                    else
                      const Icon(Icons.person, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.color_lens, color: Colors.white),
                      label: const Text(
                        "Select or Capture Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    if (_colors.isNotEmpty) ...[
                      const Text(
                        "Extracted Colors",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildColorGrid(_colors),
                      const SizedBox(height: 25),
                    ],

                    if (_skinToneType != null) ...[
                      Text(
                        "Detected: $_skinToneType",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Recommended Outfit Colors",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildSuggestionGrid(_suggestedColors),
                      const SizedBox(height: 25),
                      Text(
                        _skinToneType == "Warm Tone"
                            ? "🌞 Warm undertone detected — try coral, gold, orange, or olive hues."
                            : _skinToneType == "Cool Tone"
                            ? "❄️ Cool undertone detected — try blue, purple, turquoise, or lavender."
                            : "🌤 Neutral undertone detected — you can wear both warm and cool shades!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
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
