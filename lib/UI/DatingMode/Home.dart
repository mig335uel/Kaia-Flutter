import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kaia/UI/DatingMode/ChatScreen.dart';
import 'package:kaia/UI/DatingMode/HomeScreen.dart';

class DatingHome extends StatefulWidget {
  const DatingHome({super.key});

  @override
  State<DatingHome> createState() => _DatingHomeState();
}

class _DatingHomeState extends State<DatingHome> {
  int _currentIndex = 0;
  List<Widget> _screens = [
    HomeScreen(),
    Chatscreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),


      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.paperPlane),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}