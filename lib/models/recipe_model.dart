import 'package:cap/models/category.dart';
import 'package:cap/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Difficulty { easy, normal, hard }

class Recipe {
  final String id;
  final String name;
  final String description;
  final String dishImage;
  final int preparationTime;
  final Difficulty difficulty;
  final List<String> ingredients;
  final List<String> methodSteps;
  final Category category;
  final AppUser chef;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? videoUrl;
  final String status;
  final double averageRating;
  final int totalRatings;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.dishImage,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.preparationTime,
    required this.difficulty,
    required this.ingredients,
    required this.methodSteps,
    required this.category,
    required this.chef,
    required this.createdAt,
    required this.updatedAt,
    this.videoUrl,
    this.status = 'pending',
  });

  static Difficulty _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'normal':
        return Difficulty.normal;
      case 'hard':
        return Difficulty.hard;
      default:
        throw ArgumentError('Invalid difficulty: $difficulty');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dishImage': dishImage,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'preparationTime': preparationTime,
      'difficulty': difficulty.toString().split('.').last,
      'ingredients': ingredients,
      'methodSteps': methodSteps,
      'category': category.toMap(),
      'chef': {
        'uid': chef.id,
        'email': chef.email,
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'videoUrl': videoUrl,
      'status': status,
    };
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse dates using helper
    final createdAt = _parseFirestoreDate(data['createdAt']);
    final updatedAt = _parseFirestoreDate(data['updatedAt']);

    // Handle category data
    final categoryData = data['category'] as Map<String, dynamic>? ?? {};
    final category = Category(
      id: categoryData['id'] ?? '',
      title: categoryData['title'] ?? 'Uncategorized',
      categoryImage: categoryData['categoryImage'] ?? '',
      createdAt: _parseFirestoreDate(categoryData['createdAt']),
      updatedAt: _parseFirestoreDate(categoryData['updatedAt']),
    );

    // Handle chef data
    final chefData = data['chef'] as Map<String, dynamic>? ?? {};
    final chef = AppUser(
      id: chefData['uid'] ?? '',
      email: chefData['email'] ?? 'no-email@example.com',
      name: chefData['displayName'] ?? 'Unknown Chef',
      profileImage: chefData['photoURL'],
    );

    return Recipe(
      id: doc.id,
      name: data['name'] ?? 'Untitled Recipe',
      description: data['description'] ?? '',
      dishImage: data['dishImage'] ?? '',
      status: data['status'] ?? 'pending',
      preparationTime: data['preparationTime'] ?? 0,
      difficulty: _parseDifficulty(data['difficulty']?.toString() ?? 'easy'),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      methodSteps: List<String>.from(data['methodSteps'] ?? []),
      category: category,
      chef: chef,
      createdAt: createdAt,
      updatedAt: updatedAt,
      videoUrl: data['videoUrl'],
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: data['totalRatings'] ?? 0,
    );
  }

  static DateTime _parseFirestoreDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    return DateTime.now();
  }
}