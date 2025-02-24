import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/local_datasource.dart';
import 'presentation/views/home.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RecipeVaultApp(),
    ),
  );
}

class RecipeVaultApp extends StatelessWidget {
  const RecipeVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Vault',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respect system theme
      home: const HomePage(),
    );
  }
}
