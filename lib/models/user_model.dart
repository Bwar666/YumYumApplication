// user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser{
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImage;
  final String? bio;
  final int? yearsExperience;
  final String? youtubeChannel;
  final String? linkedIn;
  final List<String>? certifications;
  final List<Map<String, String>>? recipes;
  List<String> favorites;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.profileImage,
    this.bio,
    this.yearsExperience,
    this.youtubeChannel,
    this.linkedIn,
    this.certifications,
    this.recipes,
    this.favorites = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return AppUser(
        id: doc.id,
        name: 'Unknown User',
        email: 'no-email@example.com',
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bio: 'No bio provided',
        yearsExperience: 0,
        certifications: [],
        favorites: [],
      );
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Date parsing with helper
    DateTime _parseUserDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    return AppUser(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'no-email@example.com',
      role: data['role'] ?? 'user',
      createdAt: _parseUserDate(data['createdAt']),
      updatedAt: _parseUserDate(data['updatedAt']),
      profileImage: data['profileImage'],
      bio: data['bio'] ?? 'No bio provided',
      yearsExperience: data['yearsExperience'] ?? 0,
      youtubeChannel: data['youtubeChannel'] ?? '',
      linkedIn: data['linkedIn'] ?? '',
      certifications: List<String>.from(data['certifications'] ?? []),
      favorites: List<String>.from(data['favorites'] ?? []),
    );
  }

  get specializations => null;
  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'profileImage': profileImage,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
}
