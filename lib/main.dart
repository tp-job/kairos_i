import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mesh_background.dart';
import 'features/dashboard/dashboard_screen.dart';

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

class KairosApp extends StatelessWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Every screen's Scaffold has a transparent background (see
      // AppTheme), so wrapping the whole app once here is enough for
      // the mesh gradient to show through everywhere.
      builder: (context, child) => MeshBackground(child: child!),
      home: const DashboardScreen(),
    );
  }
}
