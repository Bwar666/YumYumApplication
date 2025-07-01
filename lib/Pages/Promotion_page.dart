import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PromotionPage extends StatefulWidget {
  @override
  _PromotionPageState createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAuthorized = true;

  // Color scheme
  final Color _primaryColor = Colors.blue.shade900;
  final Color _iconColor = Colors.blue;
  final Color _secondaryColor = Color(0xFFF8BBD0);
  final Color _backgroundColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _verifyUserRole();
  }

  Future<void> _verifyUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists || doc['role'] != 'user') {
      setState(() => _isAuthorized = false);
      
    }
  }


  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      _showErrorSnackbar('Please fill all required fields correctly');
      return;
    }

    if (_profileImage == null) {
      _showErrorSnackbar('Please select a profile image');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formData = _formKey.currentState!.value;
      final user = FirebaseAuth.instance.currentUser!;

      final existingRequest = await FirebaseFirestore.instance
          .collection('promotionRequests')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _showErrorSnackbar('Your application is under review.');
        return;
      }
      // Validate experience field
      final experience = int.tryParse(formData['experience']?.toString() ?? '');
      if (experience == null || experience < 0) {
        throw Exception('Please enter valid experience years');
      }

      // Handle certifications
      final certifications =
          formData['certifications']?.toString().split(',') ?? [];

      final imageUrl = await _uploadImage(_profileImage!);

      await FirebaseFirestore.instance.collection('promotionRequests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'bio': formData['bio'],
        'profileImage': imageUrl,
        'yearsExperience': experience,
        'youtubeChannel': formData['youtube_channel'],
        'linkedIn': formData['linkedin'],
        'certifications': certifications,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSuccessDialog(context);
      _formKey.currentState!.reset();
      setState(() => _profileImage = null);
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

// Update the _pickImage method
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: _primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final file = File(croppedFile.path);
        if (await file.exists()) {
          setState(() => _profileImage = file);
        } else {
          _showErrorSnackbar('Selected image not found');
        }
      }
    } catch (e, stack) {
      debugPrint('Image Error: $e\n$stack');
      _showErrorSnackbar('Failed to process image: ${e.toString()}');
    }
  }

// Add these required configurations

  Future<String> _uploadImage(File image) async {
    try {
      const apiKey = "992f2891c568dd9788397871c993089c";
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['data']['url'] as String;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "This page is not allowed for your credentials",
              style: TextStyle(
                  fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chef Application",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        child: Column(
          children: [
            _buildProfilePicker(),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField("full_name", "Full Name",
                          icon: Icons.person),
                      SizedBox(height: 15),
                      _buildTextField("bio", "Bio",
                          maxLines: 3, icon: Icons.description),
                      SizedBox(height: 15),
                      _buildTextField("experience", "Experience Years",
                          isNumeric: true, icon: Icons.date_range_outlined),
                      SizedBox(height: 15),
                      _buildTextField("youtube_channel", "YouTube Channel",
                          optional: true, icon: Icons.video_library),
                      SizedBox(height: 15),
                      _buildTextField("linkedin", "LinkedIn Profile",
                          optional: true, icon: Icons.link),
                      SizedBox(height: 15),
                      _buildTextField(
                          "certifications", "Certifications (comma separated)",
                          icon: Icons.verified_rounded, optional: true),
                      SizedBox(height: 20),
                      _buildTermsCheckbox(),
                      SizedBox(height: 25),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep all UI components below exactly as original
  Widget _buildProfilePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _iconColor, width: 3),
          gradient: LinearGradient(
            colors: [
              _secondaryColor.withOpacity(0.2),
              _primaryColor.withOpacity(0.1)
            ],
          ),
        ),
        child: Stack(
          children: [
            if (_profileImage != null)
              ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover)),
            if (_profileImage == null)
              Center(
                  child: Icon(Icons.camera_alt, size: 40, color: _iconColor)),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String name, String label,
      {bool isNumeric = false,
      int maxLines = 1,
      IconData? icon,
      bool optional = false}) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelStyle: TextStyle(color: _primaryColor),
        hintText: optional ? '(Optional)' : '',
        prefixIcon: icon != null ? Icon(icon, color: _iconColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (!optional && (value == null || value.isEmpty)) {
          return 'Required field';
        }
        if (isNumeric) {
          final numValue = int.tryParse(value ?? '');
          if (numValue == null || numValue < 0) {
            return 'Enter valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return FormBuilderCheckbox(
      name: 'terms',
      title: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey.shade700),
          children: [
            TextSpan(text: "I agree to the "),
            TextSpan(
              text: "terms and conditions",
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
      validator: (value) => value ?? false ? null : 'Must accept terms',
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [_iconColor, _iconColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _isSubmitting ? null : _submitApplication,
        child: _isSubmitting
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Submit Application',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info, color: _primaryColor, size: 40),
              SizedBox(height: 15),
              Text("Application Requirements",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800)),
              SizedBox(height: 15),
              _buildRequirementItem("Minimum 1 year experience"),
              _buildRequirementItem("Valid profile photo"),
              _buildRequirementItem("Complete application form"),
              SizedBox(height: 20),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Got it!"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: _primaryColor),
          SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Application Submitted!"),
        content: const Text("Your request is under review"),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
