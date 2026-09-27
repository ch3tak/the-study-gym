import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'data/app_state.dart';
import 'data/content.dart';
import 'data/content_repository.dart';
import 'data/level_progress_repository.dart';
import 'data/mission_state.dart';
import 'data/student_repository.dart';
import 'features/onboarding/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    throw StateError(
      'Missing Supabase config. Run with --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=... (see .env.example).',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // No login screen yet (docs/PLAN.md's Google/email-OTP auth comes later).
  // An anonymous session gives every install a stable user_id so RLS-scoped
  // writes (attempts, mastery, streaks) work now; it upgrades to a real
  // account later via Supabase's linkIdentity flow without losing data.
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    await auth.signInAnonymously();
  }

  StudentNotifier.repositoryOverride = StudentRepository(Supabase.instance.client);
  LevelProgressNotifier.repositoryOverride = LevelProgressRepository(Supabase.instance.client);
  StudyGymApp.contentLoader = () => ContentRepository(Supabase.instance.client).fetchAll();

  runApp(const ProviderScope(child: StudyGymApp()));
}

class StudyGymApp extends StatelessWidget {
  const StudyGymApp({super.key});

  /// How `_StartupGate` fetches content. Set by `main()` to the real
  /// Supabase call; tests override this to an instant fake so widget tests
  /// don't need `Supabase.initialize()` or network access (see
  /// test/test_content.dart).
  static Future<ContentSnapshot> Function() contentLoader =
      () => throw StateError('StudyGymApp.contentLoader was not set before running the app.');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _StartupGate(),
    );
  }
}

/// Fetches curriculum content once, then shows the real app. `Content.*` is
/// read synchronously everywhere else, so nothing downstream may render
/// before `Content.load()` has run — see `data/content.dart`.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<void> _ready = _loadContent();

  Future<void> _loadContent() async {
    final snapshot = await StudyGymApp.contentLoader();
    Content.load(snapshot);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(error: snapshot.error!, onRetry: () {
            setState(() => _ready = _loadContent());
          });
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const WelcomeScreen();
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: AppTheme.space16),
              const Text('Could not load content. Check your connection and try again.'),
              const SizedBox(height: AppTheme.space8),
              Text('$error', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppTheme.space16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
