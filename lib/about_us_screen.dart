import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Padding(
          padding: const EdgeInsets.only(left: 80),
          child: const Text(
            'About Us',
            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset("assets/images/white_back_btn.png", height: 30, width: 30),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage("assets/images/logo_icon.png"),
            ),
            const SizedBox(height: 12),
            const Text(
              'Outfitly',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About Outfitly',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Outfitly is a smart fashion assistant app that helps you digitize your wardrobe, get personalized outfit suggestions, and manage your fashion preferences with ease. Whether you\'re planning your next look or tracking your laundry, Outfitly makes style effortless.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Core Features',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            const FeatureBullet(text: 'Wardrobe Digitization'),
            const FeatureBullet(text: 'AI Outfit Suggestions'),
            const FeatureBullet(text: 'Usage & Laundry Tracker'),
            const FeatureBullet(text: 'AI Fashion Assistant'),
            const FeatureBullet(text: 'Smart Shopping Recommendations'),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Version Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('App Version: v1.0.0'),
                Text('Last Updated: May 2025'),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Connect With Us',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email: support@outfitlyapp.com',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Thank you for styling with Outfitly!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureBullet extends StatelessWidget {
  final String text;

  const FeatureBullet({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
