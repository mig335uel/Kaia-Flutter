import 'package:flutter/material.dart';

class Accountscreen extends StatefulWidget {
  const Accountscreen({super.key});

  @override
  State<Accountscreen> createState() => _AccountscreenState();
}

class _AccountscreenState extends State<Accountscreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Perfil",
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}