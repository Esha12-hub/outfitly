import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FabricDetailScreen extends StatefulWidget {
  final String fabricId;
  final String fabricName;

  const FabricDetailScreen({
    Key? key,
    required this.fabricId,
    required this.fabricName,
  }) : super(key: key);

  @override
  State<FabricDetailScreen> createState() => _FabricDetailScreenState();
}

class _FabricDetailScreenState extends State<FabricDetailScreen> {
  late Future<DocumentSnapshot> fabricFuture;

  @override
  void initState() {
    super.initState();
    fabricFuture = _loadFabricData();
  }

  Future<DocumentSnapshot> _loadFabricData() {
    return FirebaseFirestore.instance.collection('fabrics').doc(widget.fabricId).get();
  }

  void _refreshData() {
    setState(() {
      fabricFuture = _loadFabricData();
    });
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  List<String> _splitText(dynamic field) {
    if (field == null) return ["No data"];
    if (field is List) {
      return field.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return field
        .toString()
        .split(RegExp(r'\.|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final formattedName = capitalizeFirstLetter(widget.fabricName);
    final localAssetPath = 'assets/images/${widget.fabricName.toLowerCase()}.png';

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: fabricFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.pink));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('No fabric data found.', style: TextStyle(color: Colors.white)),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl']?.toString() ?? '';

            return LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final padding = isTablet ? 28.0 : 20.0;
                final titleSize = isTablet ? 26.0 : 20.0;
                final headingSize = isTablet ? 24.0 : 22.0;
                final bodyFontSize = isTablet ? 16.0 : 14.5;
                final iconSize = isTablet ? 30.0 : 24.0;

                return Column(
                  children: [
                    // ===== Top Bar =====
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 18),
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Back Button (Left)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Image.asset('assets/images/white_back_btn.png', width: 28, height: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),

                          // Center Title
                          Center(
                            child: Text(
                              "$formattedName Fabric Care",
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: titleSize,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Refresh Icon (Right)
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _refreshData,
                              child: Icon(Icons.refresh, color: Colors.white, size: iconSize),
                            ),
                          ),
                        ],
                      ),
                    ),


                    // ===== Body =====
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(padding),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== Image Section =====
                              Center(
                                child: Container(
                                  height: screenHeight * 0.25,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.pink.shade50,
                                    image: DecorationImage(
                                      image: imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : AssetImage(localAssetPath) as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 32 : 24),

                              // ===== Title =====
                              Text(
                                "How to Care for $formattedName",
                                style: TextStyle(
                                  fontSize: headingSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ===== Care Cards =====
                              _CareCard(
                                icon: FontAwesomeIcons.water,
                                title: "Washing",
                                steps: _splitText(data['washing']),
                                fontSize: bodyFontSize,
                                iconSize: iconSize,
                              ),
                              _CareCard(
                                icon: FontAwesomeIcons.wind,
                                title: "Drying",
                                steps: _splitText(data['drying']),
                                fontSize: bodyFontSize,
                                iconSize: iconSize,
                              ),
                              _CareCard(
                                icon: FontAwesomeIcons.temperatureLow,
                                title: "Ironing",
                                steps: _splitText(data['ironing']),
                                fontSize: bodyFontSize,
                                iconSize: iconSize,
                              ),
                              _CareCard(
                                icon: FontAwesomeIcons.boxArchive,
                                title: "Storage",
                                steps: _splitText(data['storage']),
                                fontSize: bodyFontSize,
                                iconSize: iconSize,
                              ),

                              const SizedBox(height: 30),

                              // ===== Icon Summary Row =====
                              Text(
                                "Quick Reminders",
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _CareIcon(icon: FontAwesomeIcons.handSparkles, label: "Hand Wash", iconSize: iconSize),
                                  _CareIcon(icon: FontAwesomeIcons.wind, label: "Air Dry", iconSize: iconSize),
                                  _CareIcon(icon: FontAwesomeIcons.temperatureLow, label: "Low Iron", iconSize: iconSize),
                                  _CareIcon(icon: FontAwesomeIcons.box, label: "Fold Dry", iconSize: iconSize),
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ===== Reusable Care Section Card =====
class _CareCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> steps;
  final double fontSize;
  final double iconSize;

  const _CareCard({
    required this.icon,
    required this.title,
    required this.steps,
    required this.fontSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, color: Colors.pink.shade400, size: iconSize),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize + 2,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map(
                (step) => Padding(
              padding: const EdgeInsets.only(left: 6, top: 4),
              child: Text(
                "• $step",
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Small Icon + Label Component =====
class _CareIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;

  const _CareIcon({required this.icon, required this.label, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.pink.shade400, size: iconSize),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
