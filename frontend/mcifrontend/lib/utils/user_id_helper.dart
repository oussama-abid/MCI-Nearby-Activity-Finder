import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  if (userId == null) {
    userId = const Uuid().v4();
    await prefs.setString('userId', userId);
  }

  return userId;
}
