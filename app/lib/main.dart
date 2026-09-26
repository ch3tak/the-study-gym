import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/welcome_screen.dart';

void main() {
  runApp(const ProviderScope(child: StudyGymApp()));
}

class StudyGymApp extends StatelessWidget {
  const StudyGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const WelcomeScreen(),
    );
  }
}
