import 'package:flutter/material.dart';
import 'fabric_detail.dart'; // import FabricDetailScreen

class FabricCareAdvisorScreen extends StatelessWidget {
  const FabricCareAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> fabrics = [
      {"name": "SILK", "id": "silk_doc_id"},
      {"name": "COTTON", "id": "cotton_doc_id"},
      {"name": "LAWN", "id": "lawn_doc_id"},
      {"name": "LINEN", "id": "linen_doc_id"},
      {"name": "CHIFFON", "id": "chiffon_doc_id"},
      {"name": "KHADDAR", "id": "khaddar_doc_id"},
      {"name": "VELVET", "id": "velvet_doc_id"},
      {"name": "JERSEY", "id": "jersey_doc_id"},
      {"name": "LEATHER", "id": "leather_doc_id"},
      {"name": "CRINKLE", "id": "crinkle_doc_id"},
      {"name": "WOOL", "id": "wool_doc_id"},
      {"name": "MARINA", "id": "marina_doc_id"},
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text(
                    "Fabric Care Advisor",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white),
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
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                image: DecorationImage(
                                  image: AssetImage('assets/images/fabric_placeholder.png'),
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
