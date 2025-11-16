import 'package:flutter/material.dart';
import 'user_login_screen.dart';
import 'writer_login_screen.dart';
import 'main.dart';

class ContinueAsScreen extends StatelessWidget {
  const ContinueAsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.06;
    final spacingLarge = screenHeight * 0.05;
    final spacingMedium = screenHeight * 0.03;
    final spacingSmall = screenHeight * 0.015;

    final titleFontSize = screenHeight * 0.035;
    final subtitleFontSize = screenHeight * 0.02;
    final roleTitleFontSize = screenHeight * 0.025;
    final roleSubtitleFontSize = screenHeight * 0.017;
    final iconSize = screenHeight * 0.045;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyApp()),
              (route) => false,
        );
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                "assets/images/background.png",
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MyApp()),
                                (route) => false,
                          );
                        },
                        child: SizedBox(
                          height: screenHeight * 0.04,
                          width: screenHeight * 0.04,
                          child: Image.asset("assets/images/back btn.png"),
                        ),
                      ),

                      SizedBox(height: spacingLarge),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              "Continue As",
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: spacingSmall),
                            Text(
                              "Choose your role to proceed",
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: spacingMedium),

                      _roleOptionTile(
                        context,
                        icon: Icons.person,
                        title: "User",
                        subtitle:
                        "Explore your wardrobe and get AI outfit suggestions",
                        iconSize: iconSize,
                        titleFontSize: roleTitleFontSize,
                        subtitleFontSize: roleSubtitleFontSize,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserLoginScreen(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: spacingMedium),

                      _roleOptionTile(
                        context,
                        icon: Icons.edit,
                        title: "Content Writer",
                        subtitle:
                        "Contribute articles, tips, and style advice.",
                        iconSize: iconSize,
                        titleFontSize: roleTitleFontSize,
                        subtitleFontSize: roleSubtitleFontSize,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WriterLoginScreen(),
                            ),
                          );
                        },
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

  Widget _roleOptionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required double iconSize,
        required double titleFontSize,
        required double subtitleFontSize,
        required VoidCallback onTap,
      }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalPadding = screenHeight * 0.025;
    final horizontalPadding = screenWidth * 0.04;
    final borderRadius = screenHeight * 0.015;
    final spacing = screenHeight * 0.015;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: Colors.black),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.black54,
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
}
