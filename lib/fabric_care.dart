import 'package:flutter/material.dart';
import 'fabric_detail.dart';

class FabricCareAdvisorScreen extends StatelessWidget {
  const FabricCareAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScale = size.width < 380 ? 0.9 : 1.0;
    final padding = size.width * 0.04;
    final isTablet = size.width > 600;

    final List<Map<String, String>> fabrics = [
      {"name": "SILK", "id": "silk_doc_id", "image": "assets/images/silk.png"},
      {"name": "COTTON", "id": "cotton_doc_id", "image": "assets/images/cotton.png"},
      {"name": "LAWN", "id": "lawn_doc_id", "image": "assets/images/lawn.png"},
      {"name": "LINEN", "id": "linen_doc_id", "image": "assets/images/linen.png"},
      {"name": "CHIFFON", "id": "chiffon_doc_id", "image": "assets/images/chiffon.png"},
      {"name": "KHADDAR", "id": "khaddar_doc_id", "image": "assets/images/khaddar.png"},
      {"name": "VELVET", "id": "velvet_doc_id", "image": "assets/images/velvet.png"},
      {"name": "JERSEY", "id": "jersey_doc_id", "image": "assets/images/jersey.png"},
      {"name": "LEATHER", "id": "leather_doc_id", "image": "assets/images/leather.png"},
      {"name": "CRINKLE", "id": "crinkle_doc_id", "image": "assets/images/crinkle.png"},
      {"name": "WOOL", "id": "wool_doc_id", "image": "assets/images/wool.png"},
      {"name": "MARINA", "id": "marina_doc_id", "image": "assets/images/marina.png"},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                padding,
                size.height * 0.02,
                padding,
                size.height * 0.018,
              ),
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/white_back_btn.png',
                        width: isTablet ? 36 : 28, height: isTablet ? 36 : 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Fabric Care Advisor",
                        textScaleFactor: textScale,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 26 : 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 60 : 48),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: size.height * 0.02),
                child: GridView.builder(
                  itemCount: fabrics.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet
                        ? 3
                        : (size.width > 450
                        ? 2
                        : 2), // more columns on large screens
                    crossAxisSpacing: size.width * 0.04,
                    mainAxisSpacing: size.height * 0.02,
                    childAspectRatio: isTablet ? 0.9 : 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final fabric = fabrics[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FabricDetailScreen(
                              fabricId: fabric['id']!,
                              fabricName: fabric['name']!,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: isTablet
                                  ? size.height * 0.22
                                  : size.height * 0.18,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                image: DecorationImage(
                                  image: AssetImage(fabric['image']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  fabric['name']!,
                                  textAlign: TextAlign.center,
                                  textScaleFactor: textScale,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isTablet ? 20 : 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
