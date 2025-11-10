import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class OutfitAPI {
  static const String apiUrl = "https://maham234-outfit-sug.hf.space/predict";

  static Future<Map<String, dynamic>> getSuggestions({
    required List<File> shirts,
    required List<File> pants,
    List<File>? shoes, // ✅ Optional
  }) async {
    final uri = Uri.parse(apiUrl);
    final request = http.MultipartRequest('POST', uri);

    // ✅ Must match FastAPI variable names
    for (final file in shirts) {
      request.files.add(await http.MultipartFile.fromPath('shirts', file.path));
    }

    for (final file in pants) {
      request.files.add(await http.MultipartFile.fromPath('pants', file.path));
    }

    // ✅ Add shoes only if selected
    if (shoes != null && shoes.isNotEmpty) {
      for (final file in shoes) {
        request.files.add(await http.MultipartFile.fromPath('shoes', file.path));
      }
    }

    final response = await http.Response.fromStream(await request.send());
    print("➡️ Sent request to $apiUrl → ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }
}
