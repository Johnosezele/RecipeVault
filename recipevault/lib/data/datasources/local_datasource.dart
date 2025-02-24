import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Initialize SharedPreferences in main.dart before running the app',
  );
});

/// Keys for SharedPreferences storage
class PreferenceKeys {
  static const String favorites = 'favorites';
  static const String bookmarks = 'bookmarks';
  static const String recipeCache = 'recipe_cache';
  static const String recipeCacheTimestamp = 'recipe_cache_timestamp';
  
  // Private constructor to prevent instantiation
  PreferenceKeys._();
}

/// Manages local storage operations for favorites and bookmarks
class LocalDataSource {
  final SharedPreferences _prefs;
  // Cache duration of 1 hour
  static const cacheDuration = Duration(hours: 1);
  // Maximum cache size (in bytes)
  static const maxCacheSize = 5 * 1024 * 1024; // 5MB

  LocalDataSource(this._prefs);

  /// Checks if a recipe is marked as favorite
  Future<bool> isFavorite(String recipeId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(recipeId);
  }

  /// Checks if a recipe is bookmarked
  Future<bool> isBookmarked(String recipeId) async {
    final bookmarks = await getBookmarkIds();
    return bookmarks.contains(recipeId);
  }

  /// Adds a recipe to favorites
  Future<void> addFavorite(String recipeId) async {
    final favorites = await getFavoriteIds();
    if (!favorites.contains(recipeId)) {
      favorites.add(recipeId);
      await _saveFavorites(favorites);
    }
  }

  /// Removes a recipe from favorites
  Future<void> removeFavorite(String recipeId) async {
    final favorites = await getFavoriteIds();
    if (favorites.remove(recipeId)) {
      await _saveFavorites(favorites);
    }
  }

  /// Adds a recipe to bookmarks
  Future<void> addBookmark(String recipeId) async {
    final bookmarks = await getBookmarkIds();
    if (!bookmarks.contains(recipeId)) {
      bookmarks.add(recipeId);
      await _saveBookmarks(bookmarks);
    }
  }

  /// Removes a recipe from bookmarks
  Future<void> removeBookmark(String recipeId) async {
    final bookmarks = await getBookmarkIds();
    if (bookmarks.remove(recipeId)) {
      await _saveBookmarks(bookmarks);
    }
  }

  /// Gets all favorite recipe IDs
  Future<List<String>> getFavoriteIds() async {
    try {
      final favoritesJson = _prefs.getString(PreferenceKeys.favorites);
      if (favoritesJson == null) return [];

      final List<dynamic> decoded = json.decode(favoritesJson);
      return decoded.cast<String>();
    } catch (e) {
      // If there's an error reading preferences, return empty list
      return [];
    }
  }

  /// Gets all bookmarked recipe IDs
  Future<List<String>> getBookmarkIds() async {
    try {
      final bookmarksJson = _prefs.getString(PreferenceKeys.bookmarks);
      if (bookmarksJson == null) return [];

      final List<dynamic> decoded = json.decode(bookmarksJson);
      return decoded.cast<String>();
    } catch (e) {
      // If there's an error reading preferences, return empty list
      return [];
    }
  }

  /// Saves favorite recipes to SharedPreferences
  Future<void> _saveFavorites(List<String> favorites) async {
    final encodedList = json.encode(favorites);
    await _prefs.setString(PreferenceKeys.favorites, encodedList);
  }

  /// Saves bookmarked recipes to SharedPreferences
  Future<void> _saveBookmarks(List<String> bookmarks) async {
    final encodedList = json.encode(bookmarks);
    await _prefs.setString(PreferenceKeys.bookmarks, encodedList);
  }

  /// Caches a recipe by letter
  Future<void> cacheRecipesByLetter(String letter, List<Map<String, dynamic>> recipes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cacheKey = '${PreferenceKeys.recipeCache}_$letter';
    final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';

    await _prefs.setString(cacheKey, json.encode(recipes));
    await _prefs.setInt(timestampKey, timestamp);
  }

  /// Gets cached recipes by letter if not expired
  Future<List<Map<String, dynamic>>?> getCachedRecipesByLetter(String letter) async {
    final cacheKey = '${PreferenceKeys.recipeCache}_$letter';
    final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';

    final cachedData = _prefs.getString(cacheKey);
    final timestamp = _prefs.getInt(timestampKey);

    if (cachedData != null && timestamp != null) {
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age < cacheDuration.inMilliseconds) {
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return null;
  }

  /// Clears cache for a specific letter
  Future<void> clearLetterCache(String letter) async {
    final cacheKey = '${PreferenceKeys.recipeCache}_$letter';
    final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';

    await _prefs.remove(cacheKey);
    await _prefs.remove(timestampKey);
  }

  /// Clears all recipe cache
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(PreferenceKeys.recipeCache)) {
        await _prefs.remove(key);
      }
    }
  }

  /// Clears all local data (useful for testing or logout)
  Future<void> clear() async {
    await _prefs.remove(PreferenceKeys.favorites);
    await _prefs.remove(PreferenceKeys.bookmarks);
    await clearAllCache();
  }

  /// Gets the total size of cached data
  Future<int> getCacheSize() async {
    int totalSize = 0;
    final keys = _prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(PreferenceKeys.recipeCache)) {
        final data = _prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    }
    return totalSize;
  }

  /// Cleans expired cache entries
  Future<void> cleanExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keys = _prefs.getKeys().toList();
    
    for (final key in keys) {
      if (key.startsWith(PreferenceKeys.recipeCache)) {
        final letter = key.split('_').last;
        final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';
        final timestamp = _prefs.getInt(timestampKey);
        
        if (timestamp != null) {
          final age = now - timestamp;
          if (age >= cacheDuration.inMilliseconds) {
            await clearLetterCache(letter);
          }
        }
      }
    }
  }

  /// Cleans cache when size exceeds limit
  Future<void> cleanCacheIfNeeded() async {
    final size = await getCacheSize();
    if (size > maxCacheSize) {
      // Get all cache entries sorted by timestamp
      final entries = <MapEntry<String, int>>[];
      final keys = _prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(PreferenceKeys.recipeCache)) {
          final letter = key.split('_').last;
          final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';
          final timestamp = _prefs.getInt(timestampKey);
          if (timestamp != null) {
            entries.add(MapEntry(letter, timestamp));
          }
        }
      }
      
      // Sort by timestamp (oldest first)
      entries.sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest entries until under size limit
      for (final entry in entries) {
        await clearLetterCache(entry.key);
        final newSize = await getCacheSize();
        if (newSize <= maxCacheSize) break;
      }
    }
  }

  /// Performs all cleanup operations
  Future<void> maintainCache() async {
    await cleanExpiredCache();
    await cleanCacheIfNeeded();
  }
}