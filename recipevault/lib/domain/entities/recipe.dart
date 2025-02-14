import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
    final String id;
    final String name;
    final String? instructions;
    final String? thumbnailUrl;
    final List<Ingredient> ingredients;

    Recipe({
        required this.id,
        required this.name;
        this.instructions,
        this.thumbnailUrl,
        required this.ingredients,
    });
}

class Ingredient {
    final String name;
    final String? measure;

    Ingredient({
        required this.name,
        this.measure,
    });
}