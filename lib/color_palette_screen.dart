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

  Widget _buildColorGrid(List<Color> colors, double width) {
    return Wrap(
      spacing: width * 0.02,
      runSpacing: width * 0.02,
      children: colors
          .map(
            (color) => Container(
          width: width * 0.12,
          height: width * 0.12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(width * 0.03),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 1))
            ],
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildSuggestionGrid(List<Map<String, dynamic>> colors, double width) {
    return Wrap(
      spacing: width * 0.03,
      runSpacing: width * 0.03,
      children: colors
          .map(
            (item) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width * 0.14,
              height: width * 0.14,
              decoration: BoxDecoration(
                color: item["color"],
                borderRadius: BorderRadius.circular(width * 0.03),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 1))
                ],
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: width * 0.16,
              child: Text(
                item["name"],
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.025),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "Skin Color Palette",
                    style: TextStyle(
                      fontSize: width * 0.05,
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
                        height: width * 0.08,
                        width: width * 0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.06)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(width * 0.04),
                        child: Image.file(_image!, height: height * 0.28, fit: BoxFit.cover),
                      )
                    else
                      Icon(Icons.person, size: width * 0.25, color: Colors.grey),
                    SizedBox(height: height * 0.025),
                    ElevatedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.color_lens, color: Colors.white),
                      label: const Text(
                        "Select or Capture Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: height * 0.015),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.05),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    if (_colors.isNotEmpty) ...[
                      Text(
                        "Extracted Colors",
                        style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: height * 0.015),
                      _buildColorGrid(_colors, width),
                      SizedBox(height: height * 0.03),
                    ],
                    if (_skinToneType != null) ...[
                      Text(
                        "Detected: $_skinToneType",
                        style: TextStyle(
                          fontSize: width * 0.048,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: height * 0.015),
                      Text(
                        "Recommended Outfit Colors",
                        style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: height * 0.015),
                      _buildSuggestionGrid(_suggestedColors, width),
                      SizedBox(height: height * 0.03),
                      Text(
                        _skinToneType == "Warm Tone"
                            ? "🌞 Warm undertone detected — try coral, gold, orange, or olive hues."
                            : _skinToneType == "Cool Tone"
                            ? "❄️ Cool undertone detected — try blue, purple, turquoise, or lavender."
                            : "🌤 Neutral undertone detected — you can wear both warm and cool shades!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: width * 0.037, color: Colors.black87),
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
