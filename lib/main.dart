import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'game/game_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

// FIREBASE: Uncomment after running `flutterfire configure`:
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // FIREBASE: Initialise Firebase before runApp:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameController()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
      ],
      child: const WarApp(),
    ),
  );
}

class WarApp extends StatelessWidget {
  const WarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        useMaterial3: true,
      ),
      // Route based on auth state; Consumer rebuilds when AuthService notifies.
      home: Consumer<AuthService>(
        builder: (_, auth, __) {
          return auth.isLoggedIn ? const MainShell() : const AuthScreen();
        },
      ),
    );
  }
}
