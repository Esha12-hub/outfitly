import 'package:flutter/material.dart';
import 'fabric_detail.dart'; // import FabricDetailScreen

class FabricCareAdvisorScreen extends StatelessWidget {
  const FabricCareAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            // Custom AppBar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Fabric Care Advisor",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the space of the back button
                ],
              ),

            ),

            // White rounded section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: GridView.builder(
                  itemCount: fabrics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
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
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                image: DecorationImage(
                                  image: AssetImage(fabric['image']!), // ✅ Dynamic image
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  fabric['name']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
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
