import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/session/session_manager.dart';
import '../../theme/app_theme.dart';

/// Conversion of `src/AuthenticationPages/login.js`.
///
/// Preserves:
///  - GET /Active/Environment      (on load, caches Activeprofile/Currency)
///  - GET /count/admin             (on load, decides whether "New user?" link shows)
///  - POST /login  {username,password}
///  - on 200: stores token/role/userid/email, and if role == CASHIER also
///    fetches GET /cashier/permissions/{userid} and caches per-module perms
///  - on 200 role SYSADMIN -> /viewAll/Admins else -> /dashboard/viewitem
///  - on 404 -> "User not found" under username field
///  - on 401 message "Incorrect password" -> shows attemptsLeft
///  - on 401 message "In Active" / "Not Approved" -> alert dialog
///  - client-side validation: email regex, password length >= 6
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _usernameError;
  String? _passwordError;
  bool _submitting = false;
  bool _adminExists = true; // default true -> hides "New user?" link

  @override
  void initState() {
    super.initState();
    _getActiveProfile();
    _checkAdminCount();
  }

  Future<void> _getActiveProfile() async {
    try {
      final res = await ApiClient.instance.dio.get('/Active/Environment');
      final env = res.data?['environment'];
      final currency = res.data?['currency'];
      if (env != null) await SessionManager.instance.setActiveProfile(env.toString());
      if (currency != null) await SessionManager.instance.setCurrency(currency.toString());
    } catch (_) {
      // React: logged + re-threw, but had no visible effect on the login UI.
    }
  }

  Future<void> _checkAdminCount() async {
    try {
      final res = await ApiClient.instance.dio.get('/count/admin');
      final count = res.data is int ? res.data as int : int.tryParse('${res.data}') ?? 0;
      setState(() => _adminExists = count > 0);
    } catch (_) {
      // React: logged only, left default (true).
    }
  }

  String? _validateUsername(String value) {
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.com$').hasMatch(value);
    return ok ? null : 'Please enter a valid email address';
  }

  String? _validatePassword(String value) {
    return value.length < 6 ? 'Password must be at least 6 characters long' : null;
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    setState(() {
      _usernameError = username.isEmpty ? 'Please Enter The Email' : _validateUsername(username);
      _passwordError = password.isEmpty ? 'Please Enter The Password' : _validatePassword(password);
    });

    if (_usernameError != null || _passwordError != null) return;

    setState(() => _submitting = true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        await SessionManager.instance.clear();
        final data = response.data as Map;
        final token = data['token'].toString();
        final role = data['role'].toString();
        await SessionManager.instance.setAuth(
          token: token,
          role: role,
          userId: data['userid'].toString(),
          email: data['email'].toString(),
        );

        if (role == 'CASHIER') {
          try {
            final permRes = await ApiClient.instance.dio
                .get('/cashier/permissions/${data['userid']}');
            final permObj = <String, dynamic>{};
            for (final p in (permRes.data as List)) {
              permObj[p['moduleName']] = {
                'canView': p['canView'],
                'canCreate': p['canCreate'],
                'canEdit': p['canEdit'],
                'canDelete': p['canDelete'],
              };
            }
            await SessionManager.instance.setPermissions(permObj);
          } catch (_) {
            await SessionManager.instance.setPermissions({});
          }
        }

        if (!mounted) return;
        // BUGFIX: route guards (_Guard.evaluate in app_router.dart) read
        // the synchronous AuthSnapshot, which is only populated at app
        // startup. Without this refresh, the guard on /dashboard/viewitem
        // or /viewAll/Admins still sees the stale logged-out state and
        // immediately redirects back to /login - looking like "login does
        // nothing."
        await AuthSnapshot.refresh();
        if (!mounted) return;
        if (role == 'SYSADMIN') {
          context.go('/viewAll/Admins');
        } else {
          context.go('/dashboard/viewitem');
        }
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        setState(() => _usernameError = 'User not found');
      } else if (status == 401) {
        final data = e.response?.data;
        final message = data is Map ? data['message'] : null;
        if (message == 'Incorrect password') {
          final attemptsLeft = data is Map ? data['attemptsLeft'] : null;
          setState(() => _passwordError =
              'Incorrect password. $attemptsLeft attempts left before account lockout.');
        } else if (message == 'In Active') {
          _showAlert('In Active User!', 'reason : ${data is Map ? data['Description'] : ''}');
        } else if (message == 'Not Approved') {
          _showAlert('$message', '${data is Map ? data['Description'] : ''}');
        }
      } else {
        // Was `rethrow` (uncaught) - any error other than a handled 404/401
        // (network failure, CORS block, backend down, 500, timeout, etc.)
        // silently crashed with no UI feedback. Surface it instead.
        _showAlert('Connection Error',
            'Could not reach the server (${e.type.name}). '
            'Check that the backend is running and reachable at the '
            'configured API_BASE_URL, and that it allows requests from '
            'this app\'s origin (CORS) if running on web.\n\n${e.message ?? ''}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _handleRegistration() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Select your Role'),
        content: const Text('Register as Admin'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go('/adminRegistration');
            },
            child: const Text('Register as Admin'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // ── LEFT DARK PANEL (.inv-left-panel) ──
          if (isWide)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(gradient: AppGradients.leftPanel),
                child: const _LeftPanelContent(),
              ),
            ),

          // ── RIGHT CARD (.inv-card-center / .inv-card-login) ──
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF4F6F8),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, size: 48, color: AppColors.darkMid),
                      const SizedBox(height: 16),
                      Text('Sign in', style: AppTheme.headingSerif),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          errorText: _usernameError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          errorText: _passwordError,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text('Forgot Password?'),
                          ),
                          if (!_adminExists)
                            TextButton(
                              onPressed: _handleRegistration,
                              child: const Text('New user?'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.loginButton,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _submitting ? null : _handleSubmit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Login', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftPanelContent extends StatelessWidget {
  const _LeftPanelContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            const Text('InvoiceBill',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const Icon(Icons.insert_chart, color: AppColors.accent, size: 120),
            const SizedBox(height: 40),
            Text(
              'Smart Invoicing\nMade Simple',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage billing, track payments,\nand grow your business with confidence.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(active: true),
                _dot(active: false),
                _dot(active: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot({required bool active}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.accent : Colors.white24,
        ),
      );
}
