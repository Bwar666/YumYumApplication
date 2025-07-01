import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


Stream<QuerySnapshot> getPendingRecipes() {
  return _firestore.collection('pending_recipes')
    .where('status', isEqualTo: "pending") // Add this filter
    .snapshots();
}

Future<void> approveRecipe(String recipeId) async {
  try {
    final doc = await _firestore.collection('pending_recipes').doc(recipeId).get();
    if (!doc.exists) throw Exception('Recipe not found');
    
    // Add to recipes collection
    await _firestore.collection('recipes').doc(recipeId).set(doc.data()!);
    
    // Update status instead of deleting
    await doc.reference.update({'status': 'approved'});
  } catch (e) {
    throw Exception('Failed to approve recipe: ${e.toString()}');
  }
}

Future<void> rejectRecipe(String recipeId) async {
  // Update status instead of deleting
  await _firestore.collection('pending_recipes').doc(recipeId).update({
    'status': 'rejected'
  });
}


Stream<QuerySnapshot> getPromotionRequests() {
  return _firestore.collection('promotionRequests')
    .where('status', isEqualTo: 'pending') // Keep existing filter
    .snapshots();
}

Future<void> approvePromotion(String requestId, String userId) async {
  try {
    final requestDoc = await _firestore.collection('promotionRequests').doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Promotion request not found');

    final requestData = requestDoc.data();
    if (requestData == null) throw Exception('Promotion request data is empty');

    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      // Update user fields with new promotion data
      transaction.update(userRef, {
        'role': 'chef',
        'updatedAt': FieldValue.serverTimestamp(),
        'profileImage': requestData['profileImage'] ?? '',
        'bio': requestData['bio'] ?? '',
        'yearsExperience': requestData['yearsExperience'] ?? 0,
        'youtubeChannel': requestData['youtubeChannel'] ?? '',
        'linkedIn': requestData['linkedIn'] ?? '',
        'certifications': requestData['certifications'] ?? [],
        'recipes': requestData['recipes'] ?? [],
      });

      // Update promotion request status
      transaction.update(requestDoc.reference, {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });
    });
  } catch (e) {
    throw Exception('Promotion approval failed: ${e.toString()}');
  }
}

Future<void> rejectPromotion(String requestId) async {
  // Update status instead of deleting
  await _firestore.collection('promotionRequests').doc(requestId).update({
    'status': 'rejected'
  });
}

  // Registered Users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }
}