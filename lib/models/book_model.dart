class BookModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String author;
  final String genre;
  final String condition;
  final String description;
  final String imageUrl;
  final String status; // "available", "pending_swap", "swapped"
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.author,
    required this.genre,
    required this.condition,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      genre: map['genre'] ?? '',
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? 'available',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'author': author,
      'genre': genre,
      'condition': condition,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookModel copyWith({
    String? status,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      title: title,
      author: author,
      genre: genre,
      condition: condition,
      description: description,
      imageUrl: imageUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}