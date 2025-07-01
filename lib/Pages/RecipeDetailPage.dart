import 'dart:async';
import 'package:cap/Pages/ProfilePage.dart';
import 'package:cap/Pages/SearchPage.dart';
import 'package:cap/constants.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:cap/models/user_model.dart';
import 'package:cap/ui_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with TickerProviderStateMixin {
  late StreamSubscription<DocumentSnapshot> _recipeSubscription;
  // ignore: unused_field
  Recipe? _currentRecipe;
  bool _showIngredients = true;
  YoutubePlayerController? _youtubeController;
  double _userRating = 0.0;
  late AnimationController _animationController;
  StreamSubscription<DocumentSnapshot>? _ratingSubscription;

@override
void initState() {
  super.initState();
  _currentRecipe = widget.recipe;

if (widget.recipe.videoUrl != null && widget.recipe.videoUrl!.isNotEmpty) {
    final videoId = YoutubePlayer.convertUrlToId(widget.recipe.videoUrl!);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }
  }
  _recipeSubscription = FirebaseFirestore.instance
      .collection('recipes')
      .doc(widget.recipe.id)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      setState(() {
        _currentRecipe = Recipe.fromFirestore(snapshot);
      });
    }
    _initSubscriptions();
    _loadUserRating();
  });
}
void _initializeYoutubeController(String? videoUrl) {
  if (videoUrl != null && videoUrl.isNotEmpty) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }
  }
}
  void _initSubscriptions() {
    _recipeSubscription = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _currentRecipe = Recipe.fromFirestore(snapshot);
        });
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ratingSubscription = FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .collection('ratings')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _userRating = (snapshot.data()!['rating'] as num).toDouble();
          });
        }
      });
    }
  }

    Future<void> _loadUserRating() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ratingDoc = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .collection('ratings')
        .doc(user.uid)
        .get();

    if (ratingDoc.exists) {
      setState(() {
        _userRating = (ratingDoc.data()!['rating'] as num).toDouble();
      });
    }
  }

  
  
 @override
  void dispose() {
    _recipeSubscription.cancel();
    _ratingSubscription?.cancel();
    super.dispose();
  }

  void _toggleView(bool showIngredients) {
    setState(() => _showIngredients = showIngredients);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: ListView(
        children: [
          _buildHeaderImage(),
          _buildRecipeTitle(),
          _buildRecipeDescription(),
          _buildMetaInformation(),
          _ChefCard(chefId: widget.recipe.chef.id),
          _buildUserRating(),
          _buildToggleButtons(),
          _buildContentSection(),
          _buildVideoTutorial(),
          _buildMoreRecipes(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

void _shareRecipe() async {
  final recipe = _currentRecipe ?? widget.recipe;
  final dynamicLink = await _createDynamicLink(recipe);
  
  final shareText = '''
Check out this delicious recipe! 🍴

${recipe.name}

⭐ Rating: ${recipe.averageRating.toStringAsFixed(1)}/5
⏱ Prep Time: ${recipe.preparationTime} minutes
🔪 Difficulty: ${recipe.difficulty.toString().split('.').last}

${recipe.description}

Get the full recipe with ingredients and instructions:
$dynamicLink
''';

  Share.share(shareText, subject: 'Check out this recipe: ${recipe.name}');
}

Future<String> _createDynamicLink(Recipe recipe) async {
  final parameters = DynamicLinkParameters(
    uriPrefix: 'https://yumyumrecipe.page.link',
    link: Uri.parse('https://yumyumrecipe.com/recipes/${recipe.id}'),
    androidParameters: const AndroidParameters(
      packageName: 'com.example.cap', // Replace with your actual package name
      minimumVersion: 1,
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: recipe.name,
      description: recipe.description,
      imageUrl: Uri.parse(recipe.dishImage),
    ),
  );

  final dynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return dynamicLink.shortUrl.toString();
}


  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black, size: 30),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.black, size: 26),
          onPressed: () => _shareRecipe(),
        ),
        IconButton(
          icon: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              bool isFavorite = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                List<dynamic> favorites = snapshot.data!['favorites'] ?? [];
                isFavorite = favorites.contains(widget.recipe.id);
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(isFavorite),
                  color: Colors.redAccent,
                  size: 32,
                ),
              );
            },
          ),
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login to save favorites')),
              );
              return;
            }
            try {
              final userDoc =
                  FirebaseFirestore.instance.collection('users').doc(user.uid);
              final doc = await userDoc.get();
              List<dynamic> favorites = doc['favorites'] ?? [];

              if (favorites.contains(widget.recipe.id)) {
                await userDoc.update({
                  'favorites': FieldValue.arrayRemove([widget.recipe.id])
                });
              } else {
                await userDoc.update({
                  'favorites': FieldValue.arrayUnion([widget.recipe.id])
                });
                _showFloatingHeart(context);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error updating favorite: ${e.toString()}')),
              );
            }
          },
        )
      ],
    );
  }

  Widget _buildHeaderImage() {
    final recipe = _currentRecipe ?? widget.recipe;
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(widget.recipe.dishImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0, top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              children: [
                RatingBarIndicator(
                  rating: _currentRecipe?.averageRating ?? 0.0,
                  itemBuilder: (_, __) =>
                      const Icon(Icons.star_rounded, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 30,
                ),
                Text(
                   '${_currentRecipe?.averageRating.toStringAsFixed(1) ?? 0.0} (${_currentRecipe?.totalRatings ?? 0})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeTitle() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(_currentRecipe?.name ?? widget.recipe.name,
        style: AppConstants.recipeTitleStyle,
      ),
    );
  }

  Widget _buildRecipeDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Text(
        _currentRecipe?.description ?? widget.recipe.description,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMetaInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          buildMetaChip(
            icon: Icons.schedule_rounded,
            label: "${_currentRecipe?.preparationTime ?? widget.recipe.preparationTime} MIN",
            color: Colors.blue.shade400,
          ),
          const SizedBox(width: 10),
          buildMetaChip(
            icon: DifficultyUtils.getDifficultyIcon(
                widget.recipe.difficulty.toString().split('.').last),
            label: _currentRecipe?.difficulty.toString().split('.').last ?? widget.recipe.difficulty.toString().split('.').last,//capitalize(),
            color: DifficultyUtils.getDifficultyColor(
                widget.recipe.difficulty.toString().split('.').last),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRating() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate this recipe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2.0),
          Text(
            'Tell others what you think about this recipe!',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6.0),
          RatingBar.builder(
            initialRating: _userRating,
            minRating: 1,
            glow: true,
            glowColor: Colors.amber.withOpacity(0.2),
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star_rounded,
              color: Colors.amber,
            ),
            unratedColor: Colors.grey.shade300,
            itemSize: 50,
            onRatingUpdate: (rating) {
              setState(() {
                _userRating = rating;
              });
              _showRatingAlert();
            },
          ),
        ],
      ),
    );
  }


  void _showRatingAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Rating'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 5),
            RatingBar.builder(
              initialRating: _userRating,
              minRating: 1,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  Icon(Icons.star_rounded, color: Colors.amber),
              unratedColor: Colors.grey.shade300,
              itemSize: 30,
              onRatingUpdate: (rating) {
                setState(() {
                  _userRating = rating;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to rate recipes')),
                );
                Navigator.pop(context);
                return;
              }

              try {
                final recipeDoc = FirebaseFirestore.instance
                    .collection('recipes')
                    .doc(widget.recipe.id);

                final ratingDoc = recipeDoc.collection('ratings').doc(user.uid);

                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final recipeSnapshot = await transaction.get(recipeDoc);
                  final ratingSnapshot = await transaction.get(ratingDoc);

                  double currentAverage =
                      (recipeSnapshot.get('averageRating') as num?)?.toDouble() ?? 0.0;
                  int totalRatings = recipeSnapshot.get('totalRatings') ?? 0;
                  double previousRating = ratingSnapshot.exists
                      ? (ratingSnapshot.get('rating') as num).toDouble()
                      : 0.0;

                  if (ratingSnapshot.exists) {
                    currentAverage = ((currentAverage * totalRatings) -
                            previousRating +
                            _userRating) /
                        totalRatings;
                  } else {
                    totalRatings++;
                    currentAverage = ((currentAverage * (totalRatings - 1)) +
                            _userRating) /
                        totalRatings;
                  }

                  transaction.update(recipeDoc, {
                    'averageRating': currentAverage,
                    'totalRatings': totalRatings,
                  });

                  transaction.set(ratingDoc, {
                    'rating': _userRating,
                    'userId': user.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                });

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error rating recipe: ${e.toString()}'),
                  ),
                );
              }
            },
            child: Text(_userRating == 0 ? 'Post Review' : 'Update Review'),
          ),
        ],
      ),
    );
  }

  void _showFloatingHeart(BuildContext context) {
    OverlayEntry entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: MediaQuery.of(context).size.width * 0.4,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: AnimationController(
                vsync: this, duration: const Duration(milliseconds: 600)),
            curve: Curves.elasticOut,
          ),
          child:
              const Icon(Icons.favorite_rounded, color: Colors.red, size: 80),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: () => _toggleView(true),
            child: Text(
              "Ingredients",
              style: TextStyle(
                color: _showIngredients ? Colors.blue : Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _toggleView(false),
            child: Text(
              "Method",
              style: TextStyle(
                color: !_showIngredients ? Colors.blue : Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      children: [
        Visibility(
          visible: _showIngredients,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ingredients:", style: _sectionHeaderStyle()),
                const SizedBox(height: 10),
                _buildIngredientsList(),
                const SizedBox(height: 20),
                _buildTalabatMart(),
              ],
            ),
          ),
        ),
        Visibility(
          visible: !_showIngredients,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Method:", style: _sectionHeaderStyle()),
                const SizedBox(height: 10),
                _buildMethodSteps(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    if (widget.recipe.ingredients.isEmpty) {
      return Text("No ingredients listed", style: _placeholderStyle());
    }
    return Column(
      children: widget.recipe.ingredients
          .map(
            (ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 18)),
                  Expanded(
                      child: Text(ingredient, style: _ingredientTextStyle())),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMethodSteps() {
    if (widget.recipe.methodSteps.isEmpty) {
      return Text("No method steps available", style: _placeholderStyle());
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.recipe.methodSteps.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${index + 1}. ", style: _stepNumberStyle()),
            Expanded(
                child: Text(widget.recipe.methodSteps[index],
                    style: _methodTextStyle())),
          ],
        ),
      ),
    );
  }
Widget _buildVideoTutorial() {
  final videoUrl = _currentRecipe?.videoUrl;
  if (_youtubeController == null || videoUrl == null || videoUrl.isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Video Tutorial", style: AppConstants.sectionTitleStyle),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  onReady: () {
                    if (_youtubeController!.value.isPlaying) {
                      _youtubeController!.pause();
                    } else {
                      _youtubeController!.play();
                    }
                  },
                ),
                builder: (context, player) => player,
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Image.asset(
                    'asset/youtube_logo.png', // Add YouTube icon asset
                    width: 32,
                    height: 32,
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(videoUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open YouTube')),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildMoreRecipes() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "More Recipes",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          _buildRecommendationList(),
        ],
      ),
    );
  }

Widget _buildRecommendationList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('recipes')
        .where('category.title', isEqualTo: widget.recipe.category.title)
        .where('status', isEqualTo: 'approved')
        .limit(10)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final recipes = snapshot.data!.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .where((recipe) => recipe.id != widget.recipe.id)
          .toList();

      return SizedBox(
        height: 200,  // Maintain container height
        child: ListView.builder(
          scrollDirection: Axis.horizontal,  // Changed to horizontal
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return Container(
              width: 330,  // Fixed width for horizontal items
              padding: const EdgeInsets.only(right: 16),
              child: RecipeCard(
                recipeName: recipe.name,
                dishImage: recipe.dishImage,
                rating: recipe.averageRating,
                preparationTime: "${recipe.preparationTime} MIN",
                difficultyLevel:
                    recipe.difficulty.toString().split('.').last.capitalize(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailPage(recipe: recipe),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

  Widget _buildTalabatMart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Save time, shop ingredients",
          style: AppConstants.sectionTitleStyle,
        ),
        RichText(
          text: TextSpan(
            text:
                "Build your grocery cart with Yum Yum, then get your order from ",
            style: const TextStyle(fontSize: 17, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                text: 'TalabatMart',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.orangeAccent[700],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0, left: 10, top: 20),
          child: SizedBox(
            width: 450,
            height: 65,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
              onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Coming Soon'),
                  content: const Text('This feature will be available soon.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
              child: const Text(
                "Buy Ingredients",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            RichText(
              text: TextSpan(
                text: 'Powered By ',
                style: const TextStyle(fontSize: 17, color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: 'TalabatMart',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.orangeAccent[700],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Image.asset("asset/talabat.gif"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Text Styles
  TextStyle _sectionHeaderStyle() => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  TextStyle _ingredientTextStyle() => TextStyle(
        fontSize: 18.0,
        color: Colors.grey[800],
      );

  TextStyle _methodTextStyle() => TextStyle(
        fontSize: 18.0,
        color: Colors.grey[800],
        height: 1.4,
      );

  TextStyle _stepNumberStyle() => TextStyle(
        fontSize: 18.0,
        color: Colors.blue[700],
        fontWeight: FontWeight.bold,
      );

  TextStyle _placeholderStyle() => TextStyle(
        fontSize: 16.0,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      );

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
}

class _ChefCard extends StatelessWidget {
  final String chefId;

  const _ChefCard({required this.chefId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(chefId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            margin: EdgeInsets.all(20),
            child: ListTile(
              leading: CircleAvatar(radius: 30),
              title: Text('Loading chef...'),
            ),
          );
        }

        final chef = AppUser.fromFirestore(snapshot.data!);

        return Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          elevation: 4,
          margin: const EdgeInsets.all(20),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userId: chefId),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(chef.profileImage ?? ''),
                    radius: 30,
                  ),
                  title: Text(
                    chef.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text(chef.email),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
