import 'package:flutter/material.dart';
import 'package:kaia/Components/LoginForm.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignTopLeft;
  late Animation<Alignment> _alignBottomRight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _alignTopLeft = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(-1.5, -1.0), // Moves towards top-left
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _alignBottomRight = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(1.5, 1.0), // Moves towards bottom-right
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start the animation as soon as the screen loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Fondo adaptable a Dark Mode
      body: Stack(
        children: [
          // Círculo 1 (Top Left - Morado claro)
          AnimatedBuilder(
            animation: _alignTopLeft,
            builder: (context, child) {
              return Align(
                alignment: _alignTopLeft.value,
                child: child,
              );
            },
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8E2DE2).withOpacity(0.5),
                    const Color(0xFF8E2DE2).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Círculo 2 (Bottom Right - Azul oscuro)
          AnimatedBuilder(
            animation: _alignBottomRight,
            builder: (context, child) {
              return Align(
                alignment: _alignBottomRight.value,
                child: child,
              );
            },
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A00E0).withOpacity(0.5),
                    const Color(0xFF4A00E0).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Contenido Principal (Texto y Formulario)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/kaia.png', height: 150),
                    Text(
                      'welcome'.tr(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const LoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
