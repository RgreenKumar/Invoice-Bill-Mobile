import '../../core/utils/safe_back.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Port of `src/AuthenticationPages/Missing.js`.
class MissingScreen extends StatelessWidget {
  const MissingScreen({super.key});

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
              const Text('404', style: TextStyle(fontSize: 72, color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Oops! Page not found', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text(
                'The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Go back To '),
                  TextButton(
                    onPressed: () => context.go('/dashboard/viewitem'),
                    child: const Text('Home'),
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
