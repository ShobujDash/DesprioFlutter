import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const defaultBaseUrl = 'https://deshprio.onrender.com/api';
  static const _baseUrlKey = 'base_url';
  static const _printerAddressKey = 'printer_address';
  static const _printerNameKey = 'printer_name';
  static const _tokenKey = 'auth_token';

  String baseUrl = defaultBaseUrl;
  String? printerAddress;
  String? printerName;
  String? authToken;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl = prefs.getString(_baseUrlKey);
    if (savedBaseUrl == null || _isLocalBackend(savedBaseUrl)) {
      baseUrl = defaultBaseUrl;
      await prefs.setString(_baseUrlKey, baseUrl);
    } else {
      baseUrl = savedBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    printerAddress = prefs.getString(_printerAddressKey);
    printerName = prefs.getString(_printerNameKey);
    authToken = prefs.getString(_tokenKey);
  }

  Future<void> setBaseUrl(String value) async {
    baseUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
    notifyListeners();
  }

  Future<void> setPrinter(
      {required String address, required String name}) async {
    printerAddress = address;
    printerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerAddressKey, address);
    await prefs.setString(_printerNameKey, name);
    notifyListeners();
  }

  Future<void> setAuthToken(String? token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
    notifyListeners();
  }
}

bool _isLocalBackend(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.contains('10.0.2.2') ||
      normalized.contains('localhost') ||
      normalized.contains('127.0.0.1');
}

class SettingsScope extends InheritedNotifier<SettingsService> {
  const SettingsScope(
      {super.key, required SettingsService notifier, required super.child})
      : super(notifier: notifier);

  static SettingsService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('SettingsScope missing');
    }
    return scope.notifier!;
  }
}
