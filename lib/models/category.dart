import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String title;
  final String categoryImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.title,
    required this.categoryImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Add fromFirestore method
factory Category.fromFirestore(Map<String, dynamic> data) {
  DateTime _parseCategoryDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }

  return Category(
    id: data['id'] ?? '',
    title: data['title'] ?? 'Uncategorized',
    categoryImage: data['categoryImage'] ?? '',
    createdAt: _parseCategoryDate(data['createdAt']),
    updatedAt: _parseCategoryDate(data['updatedAt']),
  );
}

  Map<String, dynamic> toMap() {
    return {
      'title': title,
    };
  }
}