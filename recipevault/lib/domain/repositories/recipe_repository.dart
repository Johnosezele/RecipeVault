import 'package:fpdart/fpdart.dart';
import '../../core/errors/failure.dart';
import '../entities/recipe.dart';

/// Abstract contract for recipe operations.
/// Implementation will be provided by the data layer.
abstract class RecipeRepository {
  /// Fetches recipes by first letter.
  /// Returns [Either] with [Failure] or [List<Recipe>].
  Future<Either<Failure, List<Recipe>>> getRecipesByLetter(String letter);

  /// Toggles favorite status for a recipe.
  /// Returns [Either] with [Failure] or [Recipe].
  Future<Either<Failure, Recipe>> toggleFavorite(String recipeId);

  /// Toggles bookmark status for a recipe.
  /// Returns [Either] with [Failure] or [Recipe].
  Future<Either<Failure, Recipe>> toggleBookmark(String recipeId);

  /// Gets all favorite recipes.
  /// Returns [Either] with [Failure] or [List<Recipe>].
  Future<Either<Failure, List<Recipe>>> getFavorites();

  /// Gets all bookmarked recipes.
  /// Returns [Either] with [Failure] or [List<Recipe>].
  Future<Either<Failure, List<Recipe>>> getBookmarks();
}