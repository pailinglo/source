import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

class InventoryModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final String _userId;
  final ApiService _apiService;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _recommendedRecipes = [];

  InventoryModel(this._dbHelper, this._userId)
    : _apiService = ApiService(_dbHelper) {
    loadItems();
    loadRecommendations();
  }

  List<Map<String, dynamic>> get items => _items;
  List<Map<String, dynamic>> get recommendedRecipes => _recommendedRecipes;

  Future<void> loadItems() async {
    _items = await _dbHelper.getGroceries(_userId);
    notifyListeners();
  }

  Future<void> addItem(String name) async {
    final mappedName =
        await _dbHelper.getMappedName(name.toLowerCase()) ?? name.toLowerCase();
    await _dbHelper.insertGrocery(_userId, name, mappedName);
    await loadItems();
    await _apiService.syncGroceries(_userId);
    await loadRecommendations();
  }

  Future<void> removeItem(int id) async {
    await _dbHelper.deleteGrocery(id);
    await loadItems();
    await _apiService.syncGroceries(_userId);
    await loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    try {
      _recommendedRecipes = await _apiService.getRecommendations(_userId);
      // Map backend format to match HomeScreen expectations
      _recommendedRecipes =
          _recommendedRecipes
              .map(
                (r) => {
                  'name': r['name'],
                  'instructions':
                      r['instructions'] ?? 'No instructions available',
                },
              )
              .toList();
      notifyListeners();
    } catch (e) {
      print('Failed to load recommendations: $e');
      _recommendedRecipes = [];
      notifyListeners();
    }
  }
}
