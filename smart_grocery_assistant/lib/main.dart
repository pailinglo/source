import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/recipe_detail_model.dart';
import 'services/api_service.dart';
import 'screens/add_grocery_screen.dart';
import 'screens/scan_receipt_screen.dart';
import 'models/inventory_model.dart';
import 'database/database_helper.dart';

List<CameraDescription> cameras = [];

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  try {
    cameras = await availableCameras();
    print('Available cameras: ${cameras.length}');
  } catch (e) {
    print('Error initializing cameras: $e');
  }
  final dbHelper = DatabaseHelper.instance;
  final apiService = ApiService(dbHelper);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => InventoryModel(dbHelper, '123'),
        ),
        ChangeNotifierProvider(
          create: (context) => RecipeDetailModel(apiService),
        ),
      ],
      child: const SmartGroceryApp(),
    ),
  );
}

class SmartGroceryApp extends StatelessWidget {
  const SmartGroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grocery Assistant',
      theme: ThemeData(
        primaryColor: const Color(0xFFD32323),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32323),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryModel>(context);
    final recipes = inventory.recommendedRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Grocery Assistant',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddGroceryScreen(
                              cameras: cameras,
                              userId: '123',
                            ),
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'You have ${inventory.items.length} ingredients at home',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Recommended Recipes ${recipes.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            recipes.isEmpty
                ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Add more groceries to see recipe ideas!',
                      style: TextStyle(color: Color(0xFF333333)),
                    ),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recipes.length,
                  itemBuilder:
                      (context, index) => RecipePreview(
                        recipeId: recipes[index]['recipeId'] as String,
                        name: recipes[index]['name'] as String,
                        cookTime: recipes[index]['cookTime'] as int,
                        imageUrl: recipes[index]['imageUrl'] as String,
                        ingredientCount:
                            recipes[index]['ingredientCount'] as int,
                      ),
                ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddGroceryScreen(
                              cameras: cameras,
                              userId: '123',
                            ),
                      ),
                    ),
                child: const Text('Add Groceries'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipePreview extends StatelessWidget {
  final String recipeId;
  final String name;
  final int cookTime;
  final String imageUrl;
  final int ingredientCount;

  const RecipePreview({
    super.key,
    required this.recipeId,
    required this.name,
    required this.cookTime,
    required this.imageUrl,
    required this.ingredientCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Get the recipe ID from your preview data
        final recipeId =
            this.recipeId; // You'll need to add this to your recipe preview data

        // Navigate immediately to detail screen with loading state
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChangeNotifierProvider.value(
                  value: Provider.of<RecipeDetailModel>(context, listen: false),
                  child: RecipeDetailScreen(recipeId: recipeId),
                ),
          ),
        );

        // Then load the details
        await Provider.of<RecipeDetailModel>(
          context,
          listen: false,
        ).loadRecipeDetails(recipeId);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Recipe Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$cookTime mins',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // '${instructions.length} steps',
                      '$ingredientCount ingredients',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<RecipeDetailModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: _buildBody(context, model),
    );
  }

  Widget _buildBody(BuildContext context, RecipeDetailModel model) {
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (model.error != null) {
      return Center(child: Text('Error: ${model.error}'));
    }

    if (model.recipeDetails == null) {
      return const Center(child: Text('No recipe details available'));
    }

    final recipe = model.recipeDetails!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Image
          if (recipe['imageUrl']?.isNotEmpty ?? false)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(recipe['imageUrl']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Recipe Name
          Text(
            recipe['name'] ?? 'Unnamed Recipe', // Display the recipe name
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          // const SizedBox(height: 16),
          // // Cooking Time
          // Row(
          //   children: [
          //     const Icon(Icons.timer, color: Colors.grey),
          //     const SizedBox(width: 8),
          //     Text(
          //       'Ready in ${recipe['readyInMinutes']} minutes',
          //       style: const TextStyle(fontSize: 16, color: Colors.grey),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 24),
          // Ingredients
          if (recipe['recipeIngredients']?.isNotEmpty ?? false) ...[
            const Text(
              'Ingredients:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final ingredient in recipe['recipeIngredients'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '• ${ingredient['originalText']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // Instructions
          const Text(
            'Instructions:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (recipe['instructions']?.isNotEmpty ?? false) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < recipe['instructions'].length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recipe['instructions'][i],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else if (recipe['sourceUrl']?.isNotEmpty ?? false) ...[
            InkWell(
              onTap: () async {
                final url = recipe['sourceUrl'];
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    // Handle the case where the URL cannot be launched
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch URL')),
                    );
                  }
                }
              },
              child: Text(
                recipe['sourceUrl'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ] else ...[
            const Text(
              'No instructions or source URL available.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
