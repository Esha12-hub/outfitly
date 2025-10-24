import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    double fontScale(double base) => base * (width / 390).clamp(0.8, 1.4);
    double spacing(double base) => base * (height / 844).clamp(0.8, 1.3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Padding(
          padding: EdgeInsets.only(left: spacing(80)),
          child: Text(
            'About Us',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontScale(20)),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            "assets/images/white_back_btn.png",
            height: spacing(30),
            width: spacing(30),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
        EdgeInsets.symmetric(horizontal: spacing(20), vertical: spacing(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: spacing(40),
              backgroundColor: Colors.grey,
              backgroundImage: const AssetImage("assets/images/logo_icon.png"),
            ),
            SizedBox(height: spacing(12)),
            Text(
              'Outfitly',
              style: TextStyle(
                fontSize: fontScale(24),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            SizedBox(height: spacing(20)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About Outfitly',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: fontScale(16)),
              ),
            ),
            SizedBox(height: spacing(6)),
            Text(
              'Outfitly is a smart fashion assistant app that helps you digitize your wardrobe, get personalized outfit suggestions, and manage your fashion preferences with ease. Whether you\'re planning your next look or tracking your laundry, Outfitly makes style effortless.',
              style: TextStyle(fontSize: fontScale(14)),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: spacing(20)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Core Features',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: fontScale(16)),
              ),
            ),
            SizedBox(height: spacing(8)),
            FeatureBullet(text: 'Wardrobe Digitization', fontScale: fontScale),
            FeatureBullet(text: 'AI Outfit Suggestions', fontScale: fontScale),
            FeatureBullet(text: 'Usage & Laundry Tracker', fontScale: fontScale),
            FeatureBullet(text: 'AI Fashion Assistant', fontScale: fontScale),
            FeatureBullet(
                text: 'Smart Shopping Recommendations', fontScale: fontScale),
            SizedBox(height: spacing(20)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Version Information',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: fontScale(16)),
              ),
            ),
            SizedBox(height: spacing(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('App Version: v1.0.0', style: TextStyle(fontSize: fontScale(14))),
                Text('Last Updated: May 2025', style: TextStyle(fontSize: fontScale(14))),
              ],
            ),
            SizedBox(height: spacing(20)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Connect With Us',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: fontScale(16)),
              ),
            ),
            SizedBox(height: spacing(6)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email: support@outfitlyapp.com',
                style: TextStyle(fontSize: fontScale(14)),
              ),
            ),
            SizedBox(height: spacing(30)),
            Center(
              child: Text(
                'Thank you for styling with Outfitly!',
                style: TextStyle(
                    fontStyle: FontStyle.italic, fontSize: fontScale(14)),
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
  final double Function(double) fontScale;

  const FeatureBullet({super.key, required this.text, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: fontScale(2)),
      child: Row(
        children: [
          Icon(Icons.check, size: fontScale(18), color: Colors.black87),
          SizedBox(width: fontScale(6)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontScale(14)),
            ),
          ),
        ],
      ),
    );
  }
}
