import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sample_app/models/recipe_model.dart';
import 'package:sample_app/views/receipe_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  final String _defaultImageUrl = 'https://wallpaperaccess.com/full/767048.jpg'; // Valid placeholder image URL
  String _searchQuery = '';
  bool _isSearching = false; // Track if search is active

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    QuerySnapshot snapshot = await _firestore.collection('recipes').get();
    setState(() {
      _recipes = snapshot.docs.map((doc) => Recipe.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
      _filteredRecipes = _recipes; // Initialize filtered recipes
    });
  }

  void _searchRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) => recipe.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    });
  }

  Future<void> _deleteRecipe(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).delete();
    _fetchRecipes(); // Refresh the recipe list after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cookbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching; // Toggle search mode
                if (!_isSearching) {
                  _searchQuery = ''; // Clear search query when exiting search
                  _filteredRecipes = _recipes; // Reset to all recipes
                }
              });
            },
          ),
        ],
      ),
      body: _isSearching
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value; // Update search query
                      });
                      _searchRecipes(); // Call search method
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: _filteredRecipes.isEmpty
                        ? const Center(child: Text('No recipes found.'))
                        : ListView.builder(
                            itemCount: _filteredRecipes.length,
                            itemBuilder: (context, index) {
                              final recipe = _filteredRecipes[index];
                              return _buildRecipeCard(recipe);
                            },
                          ),
                  ),
                ],
              ),
            )
          : _buildRecipeList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeScreen()),
          );
          if (result != null) {
            // If a recipe was added or edited, refresh the recipe list
            _fetchRecipes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecipeList() {
    return _recipes.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _recipes.length,
            itemBuilder: (context, index) {
              final recipe = _recipes[index];
              return _buildRecipeCard(recipe);
            },
          );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    bool _isExpanded = false; // Track the expansion state of the card

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  // Navigate to the RecipeScreen to edit the recipe
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeScreen(recipe: recipe), // Pass the selected recipe
                    ),
                  );
                  if (result != null) {
                    _fetchRecipes(); // Refresh the recipe list if updated
                  }
                },
                child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            children: [
                              const Center(child: Text('Issue loading image')),
                            ],
                          );
                        },
                      )
                    : Image.network(
                        _defaultImageUrl,
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  recipe.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(recipe.description),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded; // Toggle expansion state
                      });
                    },
                    child: Text(_isExpanded ? 'Hide Ingredients' : 'View Ingredients'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Confirm deletion
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Recipe'),
                          content: const Text('Are you sure you want to delete this recipe?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteRecipe(recipe.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Ingredients:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipe.ingredients.isEmpty
                        ? [Text('No ingredients available')] // Show this message if the list is empty
                        : recipe.ingredients
                            .map((ingredient) => Text('• ${ingredient.name} (${ingredient.quantity})')) // Display name and quantity
                            .toList(),
                  ),
                )
              ],
            ],
          ),
        );
      },
    );
  }
}
