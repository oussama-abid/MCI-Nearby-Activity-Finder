import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: const Color(0xFF534E4E),
      unselectedItemColor: const Color(0xFFA29B9B),
      selectedLabelStyle: GoogleFonts.montserrat(),
      unselectedLabelStyle: GoogleFonts.montserrat(),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Karte',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Liste',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_alt),
          label: 'Filter',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Einstellungen',
        ),
      ],
    );
  }
}
