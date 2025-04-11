import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class InventoryModel with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _recommendedRecipes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  InventoryModel() {
    _loadInventory();
    _loadRecommendations();
  }

  List<String> get items =>
      _items.map((item) => item['name'] as String).toList();
  List<Map<String, dynamic>> get itemsWithIds => _items;
  List<Map<String, dynamic>> get recommendedRecipes => _recommendedRecipes;

  Future<void> _loadInventory() async {
    _items = await _dbHelper.getGroceries();
    await _loadRecommendations(); // Update recommendations after inventory changes
    notifyListeners();
  }

  Future<void> _loadRecommendations() async {
    _recommendedRecipes = await _dbHelper.getRecommendedRecipes();
    notifyListeners();
  }

  Future<void> addItem(String item) async {
    await _dbHelper.insertGrocery(item);
    await _loadInventory();
  }

  Future<void> removeItem(int index) async {
    final id = _items[index]['id'];
    if (id != null) {
      await _dbHelper.deleteGrocery(id as int);
      await _loadInventory();
    }
  }
}
