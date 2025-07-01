import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:cap/constants.dart';
import 'package:cap/models/category.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:cap/ui_components.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDetailPage extends StatefulWidget {
  final Category category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailState();
}

class _CategoryDetailState extends State<CategoryDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get _recipesStream => _firestore
      .collection('recipes')
      .where('category.title', isEqualTo: widget.category.title)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _recipesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading recipes'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!.docs
              .map((doc) => Recipe.fromFirestore(doc))
              .toList();

          if (recipes.isEmpty) {
            return const Center(child: Text('No recipes found'));
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 10),
                child: Text(
                  widget.category.title,
                  style: AppConstants.sectionTitleStyle,
                ),
              ),
              ...recipes.map((recipe) => _buildRecipeCard(context, recipe)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: RecipeCard(
        recipeName: recipe.name,
        dishImage: recipe.dishImage,
        rating: recipe.averageRating,
        heightOfCard: 170,
        preparationTime: "${recipe.preparationTime} MIN",
        difficultyLevel: recipe.difficulty.toString().split('.').last,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        ),
      ),
    );
  }
}