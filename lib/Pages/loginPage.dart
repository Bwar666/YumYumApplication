
import 'package:cap/Pages/EmailVerificationPage.dart';
import 'package:cap/Pages/Promotion_page.dart';
import 'package:cap/Pages/homePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'signupPage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
try {
  final userCredential = await _auth.signInWithEmailAndPassword(
    email: _emailController.text,
    password: _passwordController.text,
  );

  final user = userCredential.user!;

  

  await _handleAuthSuccess(user);
}  on FirebaseAuthException catch (e) {
      _showError(e.code);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      setState(() => _isEmailValid = false);
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      setState(() => _isEmailValid = false);
      return 'Please enter a valid email address';
    }
    setState(() => _isEmailValid = true);
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      setState(() => _isPasswordValid = false);
      return 'Please enter your password';
    }
    if (value.length < 8) {
      setState(() => _isPasswordValid = false);
      return 'Password must be at least 8 characters';
    }
    setState(() => _isPasswordValid = true);
    return null;
  }
  Future<void> _handleGoogleSignIn() async {
  try {
    setState(() => _isLoading = true);
    
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn(
    );
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = 
      await googleUser.authentication;

    print('Google Auth Data:');
    print('Access Token: ${googleAuth.accessToken}');
    print('ID Token: ${googleAuth.idToken}');

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = 
      await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      await _handleAuthSuccess(userCredential.user!);
    }
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error: ${e.code} - ${e.message}');
    _showError('Google Sign-In failed: ${e.message}');
  } on PlatformException catch (e) {
    print('Platform Error: ${e.code} - ${e.message}');
    _showError('Platform error: ${e.message}');
  } catch (e, stack) {
    print('Unexpected Error: $e');
    print('Stack Trace: $stack');
    _showError('Unexpected error occurred');
  } finally {
    setState(() => _isLoading = false);
  }
}
Future<void> _handleAuthSuccess(User user) async {
 final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final userDoc = await userRef.get();

  if (!userDoc.exists) {
    await userRef.set({
      'id': user.uid,
      'name': user.displayName ?? 'Guest',
      'email': user.email,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profileImage': user.photoURL,
      'favorites': [],
    });
  }
 Navigator.pushReplacementNamed(context, '/home');
}
  void _showError(String errorCode) {
    String message;
    switch (errorCode) {
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      case 'user-not-found':
        message = 'Account not found';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Try again later';
        break;
      default:
        message = 'Authentication failed';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleGuestLogin() async {
    try {
      setState(() => _isLoading = true);
      UserCredential userCredential = await _auth.signInAnonymously();
      await _handleAuthSuccess(userCredential.user!);
    } catch (e) {
      _showError('Guest login failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildLoginForm(),
                  _buildSocialLoginButtons(),
                  _buildBottomSection(),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "asset/loginpic1.jpg",
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
      child: Column(
        children: [
          const Text(
            "Welcome Back",
            style: TextStyle(
              fontSize: 45,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Login to continue your culinary journey",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle:
                    TextStyle(color: _isEmailValid ? Colors.white : Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                      color: _isEmailValid ? Colors.white : Colors.red),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                suffixIcon: Icon(Icons.email,
                    color: _isEmailValid ? Colors.white : Colors.red),
                errorStyle: const TextStyle(color: Colors.red),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                    color: _isPasswordValid ? Colors.white : Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                      color: _isPasswordValid ? Colors.white : Colors.red),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: _isPasswordValid ? Colors.white : Colors.red,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                errorStyle: const TextStyle(color: Colors.red),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.3),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          _buildSocialButton(
            icon: Image.asset("asset/google_icon.png", width: 24, height: 24),
            label: 'Continue with Google',
            color: Colors.white,
            textColor: Colors.black,
            onPressed: _handleGoogleSignIn,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: icon,
      label: Text(label),
      onPressed: onPressed,
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>  Home()),
            ),
            child: const Text(
              'Continue as Guest',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? ",
                  style: TextStyle(color: Colors.white)),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
