import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

TextEditingController categoryController = TextEditingController();
TextEditingController nameController = TextEditingController();
TextEditingController cooktimeController = TextEditingController();
TextEditingController difficultyController = TextEditingController();
TextEditingController ratingController = TextEditingController();
TextEditingController imageController1 = TextEditingController();
TextEditingController imageController2 = TextEditingController();

List<QueryDocumentSnapshot<Object?>>? documents;

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Recipe',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(
            255, 10, 40, 98), 
      ),
      floatingActionButton: FloatingActionButton(  
        onPressed: () async {
          String collectionName = categoryController.text;

          if (double.tryParse(ratingController.text) == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please enter a valid number for rating')),
            );
            return;
          }

          await FirebaseFirestore.instance.collection(collectionName).add(
            {
              "name": nameController.text,
              "cooktime": cooktimeController.text,
              "difficulty": difficultyController.text,
              "rating":
                  double.parse(ratingController.text), 
              "photo1": imageController1.text,
              "photo2": imageController2.text,
            },
          );

          categoryController.clear();
          nameController.clear();
          cooktimeController.clear();
          difficultyController.clear();
          ratingController.clear();
          imageController1.clear();
          imageController2.clear();
        },

        backgroundColor: Colors.blueAccent,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildTextField(categoryController, 'Category'),
          _buildTextField(nameController, 'Name'),
          _buildTextField(cooktimeController, 'Cook Time'),
          _buildTextField(difficultyController, 'Difficulty'),
          _buildTextField(ratingController, 'Rating',
              isNumeric: true), 
          _buildTextField(imageController1, 'Photo 1 URL'),
          _buildTextField(imageController2, 'Photo 2 URL'),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('kkk').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                documents = snapshot.data!.docs;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: documents!
                      .map(
                        (e) => GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(4, 8),
                                ),
                              ],
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 20),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            e['name'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          CachedNetworkImage(
                                            imageUrl: (e['photo1']) ??
                                                '', // Ensure 'photo1' field exists
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder,
      {bool isNumeric = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: CupertinoTextField(
        controller: controller,
        padding: const EdgeInsets.all(15),
        placeholder: placeholder,
        keyboardType: isNumeric
            ? TextInputType.number
            : TextInputType.text,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color.fromARGB(255, 39, 94, 190)), 
        ),
      ),
    );
  }
}
