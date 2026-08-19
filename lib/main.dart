import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/navigation/app_router.dart';
import 'core/storage/prefs.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads .env into dotenv.env before any provider tries to read a key.
  await dotenv.load(fileName: '.env');

  // Resolved before the first frame so the task, note and theme stores can
  // read it synchronously in their constructors. Doing it here is what lets
  // the app open already showing the user's saved theme rather than
  // flashing the default and correcting itself a frame later.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // ProviderScope is the Riverpod equivalent of wrapping your React
    // tree in <QueryClientProvider>/<Provider store={store}> — every
    // provider used below lives inside this one root.
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const KairosApp(),
    ),
  );
}

class KairosApp extends ConsumerWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds when the user changes mode or contrast.
    final theme = ref.watch(themeProvider);
    // Read, not watched: the router owns every branch's navigation stack and
    // must outlive a theme change.
    final router = ref.read(routerProvider);

    return MaterialApp.router(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      // Both schemes are handed over at once so ThemeMode.system can follow
      // the OS live, and so a mode switch animates instead of rebuilding the
      // app with a different `theme`.
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.mode,
      // The route table — and the splash → shell handoff — now live in
      // core/navigation/app_router.dart (FR-8.6).
      routerConfig: router,
    );
  }
}
