import 'package:flutter/material.dart';

class OutfitDetailScreen extends StatefulWidget {
  const OutfitDetailScreen({super.key});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  String selectedButton = 'Save';

  final List<Map<String, dynamic>> buttons = [
    {'label': 'Like', 'icon': Icons.favorite_border},
    {'label': 'Save', 'icon': Icons.bookmark_border},
    {'label': 'AR-Try on', 'icon': Icons.view_in_ar},
    {'label': 'Share', 'icon': Icons.share},
  ];

  @override
  Widget build(BuildContext context) {
    const String image = 'assets/images/outfit2.png';
    const String title = 'Casual Streetwear';
    const String occasion = 'Weekend Outing';
    const String season = 'Spring';
    const List<String> moods = ['Relaxed', 'Trendy'];
    const List<Color> colors = [Colors.black, Colors.white, Colors.blueAccent];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
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
                  const Spacer(),
                  const Text(
                    'Outfit Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  image,
                                  height: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 250,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _infoRow(Icons.event, 'Occasion', occasion),
                                  const SizedBox(height: 8),
                                  _infoRow(Icons.cloud, 'Season', season),
                                  const SizedBox(height: 8),
                                  _infoRow(Icons.emoji_emotions, 'Mood', moods.join(', ')),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.color_lens, size: 20),
                                          SizedBox(width: 6),
                                          Text('Color Theme', style: TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      Row(
                                        children: colors
                                            .map((color) => Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                        ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            const Text('Items Included List',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(2),
                              },
                              border: TableBorder.all(color: Colors.grey.shade300),
                              children: const [
                                TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                TableRow(children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('Sweatshirt')),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircleAvatar(backgroundColor: Colors.orange, radius: 6),
                                  ),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Cozy fabric, oversized fit')),
                                ]),
                                TableRow(children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('Skirt')),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(backgroundColor: Colors.red, radius: 6),
                                        SizedBox(width: 4),
                                        CircleAvatar(backgroundColor: Colors.orange, radius: 6),
                                      ],
                                    ),
                                  ),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Knee-length, flared cut')),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildButtonColumn(['Like', 'AR-Try on']),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _buildButtonColumn(['Save', 'Share']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtonColumn(List<String> labels) {
    const double buttonWidth = 170;
    const Color activeColor = Color(0xFFE91E63);
    const Color borderColor = Colors.black;

    return labels.map((label) {
      final button = buttons.firstWhere((b) => b['label'] == label);
      final isSelected = selectedButton == label;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: buttonWidth,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                selectedButton = label;
              });
            },
            icon: Icon(
              button['icon'],
              color: isSelected ? Colors.white : borderColor,
            ),
            label: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : borderColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? activeColor : Colors.white,
              side: const BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.grey),
          ),
        )
      ],
    );
  }
}