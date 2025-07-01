import 'package:cap/models/recipe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      // Get matching chef IDs first
      final chefResults = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'chef')
          .get();

      final matchingChefIds = chefResults.docs
          .where((doc) => doc['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .map((doc) => doc.id)
          .toList();

      // Build queries
      final nameQuery = _firestore.collection('recipes');
      final ingredientQuery = _firestore.collection('recipes');
      final chefQuery = matchingChefIds.isNotEmpty
          ? _firestore.collection('recipes').where('chefId', whereIn: matchingChefIds)
          : null;

      // Execute queries
      final results = await Future.wait([
        nameQuery.get(),
        ingredientQuery.get(),
        if (chefQuery != null) chefQuery.get(),
      ]);

      // Combine and filter results
      final allResults = results.expand((snapshot) => snapshot.docs).toList();
      
      // Client-side filtering for name and ingredients
      final filteredResults = allResults.where((doc) {
        final recipeName = doc['name'].toString().toLowerCase();
        final ingredients = List<String>.from(doc['ingredients'] ?? [])
            .map((i) => i.toLowerCase())
            .toList();
        
        return recipeName.contains(query.toLowerCase()) ||
               ingredients.any((i) => i.contains(query.toLowerCase()));
      }).toList();

      // Deduplicate and convert to Recipe objects
      return filteredResults
          .map((doc) => Recipe.fromFirestore(doc))
          .toSet()
          .toList();

    } catch (e) {
      throw Exception('Recipe search failed: $e');
    }
  }
  Future<List<Recipe>> getAllRecipes() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        //.where('status', isEqualTo: 'approved')
        .get();
        
    return querySnapshot.docs
        .map((doc) => Recipe.fromFirestore(doc))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch recipes: $e');
  }
}
// Add to RecipeService class
Future<Recipe?> getRecipeById(String id) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('recipes').doc(id).get();
    if (doc.exists) {
      return Recipe.fromFirestore(doc);
    }
    return null;
  } catch (e) {
    return null;
  }
}
}