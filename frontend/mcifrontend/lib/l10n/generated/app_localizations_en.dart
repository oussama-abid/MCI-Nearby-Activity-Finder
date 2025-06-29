// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home_title => 'Counter Example';

  @override
  String get home_fab_tooltip => 'Increment';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_switch_mode => 'Dark Mode';

  @override
  String get settings_text_name => 'Name';

  @override
  String get settings_text_name_hint_text => 'Enter your name';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_font => 'Font';

  @override
  String get settings_favorites => 'Favorites';

  @override
  String get settings_blacklist => 'Blacklist';

  @override
  String get settings_about_text =>
      'Travel app for spontaneous trips based on weather and interests.';

  @override
  String get settings_language_changed => 'Language updated';

  @override
  String get settings_reset => 'Reset';

  @override
  String get settings_reset_done => 'All settings have been reset';

  @override
  String get map => 'Map';

  @override
  String get favourites => 'Favourites';

  @override
  String get settings => 'Settings';
}
