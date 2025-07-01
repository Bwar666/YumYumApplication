import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<String>> getFavoritesStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map(
      (snapshot) {
        return List<String>.from(snapshot.data()?['favorites'] ?? []);
      },
    );
  }

  Future<void> toggleFavorite(String userId, String recipeId) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final favorites = List<String>.from(snapshot.data()?['favorites'] ?? []);

      if (favorites.contains(recipeId)) {
        transaction.update(userRef, {
          'favorites': FieldValue.arrayRemove([recipeId])
        });
      } else {
        transaction.update(userRef, {
          'favorites': FieldValue.arrayUnion([recipeId])
        });
      }
    });
  }
}