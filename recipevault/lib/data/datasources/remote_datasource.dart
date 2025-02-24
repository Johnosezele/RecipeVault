import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../services/api_service.dart';
import '../models/recipe_model.dart';

/// Provider for RemoteDataSource
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  final apiService = ref.watch(dioProvider);
  return RemoteDataSource(APIService(apiService));
});

/// Handles remote data operations and transformations
class RemoteDataSource {
  final APIService _apiService;
  
  RemoteDataSource(this._apiService);

  /// Fetches recipes by first letter and transforms them into models
  Future<List<RecipeModel>> getRecipesByLetter(String letter) async {
    try {
      final response = await _apiService.get(
        '/search.php',
        queryParams: {'f': letter},
      );

      final meals = response['meals'] as List<dynamic>?;
      if (meals == null) {
        return [];
      }

      return meals
          .cast<Map<String, dynamic>>()
          .map((json) => RecipeModel.fromJson(json))
          .toList();
    } on ServerFailure catch (e) {
      throw e;
    } on ConnectionFailure catch (e) {
      throw e;
    } catch (e) {
      throw const ServerFailure(
        message: 'Failed to parse recipe data',
        statusCode: 500,
      );
    }
  }

  /// Fetches a single recipe by ID
  Future<RecipeModel?> getRecipeById(String id) async {
    try {
      final response = await _apiService.get(
        '/lookup.php',
        queryParams: {'i': id},
      );

      final meals = response['meals'] as List<dynamic>?;
      if (meals == null || meals.isEmpty) {
        return null;
      }

      return RecipeModel.fromJson(meals.first as Map<String, dynamic>);
    } on ServerFailure catch (e) {
      throw e;
    } on ConnectionFailure catch (e) {
      throw e;
    } catch (e) {
      throw const ServerFailure(
        message: 'Failed to parse recipe data',
        statusCode: 500,
      );
    }
  }
}