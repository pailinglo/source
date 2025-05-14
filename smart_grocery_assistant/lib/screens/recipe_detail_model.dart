import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class RecipeDetailModel extends ChangeNotifier {
  final ApiService _apiService;
  Map<String, dynamic>? _recipeDetails;
  bool _isLoading = false;
  String? _error;

  RecipeDetailModel(this._apiService);

  Map<String, dynamic>? get recipeDetails => _recipeDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecipeDetails(String recipeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipeDetails = await _apiService.getRecipe(recipeId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _recipeDetails = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
