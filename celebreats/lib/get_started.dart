import 'package:flutter/material.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Logo
              Image.asset(
                'assets/logo.png',
                width: 400,
                height: 400,
                fit: BoxFit.contain,
              ),
              SizedBox(height: height * 0.00),

              // App title
              Text(
                "Catering\nService",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: width * 0.13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7B241C),
                  height: 1.1,
                ),
              ),

              const Spacer(flex: 25),

              // Get Started Button - FIXED CLICKABLE AREA
              Padding(
                padding: EdgeInsets.only(bottom: height * 0.05),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      print("Get Started button pressed!");
                      Navigator.pushNamed(context, '/login');
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      width: width * 0.5,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFA4A2A), Color(0xFFFFA726)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.047,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
