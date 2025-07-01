import 'package:cap/Pages/AllCategoriesPage.dart';
import 'package:cap/Pages/CategoryDetailPage.dart';
import 'package:cap/Pages/ProfilePage.dart';
import 'package:cap/Pages/Promotion_page.dart';
import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:cap/Pages/RecipeSubmissionPage.dart';
import 'package:cap/Pages/SearchPage.dart';
import 'package:cap/Pages/adminPortalPage.dart';
import 'package:cap/Pages/favouritePage.dart';
import 'package:cap/models/category.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';
import '../ui_components.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final _pageController = PageController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _userRole = 'guest';
  String _userId = '';
  String _userName = '';
  String _userEmail = '';
  String _userProfileImage = '';
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userRole = 'guest';
        _userId = '';
        _userName = '';
        _userEmail = '';
        _userProfileImage = '';
      });
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      _userId = user.uid;
      _userName = user.displayName ?? '';
      _userEmail = user.email ?? '';
      _userProfileImage = user.photoURL ?? '';

      if (!userDoc.exists) {
        _userRole = 'user';
      } else {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userRole = userData['role'] ?? 'user';
        _userName = userData['name'] ?? _userName;
        _userProfileImage = userData['profileImage'] ?? _userProfileImage;
      }
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  List<Widget> _getPages() {
    switch (_userRole) {
      case 'admin':
        return [
          const AdminPortalPage(),
          const AllCategories(),
        ];
      case 'chef':
        return [
          const _HomeContent(),
          const AllCategories(),
          const RecipeSubmissionPage(),
          const FavoritesPage()
        ];
      case 'user':
        return [
          const _HomeContent(),
          const AllCategories(),
          const FavoritesPage()
        ];
      case 'guest':
      default:
        return [
          const _HomeContent(),
          const AllCategories(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.4),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.search,
                size: 30,
                color: AppConstants.primaryColor,
              ),
              onPressed: () => _navigateTo(const SearchPage()),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _getPages(),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        drawer: _buildAppDrawer(context),
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(_userRole == 'admin'
            ? Icons.admin_panel_settings_outlined
            : Icons.home_outlined),
        activeIcon: Icon(
            _userRole == 'admin' ? Icons.admin_panel_settings : Icons.home),
        label: _userRole == 'admin' ? 'Admin' : 'Home',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.restaurant_menu_outlined),
        activeIcon: const Icon(Icons.restaurant_menu),
        label: 'Categories',
      ),
    ];

    if ( _userRole == 'chef') {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outlined),
        activeIcon: Icon(Icons.add_circle, color: Colors.blue),
        label: 'Post',
      ));
    }

    if (_userRole == 'chef' || _userRole == 'user') {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.favorite_outline),
        activeIcon: Icon(Icons.favorite, color: AppConstants.accentColor),
        label: 'Favorites',
      ));
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppConstants.primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 8,
      items: items,
      onTap: _onItemTapped,
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              accountName: Text(
                _userName.isNotEmpty
                    ? _userName[0].toUpperCase() + _userName.substring(1)
                    : 'Guest',
                style: const TextStyle(fontSize: 18),
              ),
              accountEmail: Text(_userEmail),
              currentAccountPicture: _userProfileImage.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(_userProfileImage),
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_userRole == 'admin' || _userRole == 'chef')
                    ListTile(
                      leading: Icon(Icons.person_outline,
                          color: Colors.grey.shade700),
                      title: const Text('Profile',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () => _navigateTo(ProfilePage(userId: _userId)),
                    ),
                  if (_userRole == 'user')
                    ListTile(
                      leading: Icon(Icons.verified_user,
                          color: Colors.grey.shade700),
                      title: const Text('Apply to be a Chef',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () => _navigateTo(PromotionPage()),
                    ),
                  if (_userRole == 'admin')
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings,
                          color: Colors.grey.shade700),
                      title: const Text('Admin Portal',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () => _navigateTo(const AdminPortalPage()),
                    ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.grey.shade700),
                    title: const Text('Log Out',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () => _showLogoutConfirmation(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Update the logout method
  void _logout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Check if user signed in with Google
      if (user != null &&
          user.providerData.any((info) => info.providerId == 'google.com')) {
        await GoogleSignIn().disconnect();
      }

      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late Future<List<dynamic>> _dataFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    print("Initiating data load...");
    setState(() {
      // Add setState to trigger rebuild
      _dataFuture = Future.wait([
        _getTopRatedRecipes(),
        _getStaticCategories(),
        _getRecommendedRecipes(),
        _getNewRecipes(),
      ]);
    });
  }

  Future<List<Recipe>> _getTopRatedRecipes() async {
    try {
      print("Fetching top rated recipes...");
      final snapshot = await _firestore
          .collection('recipes')
          .orderBy('averageRating', descending: true)
          .limit(5)
          .get();

      print("Received ${snapshot.docs.length} recipes");
      if (snapshot.docs.isEmpty) print("No approved recipes found");

      return snapshot.docs.map((doc) {
        print("Processing recipe: ${doc.id}");
        return Recipe.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print("Error fetching top recipes: ${e.toString()}");
      throw e;
    }
  }

  Future<List<Recipe>> _getNewRecipes() async {
    try {
      print("Fetching top rated recipes...");
      final snapshot = await _firestore
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      print("Received ${snapshot.docs.length} recipes");
      if (snapshot.docs.isEmpty) print("No approved recipes found");

      return snapshot.docs.map((doc) {
        print("Processing recipe: ${doc.id}");
        return Recipe.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print("Error fetching top recipes: ${e.toString()}");
      throw e;
    }
  }

  Future<List<Recipe>> _getRecommendedRecipes() async {
    try {
      print("Fetching recommended recipes...");
      // Only get approved recipes to ensure they can be displayed
      final snapshot = await _firestore
          .collection('recipes')
          .where('status', isEqualTo: 'approved')
          .limit(10)
          .get();

      print("Found ${snapshot.docs.length} approved recipes");

      if (snapshot.docs.isEmpty) {
        print("No approved recipes found for recommendations");
        return [];
      }

      // Process each document with better error handling
      final List<Recipe> recipes = [];
      for (var doc in snapshot.docs) {
        try {
          print("Processing recommended recipe: ${doc.id}");
          final recipe = Recipe.fromFirestore(doc);
          recipes.add(recipe);
        } catch (e) {
          print("Error processing recipe ${doc.id}: $e");
          // Continue with next recipe instead of failing the whole function
        }
      }

      // If we have recipes, shuffle them and take up to 5
      if (recipes.isNotEmpty) {
        recipes.shuffle();
        return recipes.take(5).toList();
      } else {
        print("No valid recipes found after processing");
        return [];
      }
    } catch (e, stack) {
      print("Error fetching recommended recipes: $e");
      print("Stack trace: $stack");
      // Return empty list instead of throwing
      return [];
    }
  }

  Future<List<Category>> _getStaticCategories() async {
    print("Loading static categories...");
    try {
      return [
        Category(
          id: '1',
          title: 'Breakfast',
          categoryImage: 'asset/Category/breakfast.webp',
        ),
        Category(
          id: '2',
          title: 'Dinner',
          categoryImage: 'asset/Category/dinner1.jpg',
        ),
        Category(
          id: '3',
          title: 'Salad',
          categoryImage: 'asset/Category/salad.jpg',
        ),
      ];
    } catch (e) {
      print("Category error: ${e.toString()}");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snapshot) {
        print("Builder state: ${snapshot.connectionState}");
        print("Has error: ${snapshot.hasError}");
        print("Has data: ${snapshot.hasData}");

        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error details: ${snapshot.error}");
          return _buildErrorWidget();
        }

        final topRatedRecipes = snapshot.data![0] as List<Recipe>;
        final categories = snapshot.data![1] as List<Category>;
        final recommendedRecipes = snapshot.data![2] as List<Recipe>;
        final newRecipes = snapshot.data![3] as List<Recipe>;

        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            return;
          },
          child: ListView(
            children: [
              _buildSectionTitle("Top Rated"),
              _buildCarouselSlider(context, topRatedRecipes),
              _buildSectionTitleWithAction(
                "Categories",
                "View All",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllCategories()),
                ),
              ),
              _buildCategoryGrid(categories),
              _buildSectionTitle("Recommendation"),
              _buildRecipeList(context, recommendedRecipes),
              _buildSectionTitle("New Recipes"),
              _buildRecipeList(context, newRecipes),
              _buildSectionTitle("Tips"),
              _buildSectionTip(
                "Cooking Techniques",
                "Baking involves cooking food in an oven...",
                "asset/cooking.gif",
              ),
              _buildSectionTip(
                "Food Storage",
                "Refrigerate most fruits and vegetables...",
                "asset/foodstorage.gif",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red[700]),
          const SizedBox(height: 15),
          const Text(
            'Failed to load data. Possible issues:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            '1. No internet connection\n'
            '2. Firestore permissions issue\n'
            '3. Missing required recipe fields\n'
            '4. No approved recipes in database',
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _loadData()),
            child: const Text('Try Again'),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTip(String title, String description, String imagePath) {
    return TipSection(
      title: title,
      description: description,
      imagePath: imagePath,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20),
      child: Text(title, style: AppConstants.sectionTitleStyle),
    );
  }

  Widget _buildSectionTitleWithAction(
    String title,
    String actionText,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppConstants.sectionTitleStyle),
          InkWell(
            onTap: onTap,
            child: Text(actionText, style: AppConstants.actionTextStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider(BuildContext context, List<Recipe> recipes) {
    return CarouselSlider(
      items: recipes
          .map((recipe) => CarouselRecipeCard(
                recipeTitle: recipe.name,
                recipeDescription: recipe.description,
                dishImage: recipe.dishImage,
                rating: recipe.averageRating,
                difficultyLevel: recipe.difficulty.toString().split('.').last,
                preparationTime: "${recipe.preparationTime} MIN",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailPage(recipe: recipe),
                    ),
                  );
                  if (mounted) _loadData();
                },
              ))
          .toList(),
      options: CarouselOptions(
        height: 300,
        viewportFraction: 1,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        enlargeCenterPage: true,
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return SizedBox(
      height: 230,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories
            .take(4)
            .map((category) => CategoryItem(
                  title: category.title,
                  imagePath: category.categoryImage,
                  page: CategoryDetailPage(category: category),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRecipeList(BuildContext context, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                "No recommendations available",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.separated(
        // Changed to ListView.separated for better control
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return SizedBox(
            width: 330, // Card width
            child: RecipeCard(
              recipeName: recipe.name,
              dishImage: recipe.dishImage,
              rating: recipe.averageRating,
              preparationTime: "${recipe.preparationTime} MIN",
              difficultyLevel: recipe.difficulty.toString().split('.').last,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailPage(recipe: recipe),
                  ),
                );
                if (mounted) _loadData();
              },
            ),
          );
        },
        separatorBuilder: (context, index) =>
            const SizedBox(width: 12), // Space between cards
      ),
    );
  }
}
