import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'splash_screen.dart';
import 'get_started.dart';
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
      home: const SplashScreen(),
      routes: {
        '/getStarted': (context) => const GetStartedScreen(),
        '/login': (context) => const LogInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainNavigation(),
        '/customize-package': (context) =>
            const AuthGuard(child: CustomizePackagePage()),
      },
    );
  }
}

// ✅ AuthGuard — wraps any route that requires login.
// Uses authStateChanges STREAM so it never reads a stale null on app start.
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
        if (snapshot.hasData && snapshot.data != null) {
          return child;
        }
        return const LogInScreen();
      },
    );
  }
}
