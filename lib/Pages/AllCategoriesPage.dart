import 'package:cap/Pages/CategoryDetailPage.dart';
import 'package:cap/constants.dart';
import 'package:cap/models/category.dart';
import 'package:cap/ui_components.dart';
import 'package:flutter/material.dart';

class AllCategories extends StatefulWidget {
  const AllCategories({super.key});

  @override
  State<AllCategories> createState() => _AllCategoriesState();
}

class _AllCategoriesState extends State<AllCategories> {
  // Predefined local categories
  final List<Category> _categories =  [
    Category(
      id: '1',
      title: 'Breakfast',
      categoryImage: 'asset/Category/breakfast.webp',
    ),
    Category(
      id: '2',
      title: 'Lunch',
      categoryImage: 'asset/Category/lunch.jpeg',
    ),
    Category(
      id: '3',
      title: 'Dinner',
      categoryImage: 'asset/Category/dinner1.jpg',
    ),
    Category(
      id: '4',
      title: 'Dessert',
      categoryImage: 'asset/Category/desert.jpg',
    ),
    Category(
      id: '5',
      title: 'Fast Food',
      categoryImage: 'asset/Category/fastfood2.jpg',
    ),
    Category(
      id: '6',
      title: 'Kurdish Food',
      categoryImage: 'asset/Category/kurdishfood.jpg',
    ),
     Category(
      id: '7',
      title: 'Salad',
      categoryImage: 'asset/Category/salad.jpg',
    ),
    Category(
      id: '8',
      title: 'Appetizers',
      categoryImage: 'asset/Category/appetizers.jpg',
    ),
     Category(
      id: '9',
      title: 'test',
      categoryImage: 'asset/Category/seafood.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10, bottom: 10),
            child: Text(
              "All Categories",
              style: AppConstants.sectionTitleStyle,
            ),
          ),
          ..._categories.map((category) => _buildCategoryCard(context, category)).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryDetailPage(category: category),
        ),
      ),
      child: CategoryItem(
        title: category.title,
        imagePath: category.categoryImage,
        page: CategoryDetailPage(category: category),
        width: 500,
        height: 150,
        titlePosition: 3.5,
      ),
    );
  }
}