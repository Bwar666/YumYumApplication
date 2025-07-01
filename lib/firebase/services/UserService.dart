import 'package:cap/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppUser>> searchChefsByName(String query) async {
    try {
      // Query for chef names containing the search term (case-insensitive)
      final result = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'chef')
          .get();

      // Client-side filtering for partial matches
      return result.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Chef search failed: $e');
    }
  }
}