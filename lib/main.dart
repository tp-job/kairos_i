import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/motion/motion.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';

import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads .env into dotenv.env before any provider tries to read a key.
  await dotenv.load(fileName: '.env');

  runApp(
    // ProviderScope is the Riverpod equivalent of wrapping your React
    // tree in <QueryClientProvider>/<Provider store={store}> — every
    // provider used below lives inside this one root.
    const ProviderScope(child: KairosApp()),
  );
}

class KairosApp extends ConsumerWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds when the user changes mode or contrast.
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      // Both schemes are handed over at once so ThemeMode.system can follow
      // the OS live, and so a mode switch animates instead of rebuilding the
      // app with a different `theme`.
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.mode,
      home: const _Bootstrap(),
    );
  }
}

/// Root gate: shows the [SplashScreen] first, then cross-fades to the app
/// shell.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.slow,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.standard,
      child: _ready
          ? const MainShell()
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () => setState(() => _ready = true),
            ),
    );
  }
}
