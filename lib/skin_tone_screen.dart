import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'skin_tone_service.dart';
import 'color_recommender.dart';
import 'dart:math';

class SkinToneScreen extends StatefulWidget {
  @override
  _SkinToneScreenState createState() => _SkinToneScreenState();
}

class _SkinToneScreenState extends State<SkinToneScreen> {
  File? _image;
  String? prediction;
  List<String>? recommendedColors;
  String? errorMessage;
  bool _isLoading = false;

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _image = File(picked.path);
      setState(() {
        prediction = null;
        recommendedColors = null;
        errorMessage = null;
        _isLoading = true;
      });

      final ratio = await detectSkinInFlutter(_image!);
      if (ratio < 0.05) {
        setState(() {
          errorMessage = "No skin detected in the image.";
          _isLoading = false;
        });
        return;
      }

      await detectSkinTone();
      setState(() => _isLoading = false);
    }
  }

  Future<double> detectSkinInFlutter(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final imageDecoded = img.decodeImage(bytes)!;
    int skinPixels = 0;

    for (int y = 0; y < imageDecoded.height; y++) {
      for (int x = 0; x < imageDecoded.width; x++) {
        final pixel = imageDecoded.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        final maxVal = max(r, max(g, b));
        final minVal = min(r, min(g, b));
        final delta = maxVal - minVal;

        double h = 0;
        if (delta != 0) {
          if (maxVal == r) h = 60 * (((g - b) / delta) % 6);
          else if (maxVal == g) h = 60 * (((b - r) / delta) + 2);
          else h = 60 * (((r - g) / delta) + 4);
        }
        if (h < 0) h += 360;

        final s = maxVal == 0 ? 0 : delta / maxVal;
        final v = maxVal;

        if (h >= 0 && h <= 50 && s >= 0.23 && s <= 0.68 && v >= 0.35 && v <= 1.0) {
          skinPixels++;
        }
      }
    }

    return skinPixels / (imageDecoded.width * imageDecoded.height);
  }

  Future detectSkinTone() async {
    if (_image == null) return;
    final result = await SkinToneService.detectSkinTone(_image!);
    setState(() {
      prediction = result["prediction"];
      recommendedColors = ColorRecommender.recommend(prediction!);
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      "assets/images/white_back_btn.png",
                      width: width * 0.07,
                      height: width * 0.07,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Skin Tone Detector",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.07),
                ],
              ),
            ),
            SizedBox(height: height * 0.02),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: height * 0.03),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image preview
                      _image != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          height: height * 0.3,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      )
                          : Container(
                        height: height * 0.3,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text("No image selected")),
                      ),

                      SizedBox(height: height * 0.02),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade600,
                            minimumSize: Size.fromHeight(height * 0.055),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            "Upload Image",
                            style: TextStyle(
                                fontSize: 16 * textScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        )
                      else if (prediction != null && recommendedColors != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Skin Tone: $prediction",
                              style: TextStyle(
                                  fontSize: 18 * textScale,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Recommended Colors:",
                              style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 260,
                              child: GridView.builder(
                                physics: AlwaysScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: recommendedColors!.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 36,
                                  childAspectRatio: 0.7,
                                ),
                                itemBuilder: (context, index) {
                                  final colorName = recommendedColors![index];
                                  final color = ColorRecommender.getColorFromName(colorName);
                                  return Column(
                                    children: [
                                      Container(
                                        height: 50,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.black26),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        colorName,
                                        style: TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          "No prediction yet",
                          style: TextStyle(fontSize: 16),
                        ),
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
