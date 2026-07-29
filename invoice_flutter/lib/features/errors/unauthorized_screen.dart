import '../../core/utils/safe_back.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Port of `src/AuthenticationPages/Unauthorized.js`.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safeBack(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => safeBack(context)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('401', style: TextStyle(fontSize: 72, color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Oops! It seems you are not authorized to access this page.',
                  style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Please contact the administrator for assistance..', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Go back To '),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
