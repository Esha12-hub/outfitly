import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SkinToneService {
  static const String apiUrl = "https://esha129-skin-tone-classifier.hf.space/predict";

  static Future<Map<String, dynamic>> detectSkinTone(File imageFile) async {
    var request = http.MultipartRequest("POST", Uri.parse(apiUrl));

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      throw Exception("Failed: ${response.statusCode}");
    }
  }
}
