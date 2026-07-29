import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the React app's `sessionStorage` usage.
///
/// Original React keys this maps 1:1 to:
///   token, role, userid, email, Activeprofile, Currency,
///   siteSettings, displayname, permissions
///
/// NOTE: React used `sessionStorage` (cleared on tab close). Flutter has no
/// exact equivalent scoped to a single app "session" the same way, so this
/// uses SharedPreferences and calls `clear()` explicitly on logout - matching
/// the `sessionStorage.clear()` call in login.js on successful login and
/// wherever the app logs a user out.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ---- token / role / user identity (set in login.js handleSubmit) ----
  Future<void> setAuth({
    required String token,
    required String role,
    required String userId,
    required String email,
  }) async {
    final sp = await _sp;
    await sp.setString('token', token);
    await sp.setString('role', role);
    await sp.setString('userid', userId);
    await sp.setString('email', email);
  }

  Future<String?> get token async => (await _sp).getString('token');
  Future<String?> get role async => (await _sp).getString('role');
  Future<String?> get userId async => (await _sp).getString('userid');
  Future<String?> get email async => (await _sp).getString('email');

  Future<bool> get isAuthenticated async => (await token) != null;

  // ---- misc cached values (GlobalStateProvider.js / login.js) ----
  Future<void> setActiveProfile(String value) async =>
      (await _sp).setString('Activeprofile', value);
  Future<String?> get activeProfile async => (await _sp).getString('Activeprofile');

  Future<void> setCurrency(String value) async =>
      (await _sp).setString('Currency', value);
  Future<String?> get currency async => (await _sp).getString('Currency');

  Future<void> setSiteSettings(Map<String, dynamic> value) async =>
      (await _sp).setString('siteSettings', jsonEncode(value));
  Future<Map<String, dynamic>?> get siteSettings async {
    final raw = (await _sp).getString('siteSettings');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setDisplayName(Map<String, dynamic> value) async =>
      (await _sp).setString('displayname', jsonEncode(value));
  Future<Map<String, dynamic>?> get displayName async {
    final raw = (await _sp).getString('displayname');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setPermissions(Map<String, dynamic> value) async =>
      (await _sp).setString('permissions', jsonEncode(value));
  Future<Map<String, dynamic>?> get permissions async {
    final raw = (await _sp).getString('permissions');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Mirrors `sessionStorage.clear()` (called at the top of a successful
  /// login in login.js, before writing the new session values).
  Future<void> clear() async => (await _sp).clear();
}
