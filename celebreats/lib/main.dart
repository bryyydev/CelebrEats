import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'get_started.dart';
import 'log_in.dart';
import 'sign_up.dart';

void main() {
  runApp(const CateringApp());
}

class CateringApp extends StatelessWidget {
  const CateringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catering Service',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/getStarted': (context) => const GetStartedScreen(),
        '/login': (context) => const LogInScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
