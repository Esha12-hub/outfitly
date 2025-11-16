import 'package:flutter/material.dart';
import 'smart_assistant.dart';

class SmartAssistantWelcomeScreen extends StatelessWidget {
  const SmartAssistantWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.06;
    final imageHeight = size.height * 0.6;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FC),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Image.asset(
                'assets/images/ai_welcome.png',
                height: imageHeight,
                fit: BoxFit.contain,
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatbotScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Start Conversation',
                      style: TextStyle(fontSize: size.width * 0.042, color: Colors.white), // responsive font
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Go Back',
                      style: TextStyle(fontSize: size.width * 0.042, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.04),
          ],
        ),
      ),
    );
  }
}
