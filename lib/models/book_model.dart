import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String author;
  final String genre;
  final String condition;
  final String description;
  final String imageBase64;
  final String status; // "available", "pending", "swapped"
  final DateTime createdAt;
  final DateTime updatedAt;

  // ✅ New field to mark if the book belongs to the current user
  bool isMine;

  BookModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.author,
    required this.genre,
    required this.condition,
    required this.description,
    required this.imageBase64,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isMine = false, // default false
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
      imageBase64: map['imageBase64'] ?? '',
      status: map['status'] ?? 'available',
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : (map['updatedAt'] as Timestamp).toDate(),
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
      'imageBase64': imageBase64,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookModel copyWith({
    String? title,
    String? author,
    String? genre,
    String? condition,
    String? description,
    String? imageBase64,
    String? status,
    DateTime? updatedAt,
    bool? isMine, // ✅ support updating isMine
  }) {
    return BookModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      imageBase64: imageBase64 ?? this.imageBase64,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMine: isMine ?? this.isMine,
    );
  }
}