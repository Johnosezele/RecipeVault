import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/errors/failure.dart';

/// Provider for Dio HTTP client
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'https://www.themealdb.com/api/json/v1/1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
});

/// Raw API response type
typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

/// Basic API service for HTTP operations
class APIService {
  final Dio _dio;

  APIService(this._dio);

  /// Performs a GET request and returns raw JSON
  Future<JsonMap> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response.data as JsonMap;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handles Dio specific errors and converts them to our domain errors
  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionFailure(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return const ConnectionFailure(message: 'No internet connection');
      default:
        if (error.response?.statusCode != null) {
          return ServerFailure(
            message: error.message ?? 'Server error',
            statusCode: error.response!.statusCode!,
          );
        }
        return const ServerFailure(
          message: 'Unknown error occurred',
          statusCode: 500,
        );
    }
  }
}