import 'package:cap/models/recipe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class FirebaseRecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createRecipe(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('recipes').add({
      'name': recipe.name,
      'description': recipe.description,
      'dishImage': recipe.dishImage,
      'preparationTime': recipe.preparationTime,
      'difficulty': recipe.difficulty.toString().split('.').last,
      'ingredients': recipe.ingredients,
      'methodSteps': recipe.methodSteps,
      'category': {
      'title': recipe.category.title,
    },
      'chefId': user.uid,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'videoUrl': recipe.videoUrl,
      'averageRating': 0.0,
      'totalRatings': 0,

    });
  }

  static Future<void> updateRecipe(Recipe recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).update({
      'name': recipe.name,
      'description': recipe.description,
      'dishImage': recipe.dishImage,
      'preparationTime': recipe.preparationTime,
      'difficulty': recipe.difficulty.toString().split('.').last,
      'ingredients': recipe.ingredients,
      'methodSteps': recipe.methodSteps,
      'category': {
      'title': recipe.category.title,
    },
      'updatedAt': Timestamp.now(),
      'videoUrl': recipe.videoUrl,
    });
  }
  static Future<void> createPendingRecipe(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('pending_recipes').add({
      ...recipe.toMap(),
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

    static Future<void> deleteRecipe(String recipeId) async {
    try {
      // Delete all subcollections (add more if needed)
      await _deleteSubcollection(recipeId, 'ratings');
      
      // Delete main recipe document
      await _firestore.collection('recipes').doc(recipeId).delete();
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  static Future<void> approveRecipe(String recipeId) async {
  final doc = await _firestore.collection('pending_recipes').doc(recipeId).get();
  final data = doc.data()!;
  
  // Update the status field
  data['status'] = 'approved';
  
  await _firestore.collection('recipes').doc(recipeId).set(data);
  await doc.reference.delete();
}


  static Future<void> _deleteSubcollection(String recipeId, String subcollection) async {
    final collectionRef = _firestore
        .collection('recipes')
        .doc(recipeId)
        .collection(subcollection);
    
    final querySnapshot = await collectionRef.get();
    
    // Delete documents in batches
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}