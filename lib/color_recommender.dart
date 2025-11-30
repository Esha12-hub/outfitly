import 'package:flutter/material.dart';

class ColorRecommender {
  static List<String> recommend(String skinTone) {
    switch (skinTone.toLowerCase()) {
      case "dark":
        return [
          "Pastel Pink",
          "Mustard Yellow",
          "Burgundy",
          "Olive Green",
          "Chocolate Brown",
          "Orange",
          "Royal Blue",
          "Teal",
        ];

      case "mid-dark":
        return [
          "Olive Green",
          "Royal Blue",
          "Maroon",
          "Burgundy",
          "Mustard Yellow",
          "Charcoal",
          "Copper",
          "Emerald Green",
        ];

      case "mid-light":
        return [
          "Soft Pink",
          "Light Blue",
          "Mint Green",
          "Peach",
          "Grey",
          "Navy Blue",
          "Lavender",
          "Coral",
        ];

      case "light":
        return [
          "Dark Green",
          "Navy",
          "Black",
          "Red",
          "Purple",
          "Camel",
          "Chocolate Brown",
          "Royal Blue",
        ];

      default:
        return ["Color suggestions unavailable"];
    }
  }

  static Color getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case "white":
        return Colors.white;
      case "beige":
        return Color(0xFFF5F5DC);
      case "sky blue":
        return Color(0xFF87CEEB);
      case "mustard":
      case "mustard yellow":
        return Color(0xFFFFDB58);
      case "olive":
      case "olive green":
        return Color(0xFF808000);
      case "lavender":
        return Color(0xFFE6E6FA);
      case "pastel pink":
      case "pastel colors":
        return Color(0xFFFFC0CB);
      case "royal blue":
        return Color(0xFF4169E1);
      case "maroon":
        return Color(0xFF800000);
      case "burgundy":
        return Color(0xFF800020);
      case "charcoal":
        return Color(0xFF36454F);
      case "soft pink":
        return Color(0xFFFFB6C1);
      case "light blue":
        return Color(0xFFADD8E6);
      case "mint green":
        return Color(0xFF98FF98);
      case "peach":
        return Color(0xFFFFDAB9);
      case "grey":
        return Colors.grey;
      case "navy":
      case "navy blue":
        return Color(0xFF000080);
      case "dark green":
        return Color(0xFF006400);
      case "black":
        return Colors.black;
      case "red":
        return Colors.red;
      case "purple":
        return Colors.purple;
      case "camel":
        return Color(0xFFC19A6B);
      case "chocolate brown":
        return Color(0xFFD2691E);
      case "orange":
        return Colors.orange;
      case "teal":
        return Color(0xFF008080);
      case "copper":
        return Color(0xFFB87333);
      case "emerald green":
        return Color(0xFF50C878);
      case "coral":
        return Color(0xFFFF7F50);
      default:
        return Colors.grey;
    }
  }
}
