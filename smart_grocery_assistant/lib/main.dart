import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/scan_receipt.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  // Ensure that plugin services are initialized so that the camera is available
  // to use.
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  //  runApp(MyApp());
  runApp(const SmartGroceryApp());
}

//home: ScanReceiptScreen(), // Use the ScanReceiptScreen as the home screen

class SmartGroceryApp extends StatelessWidget {
  const SmartGroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grocery Assistant',
      theme: ThemeData(
        primaryColor: const Color(0xFFD32323), // Yelp-like red
        scaffoldBackgroundColor: const Color(0xFFF8F8F8), // Off-white
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32323), // Red buttons
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                8,
              ), // Slightly rounded buttons
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

  // Example recipes with placeholder image URLs
  final List<Map<String, String>> recipes = const [
    {
      'name': 'Tomato Basil Pasta',
      'image': 'assets/images/tomato_basil_pasta.jpg', // Local asset image
    },
    {
      'name': 'Avocado Toast',
      'image': 'assets/images/avocado_toast.jpeg', // Local asset image
    },
    {
      'name': 'Chicken Stir Fry',
      'image': 'assets/images/chicken_stirfry.jpeg', // Local asset image
    },
  ];

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Theme.of(context).primaryColor, // Red app bar
        centerTitle: true,
        elevation: 4, // Slight shadow for depth
      ),
      body: Column(
        children: [
          // Center Section: Recommended Recipes
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  return RecipeCard(
                    name: recipes[index]['name']!,
                    imagePath: recipes[index]['image']!,
                  );
                },
              ),
            ),
          ),
          // Bottom Section: Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('Voice button pressed');
                  },
                  child: const Text('Voice', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('Scan button pressed');
                  },
                  child: const Text('Scan'),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('Type button pressed');
                  },
                  child: const Text('Type'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Recipe Card Widget
class RecipeCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const RecipeCard({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // Lighter shadow for a modern look
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: const Color(0xFFEDEDED), // Light gray card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(imagePath, height: 150, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333), // Dark gray text
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
