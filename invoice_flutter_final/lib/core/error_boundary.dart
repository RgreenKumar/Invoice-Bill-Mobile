import 'package:flutter/material.dart';

/// Port of `src/ErrorBoundary.js` (a React class component using
/// `getDerivedStateFromError` / `componentDidCatch`).
///
/// Flutter has no direct widget-tree equivalent of a React error boundary
/// (a widget can't "catch" a build error in its own subtree and swap in a
/// fallback the way React can) - the idiomatic Flutter approach is a
/// global `ErrorWidget.builder` override, wired up once in `main()`, that
/// applies everywhere automatically instead of needing to be wrapped
/// around every route the way `<ErrorBoundary>` was in App.js.
///
/// Call [installErrorBoundary] once during app startup (see `main.dart`).
void installErrorBoundary() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Error captured by ErrorBoundary: ${details.exception}\n${details.stack}');
    return const _ErrorFallback();
  };
}

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Oops! Something Went Wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Some Unexpected Error Occurred Please Try again later.'),
            ],
          ),
        ),
      ),
    );
  }
}
