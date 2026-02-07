import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _passwordKey = 'app_password';
  static const String _isPasswordSetKey = 'is_password_set';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Save a new password
  Future<void> savePassword(String password) async {
    print('SecurityService: Saving password...');
    await _storage.write(key: _passwordKey, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPasswordSetKey, true);
    print('SecurityService: Password saved.');
  }

  // Check if the entered password is correct
  Future<bool> checkPassword(String password) async {
    final savedPassword = await _storage.read(key: _passwordKey);
    return savedPassword == password;
  }

  // Check if a password has been set
  Future<bool> isPasswordSet() async {
    print('SecurityService: Checking if password is set...');
    final prefs = await SharedPreferences.getInstance();
    final isSet = prefs.getBool(_isPasswordSetKey) ?? false;
    print('SecurityService: Is password set? $isSet');
    return isSet;
  }

  // Update password (verify old one first)
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    final isCorrect = await checkPassword(oldPassword);
    if (isCorrect) {
      await savePassword(newPassword);
      return true;
    }
    return false;
  }
}
