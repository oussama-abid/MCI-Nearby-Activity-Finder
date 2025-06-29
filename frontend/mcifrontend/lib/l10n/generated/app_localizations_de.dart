// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get home_title => 'Zählen';

  @override
  String get home_fab_tooltip => 'Erhöhen';

  @override
  String get settings_title => 'Einstellungen';

  @override
  String get settings_switch_mode => 'Dunkelmodus';

  @override
  String get settings_text_name => 'Name';

  @override
  String get settings_text_name_hint_text => 'Gib deinen Namen ein';

  @override
  String get settings_language => 'Sprache';

  @override
  String get settings_font => 'Schriftart';

  @override
  String get settings_favorites => 'Favoriten';

  @override
  String get settings_blacklist => 'Blacklist';

  @override
  String get settings_about_text =>
      'Reise-App zur spontanen Ausflugsplanung basierend auf Wetter & Interessen.';

  @override
  String get settings_language_changed => 'Sprache aktualisiert';

  @override
  String get settings_reset => 'Zurücksetzen';

  @override
  String get settings_reset_done => 'Alle Einstellungen wurden zurückgesetzt';

  @override
  String get map => 'Karte';

  @override
  String get favourites => 'Favoriten';

  @override
  String get settings => 'Einstellungen';
}
