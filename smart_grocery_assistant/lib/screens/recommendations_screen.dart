import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';

class RecommendationsScreen extends StatefulWidget {
  final String userId;

  const RecommendationsScreen({super.key, required this.userId});

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(DatabaseHelper.instance);
    _loadRecommendations();
  }

  void _loadRecommendations() async {
    setState(() => _isLoading = true);
    try {
      _recommendations = await _apiService.getRecommendations(widget.userId);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recommendations: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Recommendations',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recommendations.isEmpty
              ? const Center(
                child: Text(
                  'No recommendations available',
                  style: TextStyle(color: Color(0xFF333333)),
                ),
              )
              : ListView.builder(
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final recipe = _recommendations[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    color: const Color(0xFFEDEDED),
                    child: ListTile(
                      title: Text(
                        recipe['name'],
                        style: const TextStyle(color: Color(0xFF333333)),
                      ),
                      subtitle: Text(
                        'Match: ${(recipe['matchPercent'] * 100).toStringAsFixed(1)}% '
                        '(${recipe['matchCount']}/${recipe['majorIngredientCount']} ingredients)',
                        style: const TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
