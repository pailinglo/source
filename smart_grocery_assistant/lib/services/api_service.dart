import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class ApiService {
  static const String _baseUrl =
      'https://192.168.1.162:5001'; // HTTPS for security
  final DatabaseHelper _dbHelper;

  ApiService(this._dbHelper);

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncGroceries(String userId) async {
    if (!await isOnline()) return;

    final groceries = await _dbHelper.getGroceries(userId);
    final unsynced = groceries.where((g) => g['synced'] == 0).toList();
    
    // this does not handle deleted items.
    //if (unsynced.isEmpty) return;

    // instead of sending only unsynced items, we send all items to the server.
    final response = await http.post(
      Uri.parse('$_baseUrl/api/users/$userId/ingredients/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'items':
            groceries
                .map(
                  (g) => {'name': g['mapped_name'], 'originalName': g['name']},
                )
                .toList(),
      }),
    );

    if (response.statusCode == 200) {
      final syncedIds = unsynced.map((g) => g['id'] as int).toList();
      await _dbHelper.markAsSynced(syncedIds);
    } else {
      throw Exception('Failed to sync groceries: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations(String userId) async {
    if (!await isOnline()) {
      final groceries = await _dbHelper.getGroceries(userId);
      final cachedIngredients = await _dbHelper.getCachedIngredients();
      final mappedItems =
          groceries.map((g) {
            final ingredient = cachedIngredients.firstWhere(
              (i) =>
                  i['name'].toString().toLowerCase() ==
                  g['mapped_name'].toString().toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            return {'ingredientId': ingredient['ingredient_id']};
          }).toList();

      return [
        {
          'recipeId': 'offline-r1',
          'name': 'Offline Recipe',
          'ingredientCount': 5,
          'majorIngredientCount': 3,
          'matchCount': mappedItems.length,
          'matchPercent': mappedItems.length / 3.0,
        },
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/recipes/recommend/$userId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get recommendations: ${response.body}');
    }
  }

  Future<void> cacheIngredients() async {
    if (!await isOnline()) return;

    final response = await http.get(
      Uri.parse('$_baseUrl/api/ingredients'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final ingredients = List<Map<String, dynamic>>.from(
        jsonDecode(response.body),
      );
      await _dbHelper.cacheIngredients(ingredients);
    }
  }
}
