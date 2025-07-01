import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:cap/Pages/RecipeSubmissionPage.dart';
import 'package:cap/Pages/adminPortalPage.dart';
import 'package:cap/firebase/services/FirebaseRecipeService.dart';
import 'package:cap/ui_components.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:url_launcher/url_launcher.dart';
import 'package:cap/models/user_model.dart'; // Add your user model import
import 'package:cap/models/recipe_model.dart'; // Add your recipe model import // Add your recipe detail page import

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.User? _currentUser =
      firebase_auth.FirebaseAuth.instance.currentUser;
  late final String? userId;
  late final bool isCurrentUser;

  @override
  void initState() {
    super.initState();
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    // Determine target user ID
    userId = widget.userId ?? currentUser?.uid;
    // Check if viewing current user's profile
    isCurrentUser = userId == currentUser?.uid;
  }

  Stream<DocumentSnapshot> get _userStream =>
      _firestore.collection('users').doc(userId).snapshots();

  Stream<QuerySnapshot> get _chefRecipesStream => _firestore
      .collection('recipes')
      .where('chef.uid', isEqualTo: userId)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view profile')),
      );
    }

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text(widget.userId == null
              ? 'Please sign in to view your profile'
              : 'User not found'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final user = AppUser.fromFirestore(snapshot.data!);
              return Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child:
                        user.profileImage == null || user.profileImage!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final user = AppUser.fromFirestore(userSnapshot.data!);

          return StreamBuilder<QuerySnapshot>(
            stream: _chefRecipesStream,
            builder: (context, recipeSnapshot) {
              if (recipeSnapshot.hasError) return const SizedBox();

              final recipes = recipeSnapshot.data?.docs
                      .map((doc) => Recipe.fromFirestore(doc))
                      .toList() ??
                  [];

              return SingleChildScrollView(
                child: _buildContentSection(user, recipes),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContentSection(AppUser user, List<Recipe> recipes) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection(user),
          const SizedBox(height: 25),
          _buildInfoSection(user),
          const SizedBox(height: 25),
          _buildCertificationsSection(user),
          const SizedBox(height: 30),
          _buildRecipesGrid(recipes),
        ],
      ),
    );
  }

  Widget _buildAboutSection(AppUser user) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Chef",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            user.bio ?? 'No bio available',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(AppUser user) {
    return _SectionCard(
      child: Column(
        children: [
          if (user.yearsExperience != null)
            _InfoRow(
              icon: Icons.work,
              color: Colors.blue,
              text: "${user.yearsExperience} years of experience",
            ),
          if (user.youtubeChannel != null) ...[
            const Divider(height: 30),
            _InfoRow(
              icon: Icons.video_library,
              color: Colors.red,
              text: "YouTube: ${_getLastPathSegment(user.youtubeChannel!)}",
              onTap: () => _launchURL(user.youtubeChannel!),
            ),
          ],
          if (user.linkedIn != null) ...[
            const Divider(height: 30),
            _InfoRow(
              icon: Icons.link,
              color: Colors.blue[800]!,
              text: "LinkedIn: ${_getLastPathSegment(user.linkedIn!)}",
              onTap: () => _launchURL(user.linkedIn!),
            ),
          ],
        ],
      ),
    );
  }

  String _getLastPathSegment(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
      return uri.host; // Fallback to domain name
    } catch (e) {
      return 'Profile'; // Fallback for invalid URLs
    }
  }

  Widget _buildCertificationsSection(AppUser user) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Certifications",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 15),
          if (user.certifications?.isNotEmpty ?? false)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: user.certifications!
                  .map((cert) => Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                color: Colors.blue[800], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              cert,
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            )
          else
            Text(
              'No certifications available',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

Widget _buildRecipesGrid(List<Recipe> recipes) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Signature Recipes",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
      const SizedBox(height: 20),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildRecipeCard(recipe),
          );
        },
      ),
    ],
  );
}

Widget _buildRecipeCard(Recipe recipe) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      );
    },
      
    child: SizedBox(
    width: double.infinity,
    child: Stack(
      children: [
        // Main Card Content
        Container(
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
          child: Column(
            children: [
              // Image Section
              _buildImageSection(recipe),
              // Recipe Info
              _buildRecipeInfo(recipe),
            ],
          ),
        ),
        // Edit/Delete Buttons
        if (isCurrentUser)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _buildActionButton(Icons.edit, Colors.blue, () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeSubmissionPage(recipeToEdit: recipe),
                      ),
                    )),
                const SizedBox(width: 8),
                _buildActionButton(Icons.delete, Colors.red, () => _confirmDelete(recipe.id)),
              ],
            ),
          ),
      ],
    ),
  ),
  );
}

Widget _buildImageSection(Recipe recipe) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    child: Stack(
      children: [
        Image.network(
          recipe.dishImage,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 180,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _buildRecipeInfo(Recipe recipe) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Name
        Text(
          recipe.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        
        // Rating Row (kept consistent with Favorites)
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 4),
            Text(
              recipe.averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // MetaChip Style for Preparation Time & Difficulty
        Row(
          children: [
            buildMetaChip(
              icon: Icons.timer_outlined,
              label: "${recipe.preparationTime} MIN",
              color: Colors.blue.shade400,
            ),
            const SizedBox(width: 10),
            buildMetaChip(
              icon: DifficultyUtils.getDifficultyIcon(
                  recipe.difficulty.toString().split('.').last),
              label: recipe.difficulty.toString().split('.').last.capitalize(),
              color: DifficultyUtils.getDifficultyColor(
                  recipe.difficulty.toString().split('.').last),
            ),
          ],
        ),
      ],
    ),
  );
}
  Widget buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return MetaChip(
      icon: icon,
      text: label,
      color: color,
      horizontalPadding: 8,
      verticalPadding: 8,
      fontSize: 15,
      iconSize: 15,
    );
  }


Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: CircleAvatar(
      backgroundColor: Colors.white,
      radius: 20,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    ),
  );
}
void _confirmDelete(String recipeId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Recipe'),
      content: const Text('Are you sure you want to delete this recipe?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await FirebaseRecipeService.deleteRecipe(recipeId);
            
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete failed: ${e.toString()}')),
              );
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
