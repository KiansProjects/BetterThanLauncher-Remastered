import 'dart:io';
import 'package:flutter/material.dart';
import 'themes/theme_manager.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(BetterThanLauncher());
}

class BetterThanLauncher extends StatelessWidget {
  const BetterThanLauncher({super.key});

  Future<String> getJavaVersion() async {
    try {
      // Runs 'java -version' command
      ProcessResult result = await Process.run('java', ['-version']);
      // java -version outputs to stderr, not stdout
      return result.stderr.toString().split('\n')[0];
    } catch (e) {
      return 'Java not found or an error occurred: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'Flutter App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: theme.background,
            primaryColor: theme.components4,
            cardColor: theme.components,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: theme.text),
              bodyMedium: TextStyle(color: theme.text2),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }  
}
