import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/recipe.dart';

part 'recipe_model.freezed.dart';
part 'recipe_model.g.dart';

@freezed
@JsonSerializable()
class RecipeModel with _$RecipeModel {
  const RecipeModel._(); // Added for custom methods

  const factory RecipeModel({
    @JsonKey(name: 'idMeal') required String id,
    @JsonKey(name: 'strMeal') required String name,
    @JsonKey(name: 'strInstructions') String? instructions,
    @JsonKey(name: 'strMealThumb') String? thumbnailUrl,
    @Default([]) List<IngredientModel> ingredients,
    @Default(false) bool isFavorite,
    @Default(false) bool isBookmarked,
  }) = _RecipeModel;

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // Extract ingredients from the flat structure
    final ingredients = <Map<String, dynamic>>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      
      if (ingredient != null && 
          ingredient.toString().trim().isNotEmpty &&
          measure != null &&
          measure.toString().trim().isNotEmpty) {
        ingredients.add({
          'name': ingredient.toString().trim(),
          'measure': measure.toString().trim(),
        });
      }
    }

    // Create a new JSON map with our desired structure
    final transformedJson = {
      'id': json['idMeal'],
      'name': json['strMeal'],
      'instructions': json['strInstructions'],
      'thumbnailUrl': json['strMealThumb'],
      'ingredients': ingredients,
      'isFavorite': false,
      'isBookmarked': false,
    };

    return _$RecipeModelFromJson(transformedJson);
  }

  Map<String, dynamic> toJson() => _$RecipeModelToJson(this);

  /// Converts this model to a domain entity
  Recipe toDomain() => Recipe(
        id: id,
        name: name,
        instructions: instructions,
        thumbnailUrl: thumbnailUrl,
        ingredients: ingredients
            .map((ingredient) => ingredient.toDomain())
            .toList(),
        isFavorite: isFavorite,
        isBookmarked: isBookmarked,
      );
}

@freezed
@JsonSerializable()
class IngredientModel with _$IngredientModel {
  const IngredientModel._(); // Added for custom methods

  const factory IngredientModel({
    required String name,
    String? measure,
  }) = _IngredientModel;

  factory IngredientModel.fromJson(Map<String, dynamic> json) =>
      _$IngredientModelFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientModelToJson(this);

  /// Converts this model to a domain entity
  Ingredient toDomain() => Ingredient(
        name: name,
        measure: measure,
      );
}