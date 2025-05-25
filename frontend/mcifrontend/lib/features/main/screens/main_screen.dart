import 'package:flutter/material.dart';
import 'package:mcifrontend/shared/widgets/bottom_nav_bar.dart';

// Import your real screen widgets
import 'package:mcifrontend/features/home/screens/home_screen.dart';
import 'package:mcifrontend/features/filter/screens/filter_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

 final List<Widget> _screens = [
  MyHomePage(),                  // index 0
  Center(child: Text('Coming soon')), // index 1 (Map)
  Center(child: Text('Coming soon')), // index 2 (List)
  FilterScreen(),                // index 3
  Center(child: Text('Coming soon')), // index 4 (Settings)
];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
