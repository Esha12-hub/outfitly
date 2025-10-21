class ClothingItem {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String productLink;
  final DateTime createdAt;
  final String adminId;

  ClothingItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.productLink,
    required this.createdAt,
    required this.adminId,
  });

  factory ClothingItem.fromMap(Map<String, dynamic> map, String id) {
    return ClothingItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      productLink: map['productLink'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      adminId: map['adminId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'productLink': productLink,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'adminId': adminId,
    };
  }
}

// Optional: keep ClothingCategory for reference or future use
class ClothingCategory {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  ClothingCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  static List<ClothingCategory> getDefaultCategories() {
    return [
      ClothingCategory(
        id: 'tops',
        name: 'Tops',
        imageUrl: 'assets/images/shirt 1.png',
        description: 'Shirts, Blouses, T-shirts',
      ),
      ClothingCategory(
        id: 'bottoms',
        name: 'Bottoms',
        imageUrl: 'assets/images/jean1.png',
        description: 'Pants, Jeans, Shorts',
      ),
      ClothingCategory(
        id: 'dresses',
        name: 'Dresses',
        imageUrl: 'assets/images/outfit1.png',
        description: 'Casual & Formal Dresses',
      ),
      ClothingCategory(
        id: 'shoes',
        name: 'Shoes',
        imageUrl: 'assets/images/shoes.png',
        description: 'Sneakers, Heels, Boots',
      ),
      ClothingCategory(
        id: 'accessories',
        name: 'Accessories',
        imageUrl: 'assets/images/outfit2.png',
        description: 'Bags, Jewelry, Hats',
      ),
      ClothingCategory(
        id: 'outerwear',
        name: 'Outerwear',
        imageUrl: 'assets/images/jacket1.png',
        description: 'Jackets, Coats, Blazers',
      ),
    ];
  }
}
