import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'weaher_clothes.dart';
import 'settings_screen.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  // 🌍 Get user location
  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 📍 Get city name from coordinates
  Future<String> getCityName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      return placemarks.isNotEmpty ? (placemarks.first.locality ?? 'Unknown') : 'Unknown';
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return 'Unknown';
    }
  }

  // ☁️ Fetch weather
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    const apiKey = '376bd53e40e29b0e441ecfa33c0f05b0';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load weather data');
  }

  Future<Map<String, dynamic>> getWeatherData() async {
    try {
      final position = await getUserLocation();
      final cityName = await getCityName(position.latitude, position.longitude);
      final weather = await fetchWeather(position.latitude, position.longitude);
      weather.remove('name');
      weather['city_name'] = (cityName.isNotEmpty && cityName != 'Unknown') ? cityName : 'Unknown';
      return weather;
    } catch (e) {
      print('Error fetching weather: $e');
      const fallbackLat = 32.0836;
      const fallbackLon = 72.6711;
      final weather = await fetchWeather(fallbackLat, fallbackLon);
      weather.remove('name');
      weather['city_name'] = 'Sahiwal';
      return weather;
    }
  }

  String getClothingSuggestion(double temp, String gender) {
    if (gender.toLowerCase() == 'male') {
      if (temp >= 30) return "Hot! Light cotton shalwar kameez or t-shirts.";
      if (temp >= 20) return "Warm. Light shirts or jeans.";
      if (temp >= 10) return "Cool. Sweaters or jackets.";
      if (temp >= 0) return "Cold! Heavy jackets or coats.";
      return "Freezing! Layered clothes and scarves.";
    } else if (gender.toLowerCase() == 'female') {
      if (temp >= 30) return "Hot! Light cotton shalwar kameez or frocks.";
      if (temp >= 20) return "Warm. Kurtis or casual dresses.";
      if (temp >= 10) return "Cool. Sweaters, shawls, or jackets.";
      if (temp >= 0) return "Cold! Heavy coats or woolen shawls.";
      return "Freezing! Layered clothes and gloves.";
    } else return "Dress appropriately for the temperature.";
  }

  String getWeatherImage(Map<String, dynamic> weather) {
    final condition = (weather['weather']?[0]?['main'] ?? '').toString().toLowerCase();
    final sunrise = weather['sys']?['sunrise'] ?? 0;
    final sunset = weather['sys']?['sunset'] ?? 0;
    final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final isDay = currentTime >= sunrise && currentTime < sunset;

    if (condition.contains('clear')) return isDay ? 'assets/images/clear.png' : 'assets/images/clear_night.png';
    if (condition.contains('cloud')) return 'assets/images/cloudy.png';
    if (condition.contains('rain')) return 'assets/images/rain.png';
    if (condition.contains('drizzle')) return 'assets/images/drizzle.png';
    if (condition.contains('thunder')) return 'assets/images/thunderstorm.png';
    if (condition.contains('snow')) return 'assets/images/snow.png';
    if (condition.contains('mist')) return 'assets/images/mist.png';
    if (condition.contains('fog')) return 'assets/images/fog.png';
    if (condition.contains('haze')) return 'assets/images/haze.png';
    if (condition.contains('smoke')) return 'assets/images/smoke.png';
    if (condition.contains('dust')) return 'assets/images/dust.png';
    if (condition.contains('sand')) return 'assets/images/sand.png';
    if (condition.contains('tornado')) return 'assets/images/tornado.png';
    if (condition.contains('ash')) return 'assets/images/ash.png';
    return 'assets/images/clear.png';
  }

  Future<bool> isSeasonFilteringOn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['seasonBasedFiltering'] ?? false;
    } catch (e) {
      print('Error fetching seasonBasedFiltering: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset("assets/images/white_back_btn.png", height: 30, width: 30),
                  ),
                ),
                const Text('Current Weather', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topRight: Radius.circular(28), topLeft: Radius.circular(28)),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: getWeatherData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));

                  final weather = snapshot.data!;
                  final city = weather['city_name'] ?? 'Unknown';
                  final temp = (weather['main']?['temp'] ?? 25).toDouble();
                  final description = weather['weather']?[0]?['description'] ?? '';
                  final imagePath = getWeatherImage(weather);

                  final isNight = imagePath.contains('clear_night');
                  final isDay = imagePath.contains('clear.png');

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isNight)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset('assets/images/night.jpg', height: 120, width: 300, fit: BoxFit.cover),
                              ),
                            if (isDay)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset('assets/images/day.jpg', height: 120, width: 300, fit: BoxFit.cover),
                              ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(imagePath, height: 100),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(city, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('${temp.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 8),
                              Text(description, style: const TextStyle(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 12),
                              Text("Male: ${getClothingSuggestion(temp, 'male')}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                              const SizedBox(height: 8),
                              Text("Female: ${getClothingSuggestion(temp, 'female')}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final seasonOn = await isSeasonFilteringOn();
                                    if (seasonOn) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => WeatherClothesScreen(temperature: temp)));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.black87,
                                          content: RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Season-based filtering is OFF",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                                const WidgetSpan(
                                                  child: SizedBox(width: 30), // space between texts
                                                ),
                                                TextSpan(
                                                  text: "Go to Settings",
                                                  style: const TextStyle(
                                                    color: Colors.pink,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                                                      );
                                                    },
                                                ),
                                              ],
                                            ),
                                          ),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );

                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Explore Wardrobe', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
