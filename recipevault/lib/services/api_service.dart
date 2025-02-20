import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/failure.dart';
import '../data/models/recipe_model.dart';

/// Provider for APIService
final apiServiceProvider = Provider<APIService>((ref) {
  return APIService(
    dio: Dio()
      ..options = BaseOptions(
        baseUrl: 'https://www.themealdb.com/api/json/v1/1',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
  );
});

/// Service class for handling API requests
class APIService {
  final Dio dio;

  APIService({required this.dio});

  /// Fetches recipes by first letter
  /// Returns a [List<RecipeModel>] if successful
  /// Throws [ServerFailure] if API request fails
  /// Throws [ConnectionFailure] if no internet connection
  /// Throws [ParseFailure] if response parsing fails
  Future<List<RecipeModel>> getRecipesByLetter(String letter) async {
    try {
      final response = await dio.get(
        '/search.php',
        queryParameters: {'f': letter},
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to fetch recipes',
          statusCode: response.statusCode ?? 500,
        );
      }

      final data = response.data;
      if (data == null || data['meals'] == null) {
        return []; // Return empty list if no meals found
      }

      return (data['meals'] as List)
          .map((meal) => RecipeModel.fromJson(meal))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ConnectionFailure(
          message: 'Connection timeout. Please check your internet connection.',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw const ConnectionFailure(
          message: 'No internet connection.',
        );
      }

      throw ServerFailure(
        message: e.message ?? 'Server error occurred',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      if (e is ServerFailure || e is ConnectionFailure) {
        rethrow;
      }
      throw ParseFailure(
        message: 'Failed to parse recipe data',
        key: 'meals',
        expectedType: RecipeModel,
      );
    }
  }

  /// Disposes the Dio client
  void dispose() {
    dio.close(force: true);
  }
}