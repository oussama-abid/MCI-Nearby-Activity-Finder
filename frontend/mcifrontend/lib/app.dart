import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Remplace par tes vrais imports
import 'features/home/presentation/pages/map_page.dart';
import 'features/home/presentation/pages/FavoritesPage.dart';
import 'features/home/presentation/pages/settings_page.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  runApp(DayventureApp());
}

class DayventureApp extends StatefulWidget {
  const DayventureApp({super.key});

  @override
  State<DayventureApp> createState() => _DayventureAppState();
}

class _DayventureAppState extends State<DayventureApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('de');
  String _fontFamily = 'Roboto';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'de';
    final font = prefs.getString('font') ?? 'Roboto';
    final theme = prefs.getString('theme') ?? 'system';

    setState(() {
      _locale = Locale(langCode);
      _fontFamily = font;
      _themeMode = {
        'light': ThemeMode.light,
        'dark': ThemeMode.dark,
        'system': ThemeMode.system,
      }[theme]!;
    });
  }

  void _updateFont(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font', font);
    setState(() {
      _fontFamily = font;
    });
  }

  void _updateLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() {
      _locale = Locale(lang);
    });
  }

  void _toggleThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final newTheme = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    await prefs.setString(
        'theme', newTheme == ThemeMode.dark ? 'dark' : 'light');

    setState(() {
      _themeMode = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dayventure',
      theme: ThemeData(
        fontFamily: _fontFamily,
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.getTextTheme(_fontFamily),
      ),
      darkTheme: ThemeData(
        fontFamily: _fontFamily,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.getTextTheme(_fontFamily),
      ),
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      debugShowCheckedModeBanner: false,
      home: MainNavigation(
        onFontChanged: _updateFont,
        onLanguageChanged: _updateLanguage,
        onDarkModeChanged: (_) => _toggleThemeMode(),
      ),
    );

  }
}

class MainNavigation extends StatefulWidget {
  final void Function(String) onFontChanged;
  final void Function(String) onLanguageChanged;
  final void Function(bool) onDarkModeChanged;

  const MainNavigation({
    super.key,
    required this.onFontChanged,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MapPage(),
      FavoritesPage(),
      SettingsPage(
        onFontChanged: widget.onFontChanged,
        onLanguageChanged: widget.onLanguageChanged,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: loc.map),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: loc.favourites),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: loc.settings),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
