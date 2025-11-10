import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'writer_login_screen.dart';

class SeoAnalyzerScreen extends StatefulWidget {
  const SeoAnalyzerScreen({super.key});

  @override
  State<SeoAnalyzerScreen> createState() => _SeoAnalyzerScreenState();
}

class _SeoAnalyzerScreenState extends State<SeoAnalyzerScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic> _seoReport = {};

  Future<void> _analyzeContent() async {
    String content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _loading = true;
      _seoReport = {};
    });

    await Future.delayed(const Duration(milliseconds: 100));

    int wordCount = content.split(RegExp(r'\s+')).length;

    List<String> headings = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty && line.trim()[0] == '#')
        .map((e) => e.replaceAll('#', '').trim())
        .toList();

    final commonWords = [
      'the', 'a', 'an', 'and', 'or', 'in', 'on', 'at', 'of', 'for', 'to', 'with',
      'by', 'is', 'are', 'was', 'were', 'it', 'this', 'that', 'i', 'you', 'he', 'she', 'they'
    ];

    Map<String, int> freq = {};
    List<String> words = content
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'));
    for (var word in words) {
      if (word.isEmpty || commonWords.contains(word)) continue;
      freq[word] = (freq[word] ?? 0) + 1;
    }

    List<String> keywords = freq.entries
        .sortedBy((e) => -e.value)
        .take(10)
        .map((e) => e.key)
        .toList();

    int sentenceCount = content.split(RegExp(r'[.!?]')).length;
    int syllableCount = content
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '')
        .split('')
        .where((c) => 'aeiou'.contains(c))
        .length;

    double readability = wordCount > 0 && sentenceCount > 0
        ? 206.835 - 1.015 * (wordCount / sentenceCount) - 84.6 * (syllableCount / wordCount)
        : 0;

    List<String> improvementTips = [];
    if (wordCount < 300) improvementTips.add('Consider adding more content.');
    if (headings.isEmpty) improvementTips.add('Add headings (# or ##) for better structure.');
    if (keywords.length < 5) improvementTips.add('Use more keywords naturally.');

    setState(() {
      _seoReport = {
        'word_count': wordCount,
        'headings': headings,
        'keywords': keywords,
        'readability': readability.toStringAsFixed(2),
        'improvement_tips': improvementTips,
      };
      _loading = false;
    });
  }

  Widget _buildSeoCard(String title, String value, double fontSize) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.pink)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: fontSize * 0.85)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadabilityChart(String readabilityStr, double size) {
    double readability = double.tryParse(readabilityStr) ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: readability,
                      color: Colors.pink,
                      radius: size * 0.2,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - readability,
                      color: Colors.grey.shade300,
                      radius: size * 0.2,
                      showTitle: false,
                    ),
                  ],
                  sectionsSpace: 0,
                  centerSpaceRadius: size * 0.15,
                ),
              ),
              Text(
                "${readability.toStringAsFixed(1)}%",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.10,
                    color: Colors.pink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Readability",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            child: const Text("No", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WriterLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final fontSize = screenWidth * 0.045;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "Offline SEO Analyzer",
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: _handleLogout,
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Image.asset('assets/images/white_back_btn.png',height: 10,width: 10,),
          ),
        ),
      ),

      body: Center(
        child: Container(
          width: screenWidth * 0.99,
          height: screenHeight * 0.99,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, vertical: screenHeight * 0.03),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 6,
                style: TextStyle(fontSize: fontSize * 0.9),
                decoration: InputDecoration(
                  hintText: "Paste your content here",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: fontSize * 0.8, vertical: fontSize * 0.8),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _analyzeContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade600,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Analyze SEO",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Expanded(
                child: _seoReport.isEmpty
                    ? Center(
                    child: Text("SEO report will appear here",
                        style: TextStyle(fontSize: fontSize)))
                    : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_seoReport.containsKey("word_count"))
                        _buildSeoCard("Word Count",
                            _seoReport["word_count"].toString(),
                            fontSize),
                      if (_seoReport.containsKey("headings"))
                        _buildSeoCard(
                          "Headings",
                          (_seoReport["headings"] as List).isEmpty
                              ? "No headings found"
                              : (_seoReport["headings"] as List)
                              .join(", "),
                          fontSize,
                        ),
                      if (_seoReport.containsKey("keywords"))
                        _buildSeoCard(
                          "Keywords",
                          (_seoReport["keywords"] as List).isEmpty
                              ? "No keywords found"
                              : (_seoReport["keywords"] as List)
                              .join(", "),
                          fontSize,
                        ),
                      if (_seoReport.containsKey("improvement_tips"))
                        _buildSeoCard(
                          "Improvement Tips",
                          (_seoReport["improvement_tips"] as List).isEmpty
                              ? "No tips"
                              : (_seoReport["improvement_tips"] as List)
                              .join("\n"),
                          fontSize,
                        ),
                      if (_seoReport.containsKey("readability"))
                        Center(
                          child: _buildReadabilityChart(
                              _seoReport["readability"], screenWidth * 0.5),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
