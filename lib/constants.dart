import 'package:flutter/material.dart';

class AppConstants {
  static final primaryColor = Colors.blue[900];
  static const accentColor = Colors.red;
  static final darkAccentColor = Colors.red[900];
  
  static const cardRadius = 25.0;

  // Recipe Title Styles
  static TextStyle recipeTitleStyle = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.w900,
    color: Colors.black87,
    letterSpacing: 1.2,
    height: 1.1,
    shadows: [
      Shadow(
        blurRadius: 2.0,
        color: Colors.black12,
        offset: Offset(1.0, 1.0),
      ),
    ],
  );

  // Section Title Style
  static TextStyle sectionTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryColor ?? Colors.blue,
  );

  // Action Text Style
  static TextStyle actionTextStyle = TextStyle(
    fontSize: 18,
    color: primaryColor ?? Colors.blue,
    fontWeight: FontWeight.w500,
  );

  // Optional: Add a subtitle style for recipe variations
  static TextStyle recipeSubtitleStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w500,
    color: Colors.grey[700],
    fontStyle: FontStyle.italic,
  );
}