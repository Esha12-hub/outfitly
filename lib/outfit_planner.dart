import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'user_profile_screen.dart';

class OutfitCalendarScreen extends StatefulWidget {
  @override
  _OutfitCalendarScreenState createState() => _OutfitCalendarScreenState();
}

class _OutfitCalendarScreenState extends State<OutfitCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Stores selected outfits for each day
  final Map<DateTime, String> _outfitDays = {};

  /// Wardrobe items (list of images from Firestore, base64 or URL)
  List<String> _wardrobeItems = [];

  String? userId; // ✅ Dynamic user ID

  @override
  void initState() {
    super.initState();
    _getUserIdAndFetchData();
  }

  /// Get logged-in user ID and fetch wardrobe/outfits
  Future<void> _getUserIdAndFetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => userId = user.uid);
      await _fetchWardrobeItems();
      await _fetchOutfitDays();
    } else {
      print("⚠️ No user logged in.");
    }
  }

  /// ✅ Fetch wardrobe items of logged-in user
  Future<void> _fetchWardrobeItems() async {
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .get();

      setState(() {
        _wardrobeItems = snapshot.docs.map((doc) {
          if (doc.data().containsKey('imageUrl')) {
            return doc['imageUrl'] as String;
          } else if (doc.data().containsKey('image_base64')) {
            return doc['image_base64'] as String;
          } else {
            return "";
          }
        }).where((img) => img.isNotEmpty).toList();
      });
    } catch (e) {
      print("❌ Error fetching wardrobe items: $e");
    }
  }

  /// ✅ Fetch saved outfits from Firestore
  Future<void> _fetchOutfitDays() async {
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final outfits = Map<String, dynamic>.from(data['outfits'] ?? {});

        setState(() {
          _outfitDays.clear();
          outfits.forEach((dateStr, imageStr) {
            try {
              final date = DateTime.parse(dateStr);
              _outfitDays[DateTime.utc(date.year, date.month, date.day)] =
              imageStr as String;
            } catch (e) {
              print("⚠️ Invalid date format in Firestore: $dateStr");
            }
          });
        });
      }
    } catch (e) {
      print("❌ Error fetching outfits: $e");
    }
  }

  /// ✅ Save outfit selection to Firestore
  Future<void> _saveOutfit(DateTime date, String imageData) async {
    if (userId == null) return;

    final dateKey =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          "outfits": {dateKey: imageData}
        },
        SetOptions(merge: true),
      );

      setState(() {
        _outfitDays[DateTime.utc(date.year, date.month, date.day)] = imageData;
      });
    } catch (e) {
      print("❌ Error saving outfit: $e");
    }
  }

  /// ✅ Delete outfit from Firestore and local state
  Future<void> _deleteOutfit(DateTime date) async {
    if (userId == null) return;

    final dateKey =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          "outfits": {dateKey: FieldValue.delete()}
        },
        SetOptions(merge: true),
      );

      setState(() {
        _outfitDays.remove(DateTime.utc(date.year, date.month, date.day));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit deleted successfully")),
      );
    } catch (e) {
      print("❌ Error deleting outfit: $e");
    }
  }

  /// ✅ Detect Base64 vs URL
  bool _isBase64(String str) {
    try {
      if (str.startsWith("http")) return false;
      base64Decode(str.split(",").last);
      return true;
    } catch (_) {
      return false;
    }
  }

  Uint8List _decodeBase64Image(String base64String) {
    return base64Decode(base64String.split(',').last);
  }

  /// ✅ Custom image widget
  Widget _buildImage(String data,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (_isBase64(data)) {
      return Image.memory(
        _decodeBase64Image(data),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      return Image.network(
        data,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCalendarFormatButtons(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TableCalendar(
                          focusedDay: _focusedDay,
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                              _selectedDay = selectedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              return _buildDayWithOutfit(day);
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return _buildDayWithOutfit(day, isToday: true);
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return _buildDayWithOutfit(day, isSelected: true);
                            },
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle:
                            TextStyle(fontWeight: FontWeight.bold),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextFormatter: (date, locale) {
                              final month = _monthName(date.month);
                              return "$month ${date.year}";
                            },
                            titleTextStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            leftChevronIcon:
                            const Icon(Icons.arrow_left, size: 28),
                            rightChevronIcon:
                            const Icon(Icons.arrow_right, size: 28),
                          ),
                        ),
                      ),
                      if (_calendarFormat == CalendarFormat.month)
                        _buildMonthlyStatsSection(),
                      if (_selectedDay != null &&
                          _calendarFormat != CalendarFormat.month)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _outfitDays.containsKey(DateTime.utc(
                              _selectedDay!.year,
                              _selectedDay!.month,
                              _selectedDay!.day))
                              ? _buildOutfitDetailSection(_selectedDay!)
                              : _buildNoOutfitSection(_selectedDay!),
                        ),
                      const SizedBox(height: 80),
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

  /// ---------- UI HELPERS ----------

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset("assets/images/white_back_btn.png",
                height: 30, width: 30),
          ),
          const Text(
            "Outfit Planner",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
            child: const CircleAvatar(
              backgroundImage: AssetImage("assets/images/user (1).png"),
              radius: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarFormatButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _buildSegmentButton("Minimal", CalendarFormat.twoWeeks),
            _buildSegmentButton("Compact", CalendarFormat.week),
            _buildSegmentButton("Full", CalendarFormat.month),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, CalendarFormat format) {
    final isActive = _calendarFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _calendarFormat = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.pink : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayWithOutfit(DateTime day,
      {bool isToday = false, bool isSelected = false}) {
    final imagePath = _outfitDays[DateTime.utc(day.year, day.month, day.day)];

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected
            ? Colors.black
            : isToday
            ? Colors.pink.shade100
            : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imagePath != null)
            SizedBox(
              width: 25,
              height: 25,
              child: _buildImage(imagePath, fit: BoxFit.cover),
            ),
          const SizedBox(height: 2),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitDetailSection(DateTime date) {
    final imagePath =
    _outfitDays[DateTime.utc(date.year, date.month, date.day)];

    return Column(
      children: [
        Text(
          "${_monthName(date.month)} ${date.day}, ${date.year}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(
              imagePath,
              width: MediaQuery.of(context).size.width * 0.8,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        const SizedBox(height: 16),

        /// ✅ Edit + Delete buttons
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showWardrobeSelection(date),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Edit Outfit",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _deleteOutfit(date),
              icon: const Icon(Icons.delete, color: Colors.pink),
              label: const Text("Delete Outfit",
                  style: TextStyle(color: Colors.pink)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoOutfitSection(DateTime date) {
    return Column(
      children: [
        Text(
          "${_monthName(date.month)} ${date.day}, ${date.year}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        const Text("No outfit added."),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _showWardrobeSelection(date),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
          child:
          const Text("Add Outfit", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildMonthlyStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          Icon(Icons.star_border, size: 30),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("0 Day Streak",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Continuous calendar recording"),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Wardrobe selection bottom sheet
  void _showWardrobeSelection(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select an Outfit",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _wardrobeItems.isEmpty
                  ? const Text("No wardrobe items found.")
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _wardrobeItems.length,
                itemBuilder: (context, index) {
                  final itemImg = _wardrobeItems[index];
                  return GestureDetector(
                    onTap: () {
                      _saveOutfit(date, itemImg);
                      Navigator.pop(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(itemImg, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}
