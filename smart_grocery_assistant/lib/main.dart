import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'screens/scan_receipt_screen.dart';
import 'screens/inventory_screen.dart';
import 'models/inventory_model.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
    print('Available cameras: ${cameras.length}');
  } catch (e) {
    print('Error initializing cameras: $e');
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => InventoryModel(),
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

  final List<Map<String, String>> recipes = const [
    {
      'name': 'Tomato Basil Pasta',
      'image': 'assets/images/tomato_basil_pasta.jpg',
    },
    {'name': 'Avocado Toast', 'image': 'assets/images/avocado_toast.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryModel>(context); // Access inventory
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryScreen(),
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
          SizedBox(
            height: 200,
            child:
                recipes.isEmpty
                    ? const Center(
                      child: Text(
                        'Add groceries to see recipe ideas!',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.length,
                      itemBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: RecipePreview(
                              name: recipes[index]['name']!,
                              imagePath: recipes[index]['image']!,
                            ),
                          ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TypeInputScreen(),
                        ),
                      ),
                  child: const Text('Type'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ScanReceiptScreen(cameras: cameras),
                        ),
                      ),
                  child: const Text('Scan'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoiceInputScreen(),
                        ),
                      ),
                  child: const Text('Voice'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder Screens
class RecipePreview extends StatelessWidget {
  final String name;
  final String imagePath;

  const RecipePreview({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(name: name),
            ),
          ),
      child: Card(
        elevation: 2,
        color: const Color(0xFFEDEDED),
        child: Column(
          children: [
            Image.asset(imagePath, width: 150, height: 120, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypeInputScreen extends StatelessWidget {
  const TypeInputScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add by Typing')),
    body: const Center(child: Text('Type Screen')),
  );
}

class VoiceInputScreen extends StatelessWidget {
  const VoiceInputScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Voice Input')),
    body: const Center(child: Text('Voice Screen')),
  );
}

class RecipeDetailScreen extends StatelessWidget {
  final String name;
  const RecipeDetailScreen({super.key, required this.name});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Center(child: Text('$name Details')),
  );
}
