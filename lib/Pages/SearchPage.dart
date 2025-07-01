import 'dart:async';
import 'package:cap/Pages/FilterPage.dart';
import 'package:cap/Pages/ProfilePage.dart';
import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:cap/constants.dart';
import 'package:cap/firebase/services/UserService.dart';
import 'package:cap/firebase/services/recipe_service.dart';
import 'package:flutter/material.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:cap/models/user_model.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Filter _currentFilter = const Filter();
  List<Recipe> _recipeResults = [];
  List<AppUser> _chefResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
     WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _performSearch);
  }
void _showFilterDialog() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FilterDialog(
        initialFilter: _currentFilter,
        onApply: (newFilter) {
          setState(() => _currentFilter = newFilter);
          _performSearch();
        },
      ),
    ),
  );
}

Future<void> _performSearch() async {
  final query = _searchController.text.trim().toLowerCase();

  if (!mounted) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

     List<Recipe> recipes = query.isEmpty 
        ? await recipeService.getAllRecipes() // Add this method to your RecipeService
        : await recipeService.searchRecipes(query);
    final chefs = query.isEmpty
        ? [] // Don't show chefs when searching all recipes
        : await userService.searchChefsByName(query);
    // Deduplicate recipes by ID
    var uniqueRecipes = recipes.fold<Map<String, Recipe>>({}, (map, recipe) {
      map.putIfAbsent(recipe.id, () => recipe);
      return map;
    }).values.toList();

    // Apply filters
    if (_currentFilter.isNotEmpty) {
      uniqueRecipes = uniqueRecipes.where((recipe) {
        bool matches = true;
        
        // Difficulty filter
        if (_currentFilter.difficulty != null) {
          matches &= recipe.difficulty == _currentFilter.difficulty;
        }
        
        // Category filter
        if (_currentFilter.category != null) {
          matches &= recipe.category.title
              .toLowerCase()
              .contains(_currentFilter.category!.toLowerCase());
        }
        
        // Preparation time filters
        if (_currentFilter.minPreparationTime != null) {
          matches &= recipe.preparationTime >= _currentFilter.minPreparationTime!;
        }
        
        if (_currentFilter.maxPreparationTime != null) {
          matches &= recipe.preparationTime <= _currentFilter.maxPreparationTime!;
        }
        
        return matches;
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      _recipeResults = uniqueRecipes;
      _chefResults = chefs.cast<AppUser>();
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _errorMessage = 'Search failed: ${e.toString()}');
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _recipeResults = [];
      _chefResults = [];
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        )),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list,
            color: Colors.white,
            size: 24,
            ),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppConstants.primaryColor,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppConstants.primaryColor,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            hintText: 'Recipes, chefs, ingredients...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.primaryColor ?? Colors.blue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    if (_recipeResults.isEmpty && _chefResults.isEmpty) {
    // Show welcome state if no search and no filters
    if (_searchController.text.isEmpty && !_currentFilter.isNotEmpty) {
      return _buildWelcomeState();
    }
    return _buildEmptyState();
  }

    return CustomScrollView(
      slivers: [
        if (_chefResults.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader('Top Chefs'),
            ),
          ),
        if (_chefResults.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildChefCard(_chefResults[index]),
                childCount: _chefResults.length,
              ),
            ),
          ),
        if (_recipeResults.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader('Recipe Matches'),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _RecipeCard(recipe: _recipeResults[index]),
              childCount: _recipeResults.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_rounded,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'Search Recipes & Chefs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Start typing to discover recipes or use the filters to narrow your search',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildChefCard(AppUser chef) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage(userId: chef.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: chef.profileImage != null
                    ? NetworkImage(chef.profileImage!)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chef.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chef.bio ?? 'Professional Chef',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try searching for recipes, ingredients, or chef names',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              _buildImage(),
              _buildGradientOverlay(),
              _buildRecipeInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      recipe.dishImage,
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor ?? Colors.blue),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.restaurant_menu, color: Colors.grey),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
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
              height: 1.3,
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
}
class ChefCard extends StatefulWidget {
  final AppUser chef;
  final int recipeCount;
  final int yearsExperience;
  
  const ChefCard({
    super.key,
    required this.chef,
    required this.recipeCount,
    required this.yearsExperience,
  });

  @override
  State<ChefCard> createState() => _ChefCardState();
}

class _ChefCardState extends State<ChefCard> with SingleTickerProviderStateMixin {
  bool _isFollowing = false;
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),
                  // Expandable Content
                  SizeTransition(
                    sizeFactor: _heightAnimation,
                    child: _buildExpandableContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Background Image
        Container(
          height: 120,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.chef.profileImage ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Profile Info
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.chef.profileImage ?? ''),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chef.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.chef.bio ?? 'Professional Chef',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFollowing ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => setState(() => _isFollowing = !_isFollowing),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.restaurant_menu, '${widget.recipeCount}+ Recipes'),
              _buildStatItem(Icons.work_history, '${widget.yearsExperience} Years'),
              _buildStatItem(Icons.star, '4.9 Rating'),
            ],
          ),
          SizedBox(height: 16),
          
          // Specializations
          Wrap(
            spacing: 8,
            children: widget.chef.specializations.map((spec) => Chip(
              label: Text(spec),
              backgroundColor: Colors.blue.shade100,
            )).toList(),
          ),
          
          SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.person_outline),
                  label: Text('View Profile'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: widget.chef.id),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.collections_bookmark),
                  label: Text('Recipes'),
                  onPressed: () {/* Navigate to chef's recipes */},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Filter {
  final Difficulty? difficulty;
  final String? category;
  final int? minPreparationTime;
  final int? maxPreparationTime;

  const Filter({
    this.difficulty,
    this.category,
    this.minPreparationTime,
    this.maxPreparationTime,
  });

  bool get isNotEmpty =>
      difficulty != null ||
      category != null ||
      minPreparationTime != null ||
      maxPreparationTime != null;
}