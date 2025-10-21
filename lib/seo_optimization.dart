import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';

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

    await Future.delayed(const Duration(milliseconds: 100)); // simulate loading

    // Word count
    int wordCount = content.split(RegExp(r'\s+')).length;

    // Headings (lines starting with #)
    List<String> headings = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty && line.trim()[0] == '#')
        .map((e) => e.replaceAll('#', '').trim())
        .toList();

    // Simple keyword extraction: top 10 frequent words excluding common words
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

    // Keyword density (%)
    Map<String, double> keywordDensity = {};
    for (var word in keywords) {
      keywordDensity[word] =
          (RegExp('\\b$word\\b').allMatches(content).length / wordCount) * 100;
    }

    // Readability: Flesch Reading Ease approximation
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

    // Improvement tips
    List<String> improvementTips = [];
    if (wordCount < 300) improvementTips.add('Consider adding more content.');
    if (headings.isEmpty) improvementTips.add('Add headings (# or ##) for better structure.');
    if (keywords.length < 5) improvementTips.add('Use more keywords naturally.');

    setState(() {
      _seoReport = {
        'word_count': wordCount,
        'headings': headings,
        'keywords': keywords,
        'keyword_density': keywordDensity,
        'readability': readability.toStringAsFixed(2),
        'improvement_tips': improvementTips,
      };
      _loading = false;
    });
  }

  Widget _buildSeoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 6),
            Text(value)
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordDensityChart(Map<String, double> density) {
    List<BarChartGroupData> bars = [];
    int index = 0;
    density.forEach((key, value) {
      bars.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 20,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          )
        ],
        showingTooltipIndicators: [0],
      ));
      index++;
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int i = value.toInt();
                    if (i >= 0 && i < density.keys.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(density.keys.elementAt(i),
                            style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const SizedBox();
                  }),
            ),
          ),
          barGroups: bars,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline SEO Analyzer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 10,
              decoration: const InputDecoration(
                  hintText: "Paste your content here",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _analyzeContent,
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Analyze SEO"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _seoReport.isEmpty
                  ? const Center(child: Text("SEO report will appear here"))
                  : ListView(
                children: [
                  if (_seoReport.containsKey("word_count"))
                    _buildSeoCard(
                        "Word Count", _seoReport["word_count"].toString()),
                  if (_seoReport.containsKey("headings"))
                    _buildSeoCard(
                        "Headings",
                        (_seoReport["headings"] as List).isEmpty
                            ? "No headings found"
                            : (_seoReport["headings"] as List).join(", ")),
                  if (_seoReport.containsKey("keywords"))
                    _buildSeoCard(
                        "Keywords",
                        (_seoReport["keywords"] as List).isEmpty
                            ? "No keywords found"
                            : (_seoReport["keywords"] as List).join(", ")),
                  if (_seoReport.containsKey("readability"))
                    _buildSeoCard(
                        "Readability", _seoReport["readability"]),
                  if (_seoReport.containsKey("improvement_tips"))
                    _buildSeoCard(
                        "Improvement Tips",
                        (_seoReport["improvement_tips"] as List).isEmpty
                            ? "No tips"
                            : (_seoReport["improvement_tips"] as List)
                            .join("\n")),
                  if (_seoReport.containsKey("keyword_density"))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text("Keyword Density (%)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue)),
                        const SizedBox(height: 8),
                        _buildKeywordDensityChart(
                            _seoReport["keyword_density"]
                            as Map<String, double>),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
