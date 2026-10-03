import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/core/splash_screen.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/core/app_theme.dart';
import 'package:docsmind/constants/app_constants.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    // If explicit themeMode was chosen, respect it; otherwise fall back to darkMode toggle
    final effectiveThemeMode = themeMode != ThemeMode.system
        ? themeMode
        : (isDarkMode ? ThemeMode.dark : ThemeMode.system);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: effectiveThemeMode,
      home: const SplashScreen(),
    );
  }
}
