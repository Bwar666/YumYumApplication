import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cap/Pages/EmailVerificationPage.dart';
import 'package:cap/Pages/HomePage.dart';
import 'package:cap/Pages/ProfilePage.dart';
import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:cap/Pages/SignupPage.dart';
import 'package:cap/Pages/SplashPage.dart';
import 'package:cap/Pages/favouritePage.dart';
import 'package:cap/Pages/loginPage.dart';
import 'package:cap/UserProvider.dart';
import 'package:cap/firebase/firebase_options.dart';
import 'package:cap/firebase/services/UserService.dart';
import 'package:cap/firebase/services/admin_service.dart';
import 'package:cap/firebase/services/favorite_service.dart';
import 'package:cap/firebase/services/recipe_service.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        StreamProvider<User?>(
          create: (context) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        Provider<AdminService>(create: (_) => AdminService()),
        Provider<FavoriteService>(create: (_) => FavoriteService()),
        Provider<RecipeService>(create: (_) => RecipeService()),
        Provider<UserService>(create: (_) => UserService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription? _sub;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleInitialDeepLink();
    if (!kIsWeb) {
      _setupUriStream();
    }
  }

  void _setupUriStream() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (!mounted) return;
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      if (!mounted) return;
      print('Error on uri stream: $err');
    });
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } on PlatformException {
      // Handle exception
    } catch (e) {
      print('Error getting initial uri: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'cap' && uri.host == 'recipe') {
      final recipeId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      if (recipeId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            '/recipe',
            arguments: recipeId,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/splash',
      routes: {
        '/': (context) => _getInitialScreen(context),
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const Login(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const Home(),
        '/profile': (context) => const ProfilePage(),
        '/favorites': (context) => const FavoritesPage(),
        '/email-verify': (context) => const EmailVerificationScreen(email: ''),
        '/recipe': (context) {
          final recipeId = ModalRoute.of(context)!.settings.arguments as String;
          return FutureBuilder<Recipe?>(
            future: context.read<RecipeService>().getRecipeById(recipeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return RecipeDetailPage(recipe: snapshot.data!);
                } else {
                  return Scaffold(
                    body: Center(child: Text('Recipe not found')),
                  );
                }
              } else {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        },
      },
    );
  }

  Widget _getInitialScreen(BuildContext context) {
    final user = Provider.of<User?>(context);
    return user != null ? const Home() : const Login();
  }
}