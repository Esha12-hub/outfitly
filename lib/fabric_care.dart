import 'package:flutter/material.dart';

class FabricCareAdvisorScreen extends StatelessWidget {
  const FabricCareAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> fabrics = [
      "SILK",
      "COTTON",
      "LAWN",
      "LINEN",
      "CHIFFON",
      "KHADDAR",
      "VELVET",
      "JERSEY",
      "LEATHER",
      "CRINKLE",
      "WOOL",
      "MARINA",
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

            // White rounded background section
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
                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You clicked on ${fabrics[index]}'),
                            duration: Duration(seconds: 1),
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
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Placeholder image on top
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/fabric_placeholder.png'), // replace with your placeholder
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // Fabric name below
                            Expanded(
                              child: Center(
                                child: Text(
                                  fabrics[index],
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
