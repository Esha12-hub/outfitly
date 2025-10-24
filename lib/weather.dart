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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.06),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset("assets/images/white_back_btn.png",
                        height: screenHeight * 0.03, width: screenHeight * 0.03),
                  ),
                ),
                Text('Current Weather',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: screenHeight * 0.02),
              padding: EdgeInsets.all(screenWidth * 0.06),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(screenWidth * 0.07),
                  topLeft: Radius.circular(screenWidth * 0.07),
                ),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: getWeatherData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError)
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04)));

                  final weather = snapshot.data!;
                  final city = weather['city_name'] ?? 'Unknown';
                  final temp = (weather['main']?['temp'] ?? 25).toDouble();
                  final description = weather['weather']?[0]?['description'] ?? '';
                  final imagePath = getWeatherImage(weather);

                  final isNight = imagePath.contains('clear_night');
                  final isDay = imagePath.contains('clear.png');

                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isNight)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                  child: Image.asset(
                                    'assets/images/night.jpg',
                                    height: screenHeight * 0.15,
                                    width: screenWidth * 0.8,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (isDay)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                  child: Image.asset(
                                    'assets/images/day.jpg',
                                    height: screenHeight * 0.15,
                                    width: screenWidth * 0.8,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                child: Image.asset(
                                  imagePath,
                                  height: screenHeight * 0.12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.pink[100],
                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            ),
                            child: Column(
                              children: [
                                Text(city,
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: screenHeight * 0.01),
                                Text('${temp.toStringAsFixed(1)}°C',
                                    style: TextStyle(fontSize: screenWidth * 0.05)),
                                SizedBox(height: screenHeight * 0.01),
                                Text(description,
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: screenWidth * 0.045)),
                                SizedBox(height: screenHeight * 0.015),
                                Text("Male: ${getClothingSuggestion(temp, 'male')}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.04, color: Colors.black87)),
                                SizedBox(height: screenHeight * 0.01),
                                Text("Female: ${getClothingSuggestion(temp, 'female')}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.04, color: Colors.black87)),
                                SizedBox(height: screenHeight * 0.02),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final seasonOn = await isSeasonFilteringOn();
                                      if (seasonOn) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => WeatherClothesScreen(
                                                    temperature: temp)));
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
                                                    child: SizedBox(width: 10),
                                                  ),
                                                  TextSpan(
                                                    text: "Go to Settings",
                                                    style: TextStyle(
                                                      color: Colors.pink,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: screenWidth * 0.04,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (_) =>
                                                                  SettingsScreen()),
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
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.018),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                                    ),
                                    child: Text('Explore Wardrobe',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
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
    );
  }
}
