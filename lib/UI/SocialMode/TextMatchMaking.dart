import 'package:flutter/material.dart';
import 'package:kaia/Controllers/TextMatchMakingController.dart';
import 'dart:math' as math;

class Textmatchmaking extends StatefulWidget {
  const Textmatchmaking({super.key});

  @override
  State<Textmatchmaking> createState() => _TextmatchmakingState();
}

class _TextmatchmakingState extends State<Textmatchmaking> with SingleTickerProviderStateMixin {
  final TextMatchmakingcontroller mmc = TextMatchmakingcontroller();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Animación de pulso continuo (latido/radar)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    
    // Iniciar la búsqueda real nada más cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mmc.iniciarBusqueda(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Asegúrate de cancelar la búsqueda en tu backend si el usuario sale de la pantalla
    mmc.cancelarBusqueda();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo oscuro premium para que los colores resalten
      backgroundColor: const Color(0xFF0F172A), 
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // CENTRO ANIMADO (El Orbe de conexión)
            Center(
              child: CustomPaint(
                painter: PulsePainter(_animationController),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Gradiente moderno tipo cristal
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD946EF).withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 70),
            
            // TEXTO ANIMADO Y ESTILIZADO
            const Text(
              "Buscando conexión...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "El destino está haciendo su magia ✧",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
            
            const Spacer(),
            
            // BOTÓN DE CANCELAR (Diseño limpio y moderno)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  // Cancelar en backend
                  mmc.cancelarBusqueda();
                  // Volver atrás
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2), 
                      width: 1.5
                    ),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "Cancelar búsqueda",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PINTOR PERSONALIZADO PARA EL EFECTO PULSO
// ==========================================
class PulsePainter extends CustomPainter {
  final Animation<double> animation;

  PulsePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Dibujamos 3 anillos que se expanden
    for (int i = 0; i < 3; i++) {
      // Creamos un desfase para que los anillos salgan uno tras otro
      double progress = (animation.value - (i * 0.33)) % 1.0;
      if (progress < 0) progress += 1.0; // Evita valores negativos
      
      // El radio crece a medida que avanza la animación (de 65 a 180)
      final radius = 65.0 + (130.0 * progress);
      // La opacidad disminuye a medida que el círculo se hace más grande
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      
      // Borde del anillo
      final paintStroke = Paint()
        ..color = const Color(0xFFD946EF).withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paintStroke);
      
      // Relleno súper suave para dar un efecto de "onda de energía"
      final paintFill = Paint()
        ..color = const Color(0xFF6366F1).withOpacity(opacity * 0.15)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(center, radius, paintFill);
    }
  }

  @override
  bool shouldRepaint(covariant PulsePainter oldDelegate) => true;
}