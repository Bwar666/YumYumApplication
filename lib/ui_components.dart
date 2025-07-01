// ui_components.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'constants.dart';

class DifficultyUtils {
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'normal':
        return Colors.amber;
      case 'hard':
      case 'difficult':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.eco_rounded;
      case 'normal':
        return Icons.fastfood_rounded;
      case 'hard':
      case 'difficult':
        return Icons.whatshot_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isSmall;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;

  const MetaChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.isSmall = false,
    this.horizontalPadding = 10,
    this.verticalPadding = 5,
    this.fontSize = 11,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 120,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? horizontalPadding * 0.7 : horizontalPadding,
        vertical: isSmall ? verticalPadding * 0.7 : verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: isSmall ? iconSize * 0.9 : iconSize, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? fontSize * 1 : fontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String recipeName;
  final String backgroundImage;
  final String dishImage;
  final double rating;
  final String preparationTime;
  final String difficultyLevel;
  final double heightOfCard;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipeName,
    this.backgroundImage = "asset/cementpic2.jpeg",
    required this.dishImage,
    required this.rating,
    required this.preparationTime,
    required this.difficultyLevel,
    required this.onTap,
    this.heightOfCard = 200,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
            child: Container(
              width: double.infinity,
              height: heightOfCard,
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.95,
                minHeight: 160,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  // Fixed image declaration
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          dishImage,
                          width: isSmallScreen ? 120 : 140,
                          height: isSmallScreen ? 90 : 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              recipeName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              minFontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              MetaChip(
                                icon: Icons.access_time_outlined,
                                text: preparationTime,
                                color: Colors.blue.shade400,
                                isSmall: isSmallScreen,
                              ),
                              MetaChip(
                                icon: DifficultyUtils.getDifficultyIcon(
                                    difficultyLevel),
                                text: difficultyLevel,
                                color: DifficultyUtils.getDifficultyColor(
                                    difficultyLevel),
                                isSmall: isSmallScreen,
                              ),
                            ],
                          ),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? 130 : 150,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RatingBarIndicator(
                                  rating: rating,
                                  itemBuilder: (context, index) => const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: isSmallScreen ? 17 : 20,
                                  unratedColor: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
class CarouselRecipeCard extends StatelessWidget {
  final String recipeTitle;
  final String recipeDescription;
  final String backgroundImage;
  final String dishImage;
  final double rating;
  final String preparationTime;
  final String difficultyLevel;
  final VoidCallback onTap;

  const CarouselRecipeCard({
    super.key,
    required this.recipeTitle,
    required this.recipeDescription,
    this.backgroundImage = "asset/cementpic2.jpeg",
    required this.dishImage,
    required this.rating,
    required this.preparationTime,
    required this.difficultyLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(backgroundImage),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),

              // Dish image with rounded corners
              Positioned(
                right: -40,
                top: 30,
                child: Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        dishImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // Text content
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe title with constrained width
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5),
                      child: AutoSizeText(
                        recipeTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        maxFontSize: 28,
                      ),
                    ),

                    // Recipe description with constrained width
                    Padding(
                      padding: const EdgeInsets.only(top: 15, right: 120),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                          recipeDescription,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Metadata chips and rating
                    Row(
                      children: [
                        MetaChip(
                          icon: Icons.schedule_rounded,
                          text: preparationTime,
                          color: Colors.blue.shade400,
                        ),
                        const SizedBox(width: 10),
                        MetaChip(
                          icon: DifficultyUtils.getDifficultyIcon(difficultyLevel),
                          text: difficultyLevel,
                          color: DifficultyUtils.getDifficultyColor(difficultyLevel),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              RatingBarIndicator(
                                rating: rating,
                                itemBuilder: (context, index) => Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 17,
                                unratedColor: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class CategoryItem extends StatelessWidget {
  final String title;
  final String imagePath;
  final Widget page;
  final double width;
  final double height;
  final double titlePosition;

  const CategoryItem(
      {required this.title,
      required this.imagePath,
      required this.page,
      this.width = 250, // Default width
      this.height = 400,
      this.titlePosition = 8 // Default height
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (error, stackTrace) => Container(
                color: Colors.grey[200],
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: width,
              height: height / titlePosition,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Add to ui_components.dart
class TipSection extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const TipSection({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTipImage(),
            _buildTipContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: Image.asset(
        imagePath,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          height: 180,
          child: const Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }

  Widget _buildTipContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipHeader(),
          const SizedBox(height: 15),
          _buildDescription(),
          const SizedBox(height: 15),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TipBadge(
                text: 'Time Saver',
                icon: Icons.access_time,
                iconColor: Colors.green,
              ),
              TipBadge(
                text: 'Health Tips',
                icon: Icons.favorite_border,
                iconColor: Colors.red,
              ),
              TipBadge(
                text: 'Beginner',
                icon: Icons.star_border,
                iconColor: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor?.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            color: AppConstants.primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppConstants.primaryColor ?? Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }
}

class TipBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? iconColor;

  const TipBadge({
    super.key,
    required this.text,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppConstants.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final BuildContext context;
  final List<DrawerItem> drawerItems;
  final Function(DrawerItem) onItemTap;
  final VoidCallback onLogoutPressed;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AppDrawer({
    super.key,
    required this.context,
    required this.drawerItems,
    required this.onItemTap,
    required this.onLogoutPressed,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            _buildDrawerList(),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(20),
        ),
      ),
      accountName: const Text("Bwar", style: TextStyle(fontSize: 18)),
      accountEmail: const Text("BwarHakeem@gmail.com"),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          "B",
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerList() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: drawerItems
            .map((item) => ListTile(
                  leading: Icon(item.icon, color: Colors.grey.shade700),
                  title: Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () => onItemTap(item),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.darkAccentColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text("Log Out", style: TextStyle(color: Colors.white)),
          onPressed: onLogoutPressed,
        ),
      ),
    );
  }
}

enum DrawerItemType { profile, language, support, settings }

class DrawerItem {
  final IconData icon;
  final String title;
  final DrawerItemType type;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.type,
  });
}
