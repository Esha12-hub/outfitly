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

  final Map<DateTime, String> _outfitDays = {};
  List<String> _wardrobeItems = [];
  String? userId;
  String? profileImageBase64;
  String? googlePhotoUrl;

  @override
  void initState() {
    super.initState();
    _getUserIdAndFetchData();
  }

  Future<void> _getUserIdAndFetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => userId = user.uid);
      if (user.photoURL != null) {
        googlePhotoUrl = user.photoURL;
      }
      await _fetchWardrobeItems();
      await _fetchOutfitDays();
      await _fetchProfileImage();
    } else {
      print("⚠️ No user logged in.");
    }
  }

  Future<void> _fetchProfileImage() async {
    if (userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('image_base64')) {
        setState(() {
          profileImageBase64 = doc['image_base64'] as String;
        });
      }
    } catch (e) {
      print("❌ Error fetching profile image: $e");
    }
  }

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
          final data = doc.data();
          if (data.containsKey('imageUrl')) return data['imageUrl'] as String;
          if (data.containsKey('image_base64')) return data['image_base64'] as String;
          return "";
        }).where((img) => img.isNotEmpty).toList();
      });
    } catch (e) {
      print("❌ Error fetching wardrobe items: $e");
    }
  }

  Future<void> _fetchOutfitDays() async {
    if (userId == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final outfits = Map<String, dynamic>.from(data['outfits'] ?? {});
        setState(() {
          _outfitDays.clear();
          outfits.forEach((dateStr, imageStr) {
            try {
              final date = DateTime.parse(dateStr);
              _outfitDays[DateTime.utc(date.year, date.month, date.day)] = imageStr as String;
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

  Future<void> _saveOutfit(DateTime date, String imageData) async {
    if (userId == null) return;
    final dateKey =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

  Future<void> _deleteOutfit(DateTime date) async {
    if (userId == null) return;
    final dateKey =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

  Widget _buildTopBar(BuildContext context, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset("assets/images/white_back_btn.png",
                height: width * 0.08, width: width * 0.08),
          ),
          Text(
            "Outfit Planner",
            style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserProfileScreen()));
            },
            child: CircleAvatar(
              radius: width * 0.045,
              backgroundColor: Colors.grey[300],
              backgroundImage: profileImageBase64 != null
                  ? MemoryImage(_decodeBase64Image(profileImageBase64!))
                  : (googlePhotoUrl != null
                  ? NetworkImage(googlePhotoUrl!)
                  : const AssetImage("assets/images/user (1).png") as ImageProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarFormatButtons(double width) {
    return Padding(
      padding: EdgeInsets.all(width * 0.04),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _buildSegmentButton("Minimal", CalendarFormat.twoWeeks, width),
            _buildSegmentButton("Compact", CalendarFormat.week, width),
            _buildSegmentButton("Full", CalendarFormat.month, width),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, CalendarFormat format, double width) {
    final isActive = _calendarFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _calendarFormat = format),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: width * 0.025),
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
              fontSize: width * 0.035,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayWithOutfit(DateTime day, double width,
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
              width: width * 0.07,
              height: width * 0.07,
              child: _buildImage(imagePath, fit: BoxFit.cover),
            ),
          SizedBox(height: width * 0.008),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: width * 0.03,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitDetailSection(DateTime date, double width) {
    final imagePath =
    _outfitDays[DateTime.utc(date.year, date.month, date.day)];
    return Column(
      children: [
        Text(
          "${_monthName(date.month)} ${date.day}, ${date.year}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: width * 0.04),
        ),
        SizedBox(height: width * 0.025),
        if (imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(
              imagePath,
              width: width * 0.8,
              height: width * 0.5,
              fit: BoxFit.contain,
            ),
          ),
        SizedBox(height: width * 0.04),
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showWardrobeSelection(date),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Edit Outfit",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            ),
            SizedBox(height: width * 0.02),
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

  Widget _buildNoOutfitSection(DateTime date, double width) {
    return Column(
      children: [
        Text(
          "${_monthName(date.month)} ${date.day}, ${date.year}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: width * 0.04),
        ),
        SizedBox(height: width * 0.025),
        const Text("No outfit added."),
        SizedBox(height: width * 0.025),
        ElevatedButton(
          onPressed: () => _showWardrobeSelection(date),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
          child: const Text("Add Outfit", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildMonthlyStatsSection(double width) {
    return Padding(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          Icon(Icons.star_border, size: width * 0.08),
          SizedBox(width: width * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("0 Day Streak",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: width * 0.035)),
              Text("Continuous calendar recording",
                  style: TextStyle(fontSize: width * 0.03)),
            ],
          ),
        ],
      ),
    );
  }

  void _showWardrobeSelection(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return Container(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select an Outfit",
                  style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
              SizedBox(height: width * 0.04),
              _wardrobeItems.isEmpty
                  ? const Text("No wardrobe items found.")
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: width > 600 ? 5 : 3,
                  crossAxisSpacing: width * 0.02,
                  mainAxisSpacing: width * 0.02,
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, width),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCalendarFormatButtons(width),
                      Padding(
                        padding: EdgeInsets.all(width * 0.04),
                        child: TableCalendar(
                          focusedDay: _focusedDay,
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                              return _buildDayWithOutfit(day, width);
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return _buildDayWithOutfit(day, width, isToday: true);
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return _buildDayWithOutfit(day, width, isSelected: true);
                            },
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextFormatter: (date, locale) {
                              final month = _monthName(date.month);
                              return "$month ${date.year}";
                            },
                            titleTextStyle: TextStyle(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            leftChevronIcon: const Icon(Icons.arrow_left, size: 28),
                            rightChevronIcon: const Icon(Icons.arrow_right, size: 28),
                          ),
                        ),
                      ),
                      if (_calendarFormat == CalendarFormat.month)
                        _buildMonthlyStatsSection(width),
                      if (_selectedDay != null && _calendarFormat != CalendarFormat.month)
                        Padding(
                          padding: EdgeInsets.all(width * 0.04),
                          child: _outfitDays.containsKey(
                              DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day))
                              ? _buildOutfitDetailSection(_selectedDay!, width)
                              : _buildNoOutfitSection(_selectedDay!, width),
                        ),
                      SizedBox(height: height * 0.1),
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
}
