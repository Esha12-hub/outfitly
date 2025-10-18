class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? avatarUrl;
  final DateTime createdAt;
  final int wardrobeItems;
  final int outfitsCreated;
  final int tryOns;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.avatarUrl,
    required this.createdAt,
    this.wardrobeItems = 0,
    this.outfitsCreated = 0,
    this.tryOns = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Regular User',
      status: json['status'] ?? 'Active',
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      wardrobeItems: json['wardrobeItems'] ?? 0,
      outfitsCreated: json['outfitsCreated'] ?? 0,
      tryOns: json['tryOns'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'wardrobeItems': wardrobeItems,
      'outfitsCreated': outfitsCreated,
      'tryOns': tryOns,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    String? avatarUrl,
    DateTime? createdAt,
    int? wardrobeItems,
    int? outfitsCreated,
    int? tryOns,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      wardrobeItems: wardrobeItems ?? this.wardrobeItems,
      outfitsCreated: outfitsCreated ?? this.outfitsCreated,
      tryOns: tryOns ?? this.tryOns,
    );
  }
} 