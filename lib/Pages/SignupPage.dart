import 'package:cap/Pages/EmailVerificationPage.dart';
import 'package:cap/Pages/loginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isUsernameValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;

Future<void> _submitSignup() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
  final credential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(
    email: _emailController.text,
    password: _passwordController.text,
  );

  // Send verification email
  await credential.user!.sendEmailVerification();

  // Save user data to Firestore
  await FirebaseFirestore.instance
      .collection('users')
      .doc(credential.user!.uid)
      .set({
    'id': credential.user!.uid,
    'name': _usernameController.text,
    'email': credential.user!.email,
    'role': 'user',
    'favorites': [],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User Registered Successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate after a short delay
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => EmailVerificationScreen(email: _emailController.text),
    ),
  );
  } on FirebaseAuthException catch (e) {
    String message = 'Signup failed';
    if (e.code == 'weak-password') {
      message = 'Password is too weak';
    } else if (e.code == 'email-already-in-use') {
      message = 'Email is already registered';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration failed')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      setState(() => _isUsernameValid = false);
      return 'Please enter username';
    }
    setState(() => _isUsernameValid = true);
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      setState(() => _isEmailValid = false);
      return 'Please enter email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      setState(() => _isEmailValid = false);
      return 'Invalid email format';
    }
    setState(() => _isEmailValid = true);
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      setState(() => _isPasswordValid = false);
      return 'Please enter password';
    }
    if (value.length < 8) {
      setState(() => _isPasswordValid = false);
      return 'Password must be at least 8 characters';
    }
    setState(() => _isPasswordValid = true);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackgroundImage(),
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderText(),
                _buildSignupForm(),
                _buildLoginPrompt(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "asset/signuppic.jpg",
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

  Widget _buildHeaderText() {
    return Column(
      children: [
        const SizedBox(height: 70),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            "Welcome to Yum Yum",
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
          child: Text(
            "Sign Up and Discover Delicious Recipes",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildUsernameField(),
              const SizedBox(height: 20),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 40),
              _buildSignupButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Username",
        labelStyle:
            TextStyle(color: _isUsernameValid ? Colors.white : Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              BorderSide(color: _isUsernameValid ? Colors.white : Colors.red),
        ),
        suffixIcon: Icon(Icons.person_outline,
            color: _isUsernameValid ? Colors.white : Colors.red),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: _validateUsername,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Email",
        labelStyle: TextStyle(color: _isEmailValid ? Colors.white : Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              BorderSide(color: _isEmailValid ? Colors.white : Colors.red),
        ),
        suffixIcon:
            Icon(Icons.email, color: _isEmailValid ? Colors.white : Colors.red),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      style: const TextStyle(color: Colors.white),
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle:
            TextStyle(color: _isPasswordValid ? Colors.white : Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              BorderSide(color: _isPasswordValid ? Colors.white : Colors.red),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: _isPasswordValid ? Colors.white : Colors.red,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.4),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      onPressed: _isLoading ? null : _submitSignup,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Create Account",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLoginPrompt() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Center(
        child: TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          ),
          child: const Text(
            "Already signed up? Login",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
