import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cap/models/recipe_model.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _user;
  late Stream<List<String>> _favoriteIdsStream;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _initializeStreams();
  }

  void _initializeStreams() {
    _favoriteIdsStream = _user != null
        ? _firestore.collection('users').doc(_user!.uid).snapshots().map(
              (snapshot) =>
                  List<String>.from(snapshot.data()?['favorites'] ?? []),
            )
        : const Stream.empty();
  }

  Stream<List<Recipe>> _favoriteRecipesStream(List<String> favoriteIds) {
    if (favoriteIds.isEmpty) return const Stream.empty();
    return _firestore
        .collection('recipes')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }

  Future<void> _toggleFavorite(String recipeId) async {
    if (_user == null || !mounted) return;

    try {
      final userRef = _firestore.collection('users').doc(_user!.uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final favorites =
            List<String>.from(snapshot.data()?['favorites'] ?? []);

        if (favorites.contains(recipeId)) {
          transaction.update(userRef, {
            'favorites': FieldValue.arrayRemove([recipeId])
          });
          if (!mounted) return;
          setState(() {});
        } else {
          transaction.update(userRef, {
            'favorites': FieldValue.arrayUnion([recipeId])
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<String>>(
        stream: _favoriteIdsStream,
        builder: (context, idsSnapshot) {
          // Error handling
          if (idsSnapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load favorites\n${idsSnapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade700,
                ),
              ),
            );
          }

          // Loading state
          if (!idsSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
            );
          }

          final favoriteIds = idsSnapshot.data!;

          // Immediate empty state for no favorites
          if (favoriteIds.isEmpty) {
            return _buildEmptyState();
          }

          // Show recipes grid for existing favorites
          return StreamBuilder<List<Recipe>>(
            stream: _favoriteRecipesStream(favoriteIds),
            builder: (context, recipesSnapshot) {
              // Recipes loading state
              if (!recipesSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                );
              }

              // Handle potential recipe loading errors
              if (recipesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading recipes\n${recipesSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                );
              }

              final favorites = recipesSnapshot.data!;

              // Fallback empty state if recipes were deleted
              return favorites.isEmpty
                  ? _buildEmptyState()
                  : _buildRecipeGrid(favorites);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            'No Favorite Recipes Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap the heart icon on any recipe to save it here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> favorites) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final recipe = favorites[index];
          return _RecipeCard(
            recipe: recipe,
            onRemove: () => _toggleFavorite(recipe.id),
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onRemove;

  const _RecipeCard({required this.recipe, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(recipe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) => onRemove(),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipe: recipe),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Stack(
      children: [
        _buildBackgroundImage(),
        _buildGradientOverlay(),
        _buildRecipeInfo(),
        _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        recipe.dishImage,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
            stops: const [0.1, 0.5],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeInfo() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                recipe.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                '${recipe.preparationTime} min',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.9),
        radius: 18,
        child: IconButton(
          icon: const Icon(Icons.favorite_rounded, color: Colors.red),
          iconSize: 20,
          onPressed: onRemove,
        ),
      ),
    );
  }
}
