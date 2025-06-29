import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../l10n/generated/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final void Function(String) onFontChanged;
  final void Function(String) onLanguageChanged;
  final void Function(bool) onDarkModeChanged;

  const SettingsPage({
    super.key,
    required this.onFontChanged,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _nameController;
  final FocusNode _focusNodeName = FocusNode();
  bool _prefsReady = false;

  bool _isDarkMode = false;
  String _language = 'de';
  String _font = 'Roboto';

  Map<String, dynamic> favoritePlaces = {};
  Map<String, dynamic> blacklistPlaces = {};

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    setState(() {
      _isDarkMode = _prefs.getBool('darkMode') ?? false;
      _nameController.text = _prefs.getString('userName') ?? '';
      _language = _prefs.getString('language') ?? 'de';
      _font = _prefs.getString('font') ?? 'Roboto';

      try {
        favoritePlaces = jsonDecode(_prefs.getString('favorites') ?? '{}');
      } catch (_) {
        favoritePlaces = {};
      }

      try {
        blacklistPlaces = jsonDecode(_prefs.getString('blacklist') ?? '{}');
      } catch (_) {
        blacklistPlaces = {};
      }

      _prefsReady = true; // ✅ ici !
    });

    _focusNodeName.addListener(() {
      if (!_focusNodeName.hasFocus) {
        _saveName();
      }
    });
  }


  Future<void> _saveName() async {
    await _prefs.setString('userName', _nameController.text);
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await _prefs.setBool('darkMode', value);
    widget.onDarkModeChanged(value);
  }

  Future<void> _removeFavorite(String placeId) async {
    setState(() {
      favoritePlaces.remove(placeId);
    });
    await _prefs.setString('favorites', jsonEncode(favoritePlaces));
  }

  Future<void> _removeBlacklist(String placeId) async {
    setState(() {
      blacklistPlaces.remove(placeId);
    });
    await _prefs.setString('blacklist', jsonEncode(blacklistPlaces));
  }

  Future<void> _resetPreferences() async {
    await _prefs.clear();

    setState(() {
      _nameController.text = '';
      _isDarkMode = false;
      _language = 'de';
      _font = 'Roboto';
      favoritePlaces = {};
      blacklistPlaces = {};
    });

    widget.onDarkModeChanged(false);
    widget.onLanguageChanged('de');
    widget.onFontChanged('Roboto');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)?.settings_reset_done ?? 'Preferences reset')),
    );
  }

  void _goToDetail(String placeId, Map<String, dynamic> data) {
    Navigator.pushNamed(context, '/detail', arguments: {
      'placeId': placeId,
      'data': data,
    });
  }

  @override
  void dispose() {
    _focusNodeName.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('⚠️ Localization not available')),
      );
    }

    final supportedFonts = ['Roboto', 'Lato', 'Oswald'];

    if (!supportedFonts.contains(_font)) {
      _font = 'Roboto';
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(loc.settings_switch_mode),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          ListTile(
            title: Text(loc.settings_text_name),
            trailing: SizedBox(
              width: 150,
              child: TextField(
                controller: _nameController,
                focusNode: _focusNodeName,
                decoration: InputDecoration(
                  hintText: loc.settings_text_name_hint_text,
                ),
              ),
            ),
          ),
          ListTile(
            title: Text(loc.settings_language),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _language = value);
                await _prefs.setString('language', value);
                widget.onLanguageChanged(value);
              },
              items: const [
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ),
          ListTile(
            title: Text(loc.settings_font),
            trailing: DropdownButton<String>(
              value: _font,
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _font = value);
                await _prefs.setString('font', value);
                widget.onFontChanged(value);
              },
              items: supportedFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(fontFamily: font),
                  ),
                );
              }).toList(),
            ),
          ),
          ExpansionTile(
            title: Text(loc.settings_favorites),
            children: favoritePlaces.entries.map((entry) {
              final placeId = entry.key;
              final data = entry.value as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Ort'),
                subtitle: Text(data['kategorie'] ?? ''),
                onTap: () => _goToDetail(placeId, data),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeFavorite(placeId),
                ),
              );
            }).toList(),
          ),
          ExpansionTile(
            title: Text(loc.settings_blacklist),
            children: blacklistPlaces.entries.map((entry) {
              final placeId = entry.key;
              final data = entry.value as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Ort'),
                subtitle: Text(data['kategorie'] ?? ''),
                onTap: () => _goToDetail(placeId, data),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeBlacklist(placeId),
                ),
              );
            }).toList(),
          ),
          AboutListTile(
            icon: const Icon(Icons.info),
            applicationName: 'REISE',
            applicationVersion: '1.0.0',
            applicationIcon: const Icon(Icons.apps),
            aboutBoxChildren: [
              Text(loc.settings_about_text),
            ],
          ),
          ListTile(
            title: Text(loc.settings_reset),
            trailing: IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetPreferences,
            ),
          ),
        ],
      ),
    );
  }
}
