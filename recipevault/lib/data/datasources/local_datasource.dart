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
  
  // Private constructor to prevent instantiation
  PreferenceKeys._();
}

/// Manages local storage operations for favorites and bookmarks
class LocalDataSource {
  final SharedPreferences _prefs;

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

  /// Clears all local data (useful for testing or logout)
  Future<void> clear() async {
    await _prefs.remove(PreferenceKeys.favorites);
    await _prefs.remove(PreferenceKeys.bookmarks);
  }
}