import 'package:flutter/material.dart';

class InteractiveFeaturesScreen extends StatefulWidget {
  const InteractiveFeaturesScreen({super.key});

  @override
  State<InteractiveFeaturesScreen> createState() => _InteractiveFeaturesScreenState();
}

class _InteractiveFeaturesScreenState extends State<InteractiveFeaturesScreen> {
  String? selectedButton;

  void _selectButton(String button) {
    setState(() {
      selectedButton = button;
    });
  }

  final String? videoThumbnail = null; // ← Set to null to simulate "no video"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Interactive Features',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),


            // White Rounded Sheet
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      // Video Section (optional)
                      videoThumbnail != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              videoThumbnail!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                          ],
                        ),
                      )
                          : Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Feature Tiles
                      const _FeatureTile(
                        icon: Icons.checkroom,
                        title: 'Tag Outfit Item',
                        subtitle: 'Add label',
                        time: '1:10',
                      ),
                      const _FeatureTile(
                        icon: Icons.link,
                        title: 'Insert Product Link',
                        subtitle: 'Paste URL',
                        time: '1:10',
                      ),
                      const _FeatureTile(
                        icon: Icons.brush,
                        title: 'Add Styling Tip',
                        subtitle: 'Add text',
                        time: '1:10',
                      ),
                      const _FeatureTile(
                        icon: Icons.poll,
                        title: 'Insert Poll',
                        subtitle: 'Add a question',
                        time: null,
                      ),

                      const SizedBox(height: 24),

                      // Selectable Action Buttons
                      Row(
                        children: [
                          _SelectableButton(
                            text: 'Save Draft',
                            isSelected: selectedButton == 'Save Draft',
                            onTap: () => _selectButton('Save Draft'),
                          ),
                          const SizedBox(width: 8),
                          _SelectableButton(
                            text: 'Preview',
                            isSelected: selectedButton == 'Preview',
                            onTap: () => _selectButton('Preview'),
                          ),
                          const SizedBox(width: 8),
                          _SelectableButton(
                            text: 'Submit',
                            isSelected: selectedButton == 'Submit',
                            onTap: () => _selectButton('Submit'),
                          ),
                        ],
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

// Reusable feature tile widget
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? time;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          if (time != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(time!, style: const TextStyle(fontSize: 12)),
            )
          else
            const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

// Reusable bottom button widget
class _SelectableButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color:Colors.black54),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}