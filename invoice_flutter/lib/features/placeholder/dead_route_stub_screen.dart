import 'package:flutter/material.dart';

/// Shared stub for four React source files that are **entirely commented
/// out** (no active default export at all, not even a blank component):
///
///   - `Registration/StudentRegister.js`
///   - `Registration/TrainerRegistration.js`
///   - `AuthenticationPages/LicenceDetails.js`
///   - `AuthenticationPages/LicenceFileCreation.js`
///
/// `App.js` still imports and routes to all four (`/StudentRegistration`,
/// `/TrainerRegistration`, `/licenceDetails`, `/getlicence`), which means
/// in the *live* React app those routes currently render `undefined` and
/// throw a React "Element type is invalid" error rather than any UI.
///
/// Rather than inventing new registration/licence forms the source
/// doesn't define, this reproduces the actual current behavior (broken/
/// blank route) and documents which file to reference if/when the
/// commented-out implementation should be restored and then converted.
class DeadRouteStubScreen extends StatelessWidget {
  const DeadRouteStubScreen({super.key, required this.reactSource});

  final String reactSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.code_off, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'This route is currently non-functional in the source React app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$reactSource is entirely commented out (no active export) '
                'in the original codebase.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
