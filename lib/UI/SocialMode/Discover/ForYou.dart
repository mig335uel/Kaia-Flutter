import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
class Foryou extends StatefulWidget {
  const Foryou({super.key});

  @override
  State<Foryou> createState() => _ForyouState();
}

class _ForyouState extends State<Foryou> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: Column(
          children: [
            Text("foryou".tr()),
            
          ],
        ),

      ),
    );
  }
}