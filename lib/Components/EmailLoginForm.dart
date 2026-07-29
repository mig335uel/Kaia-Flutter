import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EmailLoginForm extends StatelessWidget {
  final VoidCallback onBack;

  const EmailLoginForm({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón de atrás
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white70 : Colors.black87),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Campo de Email
        TextField(
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'email'.tr(),
            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        const SizedBox(height: 15),
        
        // Campo de Contraseña
        TextField(
          obscureText: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'password'.tr(),
            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        const SizedBox(height: 25),
        
        // Botón Entrar
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A5BFC), Color(0xFF7575FF), Color(0xFF3FCECC)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: CupertinoButton(
            onPressed: () {
              // Aquí irá la lógica de Supabase Auth
            },
            child: Text(
              'enter'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
