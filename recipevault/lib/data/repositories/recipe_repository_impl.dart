import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/data/models/recipe_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failure.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../services/api_service.dart';
import '../datasources/local_datasource.dart';

/// Provider for RecipeRepository implementation
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  return RecipeRepositoryImpl(
    apiService: apiService,
    localDataSource: LocalDataSource(prefs),
  );
});

/// Implementation of [RecipeRepository] that coordinates between
/// remote data ([APIService]) and local data ([LocalDataSource])
class RecipeRepositoryImpl implements RecipeRepository {
  final APIService apiService;
  final LocalDataSource localDataSource;

  RecipeRepositoryImpl({
    required this.apiService,
    required this.localDataSource,
  });

  /// Performs cache maintenance operations
  Future<void> _maintainCache() async {
    try {
      await localDataSource.maintainCache();
    } catch (e) {
      // Log error but don't throw - cache maintenance is non-critical
      print('Cache maintenance failed: $e');
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getRecipesByLetter(String letter) async {
    try {
      // Trigger cache maintenance (non-blocking)
      _maintainCache();

      // Check cache first
      final cachedData = await localDataSource.getCachedRecipesByLetter(letter);
      final List<RecipeModel> recipes;

      if (cachedData != null) {
        // Use cached data
        recipes = cachedData
            .map((json) => RecipeModel.fromJson(json))
            .toList();
      } else {
        // Fetch from API and cache
        recipes = await apiService.getRecipesByLetter(letter);
        await localDataSource.cacheRecipesByLetter(
          letter,
          recipes.map((r) => r.toJson()).toList(),
        );
      }
      
      // Convert models to entities and merge with local state
      final recipesWithState = await Future.wait(
        recipes.map((model) async {
          final isFavorite = await localDataSource.isFavorite(model.id);
          final isBookmarked = await localDataSource.isBookmarked(model.id);
          
          return model.toDomain().copyWith(
            isFavorite: isFavorite,
            isBookmarked: isBookmarked,
          );
        }),
      );

      return Right(recipesWithState);
    } on ServerFailure catch (e) {
      return Left(e);
    } on ConnectionFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Unexpected error occurred',
          statusCode: 500,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Recipe>> toggleFavorite(String recipeId) async {
    try {
      final isFavorite = await localDataSource.isFavorite(recipeId);
      
      if (isFavorite) {
        await localDataSource.removeFavorite(recipeId);
      } else {
        await localDataSource.addFavorite(recipeId);
      }

      // Get the full recipe data and update its state
      final result = await _getRecipeWithState(recipeId);
      return result;
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Failed to toggle favorite status',
          operation: 'toggleFavorite',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Recipe>> toggleBookmark(String recipeId) async {
    try {
      final isBookmarked = await localDataSource.isBookmarked(recipeId);
      
      if (isBookmarked) {
        await localDataSource.removeBookmark(recipeId);
      } else {
        await localDataSource.addBookmark(recipeId);
      }

      // Get the full recipe data and update its state
      final result = await _getRecipeWithState(recipeId);
      return result;
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Failed to toggle bookmark status',
          operation: 'toggleBookmark',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getFavorites() async {
    try {
      final favoriteIds = await localDataSource.getFavoriteIds();
      final recipes = await _getRecipesWithState(favoriteIds);
      return Right(recipes);
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Failed to get favorite recipes',
          operation: 'getFavorites',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getBookmarks() async {
    try {
      final bookmarkIds = await localDataSource.getBookmarkIds();
      final recipes = await _getRecipesWithState(bookmarkIds);
      return Right(recipes);
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Failed to get bookmarked recipes',
          operation: 'getBookmarks',
        ),
      );
    }
  }

  /// Helper method to get a recipe with its current state
  Future<Either<Failure, Recipe>> _getRecipeWithState(String recipeId) async {
    try {
      // In a real app, you might want to cache this data
      final recipes = await apiService.getRecipesByLetter(recipeId[0]);
      final recipe = recipes.firstWhere((r) => r.id == recipeId);
      
      final isFavorite = await localDataSource.isFavorite(recipeId);
      final isBookmarked = await localDataSource.isBookmarked(recipeId);
      
      return Right(
        recipe.toDomain().copyWith(
          isFavorite: isFavorite,
          isBookmarked: isBookmarked,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to get recipe details',
          statusCode: 500,
        ),
      );
    }
  }

  /// Helper method to get multiple recipes with their states
  Future<List<Recipe>> _getRecipesWithState(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Group IDs by first letter to minimize API calls
    final recipesByLetter = <String, List<String>>{};
    for (final id in ids) {
      final letter = id[0];
      recipesByLetter.putIfAbsent(letter, () => []).add(id);
    }

    final allRecipes = <Recipe>[];
    for (final letter in recipesByLetter.keys) {
      final recipes = await apiService.getRecipesByLetter(letter);
      final targetIds = recipesByLetter[letter]!;
      
      final matchingRecipes = recipes.where((r) => targetIds.contains(r.id));
      for (final recipe in matchingRecipes) {
        final isFavorite = await localDataSource.isFavorite(recipe.id);
        final isBookmarked = await localDataSource.isBookmarked(recipe.id);
        
        allRecipes.add(
          recipe.toDomain().copyWith(
            isFavorite: isFavorite,
            isBookmarked: isBookmarked,
          ),
        );
      }
    }

    return allRecipes;
  }
}