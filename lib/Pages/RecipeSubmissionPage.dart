import 'dart:async';
import 'dart:io';
import 'package:cap/UserProvider.dart';
import 'package:cap/firebase/services/FirebaseRecipeService.dart';
import 'package:cap/models/category.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:cap/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:provider/provider.dart';

class RecipeSubmissionPage extends StatefulWidget {
  final Recipe? recipeToEdit;
  const RecipeSubmissionPage({Key? key, this.recipeToEdit}) : super(key: key);

  @override
  _RecipeSubmissionPageState createState() => _RecipeSubmissionPageState();
}

class _RecipeSubmissionPageState extends State<RecipeSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  
  File? _selectedImage;
  final List<String> _ingredients = [];
  final List<String> _steps = [];
  String? _selectedDifficulty;
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _difficultyLevels = ['easy', 'normal', 'hard'];
  final List<String> _categories = [
    'Dinner',
    'Breakfast',
    'Lunch',
    'Fast Food',
    'Appetizers',
    'Salad',
    'Desserts',
    'Kurdish Food'
    ,'test'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      _initializeFormWithRecipe(widget.recipeToEdit!);
    }
}

  void _initializeFormWithRecipe(Recipe recipe) {
    _titleController.text = recipe.name;
    _descriptionController.text = recipe.description;
    _prepTimeController.text = recipe.preparationTime.toString();
    _selectedDifficulty = recipe.difficulty.toString().split('.').last;
    _selectedCategory = recipe.category.title;
    _ingredients.addAll(recipe.ingredients);
    _steps.addAll(recipe.methodSteps);
    _youtubeUrlController.text = recipe.videoUrl ?? '';
  }

  // Add missing methods
  void _addIngredient() {
    if (_ingredientsController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientsController.text);
        _ingredientsController.clear();
      });
    }
  }

  void _addStep() {
    if (_stepsController.text.isNotEmpty) {
      setState(() {
        _steps.add(_stepsController.text);
        _stepsController.clear();
      });
    }
  }

 void _removeItem(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // Replace the _uploadImage() method with:
Future<String> _uploadImage(File image) async {
  try {
    const apiKey = "992f2891c568dd9788397871c993089c"; // Get from https://api.imgbb.com/
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', image.path),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = jsonDecode(responseData);

    if (response.statusCode == 200) {
      return jsonData['data']['url'];
    }
    throw Exception('Image upload failed: ${jsonData['error']['message']}');
  } catch (e) {
    throw Exception('Image upload error: ${e.toString()}');
  }
}
Future<void> _submitRecipe() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedImage == null && widget.recipeToEdit == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red[400],
        content: const Text('📸 Please select a photo for your recipe!'),
      ),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    String? imageUrl = widget.recipeToEdit?.dishImage;

    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
    _showError('User not authenticated');
    return;
  } 
    final recipe = Recipe(
      id: widget.recipeToEdit?.id ?? '',
      name: _titleController.text,
      description: _descriptionController.text,
      dishImage: imageUrl ?? '',
      averageRating: widget.recipeToEdit?.averageRating ?? 0.0,
      preparationTime: int.parse(_prepTimeController.text),
      difficulty: _parseDifficulty(_selectedDifficulty!),
      ingredients: _ingredients,
      methodSteps: _steps,
      category: Category(
        id: '',
        title: _selectedCategory!,
        categoryImage: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      chef: AppUser(
        id: user.uid,
        name: user.displayName ?? 'Anonymous',
        email: user.email ?? '',
        profileImage: user.photoURL ?? '',
      ),
      createdAt: widget.recipeToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      videoUrl: _youtubeUrlController.text.isNotEmpty 
          ? _youtubeUrlController.text 
          : null,
           status: 'pending', 
    );

    if (widget.recipeToEdit != null) {
      await FirebaseRecipeService.updateRecipe(recipe);
    } else {
      await FirebaseRecipeService.createPendingRecipe(recipe);
    }

    _showSuccessDialog();
    _resetForm();
  } catch (e) {
    _showError(e.toString());
  } finally {
    setState(() => _isSubmitting = false);
  }
}

  Difficulty _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'normal':
        return Difficulty.normal;
      case 'hard':
        return Difficulty.hard;
      default:
        throw ArgumentError('Invalid difficulty: $difficulty');
    }
  }
  

  void _resetForm() {
    _formKey.currentState!.reset();
    _titleController.clear();
    _descriptionController.clear();
    _prepTimeController.clear();
    _youtubeUrlController.clear();
    _ingredients.clear();
    _steps.clear();
    _selectedImage = null;
    _selectedDifficulty = null;
    _selectedCategory = null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.recipeToEdit != null ? '🎉 Recipe Updated!' : '🎉 Recipe Submitted!'),
        content: Text(widget.recipeToEdit != null 
            ? 'Recipe updated successfully'
            : 'Your recipe is under review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      final userProvider = Provider.of<UserProvider>(context);
  final user = userProvider.user;

  // Immediate check for unauthenticated users
  if (user == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required to submit recipes'),
          backgroundColor: Colors.red,
        ),
      );
    });
    return const SizedBox.shrink();
  }
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                child: Text('Share Your Recipe',
                    textAlign: TextAlign.center,  
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 28)),
              ),
              _buildImagePicker(),
              const SizedBox(height: 25),
              _buildTextFormField(
                controller: _titleController,
                label: 'Recipe Title',
                icon: Icons.title_outlined,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _prepTimeController,
                label: 'Preparation Time (minutes)',
                icon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                label: 'Difficulty Level',
                icon: Icons.speed,
                items: _difficultyLevels,
                value: _selectedDifficulty,
                onChanged: (value) => setState(() => _selectedDifficulty = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                label: 'Category',
                icon: Icons.fastfood_outlined,
                items: _categories,
                value: _selectedCategory,
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 25),
              _buildListSection(
                title: 'Ingredients',
                controller: _ingredientsController,
                list: _ingredients,
                onAdd: _addIngredient,
              ),
              const SizedBox(height: 25),
              _buildListSection(
                title: 'Cooking Steps',
                controller: _stepsController,
                list: _steps,
                onAdd: _addStep,
              ),
              const SizedBox(height: 25),
              _buildTextFormField(
                controller: _youtubeUrlController,
                label: 'YouTube Video URL (optional)',
                icon: Icons.video_collection,
                validator: (value) {
                  if (value!.isNotEmpty && !value.startsWith('https://')) {
                    return 'Invalid URL format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRecipe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            widget.recipeToEdit != null ? 'Update Recipe' : 'Submit Recipe',
                            style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildDropdownFormField({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required FormFieldValidator<String?> validator,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                errorText: state.errorText,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                  items: items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    onChanged(value);
                    state.didChange(value);
                  },
                ),
              ),
            ),
            if (state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 15, top: 5),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_selectedImage != null)
                Image.file(_selectedImage!, fit: BoxFit.cover),
              Container(
                color: _selectedImage != null 
                    ? Colors.black.withOpacity(0.3) 
                    : Colors.transparent,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          size: 50,
                          color: _selectedImage != null 
                              ? Colors.white 
                              : Colors.blueAccent),
                      Text(
                        _selectedImage != null 
                            ? 'Change Photo' 
                            : 'Tap to Add Dish Photo',
                        style: TextStyle(
                          color: _selectedImage != null 
                              ? Colors.white 
                              : Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildListSection({
    required String title,
    required TextEditingController controller,
    required List<String> list,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800])),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  hintText: 'Add ${title.split(' ')[0]}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blueAccent,
              onPressed: onAdd,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(list.length, (index) => _buildListItem(list[index], index)),
      ],
    );
  }

  Widget _buildListItem(String text, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Dismissible(
        key: Key('$text$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red[100],
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.delete, color: Colors.red[400]),
        ),
        onDismissed: (direction) => _removeItem(
          _steps.length > index ? _steps : _ingredients, index),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: Text('${index + 1}',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            title: Text(text),
            trailing: IconButton(
              icon: Icon(Icons.cancel, color: Colors.red[200]),
              onPressed: () => _removeItem(
                _steps.length > index ? _steps : _ingredients, index),
            ),
          ),
        ),
      ),
    );
  }

    @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }
}
class FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  
  const FilterSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        child,
        const Divider(height: 40),
      ],
    );
  }
}