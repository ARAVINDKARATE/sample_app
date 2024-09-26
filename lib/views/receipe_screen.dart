import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_app/models/ingredient_model.dart';
import 'package:sample_app/models/recipe_model.dart';
import 'package:sample_app/views/ingredient_selector_screen.dart'; // Import the ingredient selector screen

class RecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  RecipeScreen({this.recipe});

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _description, _instructions;
  List<Ingredient> _ingredients = [];
  String? _imageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Edit Recipe' : 'Add Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Recipe Name'),
                initialValue: widget.recipe?.name ?? '',
                onSaved: (value) => _name = value,
                validator: (value) => value!.isEmpty ? 'Enter a recipe name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                initialValue: widget.recipe?.description ?? '',
                onSaved: (value) => _description = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Instructions'),
                initialValue: widget.recipe?.instructions ?? '',
                onSaved: (value) => _instructions = value,
              ),
              // Button to navigate to ingredient selection screen
              ElevatedButton(
                onPressed: () async {
                  final selectedIngredients = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => IngredientsScreen()),
                  );

                  if (selectedIngredients != null) {
                    setState(() {
                      _ingredients = List<Ingredient>.from(selectedIngredients);
                    });
                  }
                },
                child: Text('Select Ingredients'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('${_ingredients[index].name} (${_ingredients[index].quantity})'),
                    );
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_a_photo),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _imageUrl = pickedFile.path; // Upload to Firebase if needed
                    });
                  }
                },
              ),
              ElevatedButton(
                onPressed: _submitRecipe,
                child: Text('Save Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRecipe() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Recipe newRecipe = Recipe(
        id: widget.recipe?.id ?? _firestore.collection('recipes').doc().id,
        name: _name!,
        description: _description!,
        instructions: _instructions!,
        ingredients: _ingredients,
        imageUrl: _imageUrl,
      );

      _firestore.collection('recipes').doc(newRecipe.id).set(newRecipe.toJson()).then((_) {
        Navigator.pop(context);
      });
    }
  }
}
