import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcifrontend/shared/widgets/bottom_nav_bar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with title and sun icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dayventure',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(
                    Icons.wb_sunny,
                    color: Color(0xFFFFE62E),
                    size: 49,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Temperature
            Text(
              '19°',
              style: GoogleFonts.montserrat(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF534E4E),
              ),
            ),

            const SizedBox(height: 10),

            // Weather description
            Text(
              'Sonnig',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                color: const Color(0xFFA29B9B),
              ),
            ),

            const SizedBox(height: 8),

            // City name
            Text(
              'Bremen, Deutschland',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 40),

            // Suggestion Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: add your action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0071BC), // Blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Vorschlag für deinen Ausflug',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
