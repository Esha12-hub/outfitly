enum ContentStatus {
  pending,
  approved,
  rejected,
}

enum ContentType {
  outfit,
  image,
  review,
  article,
}

class ContentModel {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final ContentType type;
  final ContentStatus status;
  final DateTime createdAt;
  final String? imageUrl;
  final String? content;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;

  ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.content,
    this.rejectionReason,
    this.metadata,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.toString() == 'ContentType.${json['type']}',
        orElse: () => ContentType.article,
      ),
      status: ContentStatus.values.firstWhere(
        (e) => e.toString() == 'ContentStatus.${json['status']}',
        orElse: () => ContentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['imageUrl'],
      content: json['content'],
      rejectionReason: json['rejectionReason'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'content': content,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  ContentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    ContentType? type,
    ContentStatus? status,
    DateTime? createdAt,
    String? imageUrl,
    String? content,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      content: content ?? this.content,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }
} 