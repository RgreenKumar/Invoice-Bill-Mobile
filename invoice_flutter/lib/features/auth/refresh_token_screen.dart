import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/safe_back.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session_manager.dart';

/// Port of `src/AuthenticationPages/RefreshToken.js`.
///
/// Preserves: `POST /refreshtoken` with the current token as
/// Authorization header; on success overwrites the stored token and goes
/// back one entry in history (`navigate(-1)`).
class RefreshTokenScreen extends StatelessWidget {
  const RefreshTokenScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final token = await SessionManager.instance.token;
    try {
      final res = await ApiClient.instance.dio.post('/refreshtoken');
      if (res.statusCode == 200 && (token?.isNotEmpty ?? false)) {
        await SessionManager.instance.setAuth(
          token: '${res.data}',
          role: (await SessionManager.instance.role) ?? '',
          userId: (await SessionManager.instance.userId) ?? '',
          email: (await SessionManager.instance.email) ?? '',
        );
        if (context.mounted) safeBack(context);
      }
    } catch (e) {
      debugPrint('Refresh token failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Session Expired',
                  style: TextStyle(fontSize: 32, color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Oops! It seems your session was Expired Try Login again or Refresh your Session .',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text('Refresh Session by Clicking Refresh button..'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refresh(context),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
