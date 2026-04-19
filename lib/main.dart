import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'splash_screen.dart';
import 'log_in.dart';
import 'sign_up.dart';
import 'bottom_navigation.dart';
import 'favorites_manager.dart';
import 'customize_package.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => FavoritesManager(),
      child: const CateringApp(),
    ),
  );
}

class CateringApp extends StatelessWidget {
  const CateringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CelebrEats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: const AppRoot(),
      routes: {
        '/login': (context) => const LogInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainNavigation(),
        '/customize-package': (context) =>
            const AuthGuard(child: CustomizePackagePage()),
      },
    );
  }
}

// ── AppRoot ──────────────────────────────────────────────────────────────────
// Now flows directly: Splash (6s) -> MainNavigation (Home)
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Keep the splash for 6 seconds as requested
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show Splash Screen first
    if (_showSplash) return const SplashScreen();

    // 2. After splash, go directly to Home (MainNavigation)
    // If you want the home page to be accessible to guests, we return it here.
    return const MainNavigation();
  }
}

// ── AuthGuard ────────────────────────────────────────────────────────────────
// Use this for specific screens that MUST have a login (like Checkout or Profile)
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If logged in, show the protected page
        if (snapshot.hasData && snapshot.data != null) {
          return child;
        }
        // Otherwise, redirect to Login
        return const LogInScreen();
      },
    );
  }
}
