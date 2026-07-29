import 'package:flutter/material.dart';

/// Shown for every React route that has not been converted to a real
/// Flutter screen yet. Keeps the whole route table/navigation working
/// end-to-end while individual features are ported one by one.
///
/// [reactSource] documents exactly which original file still needs
/// converting, so this can be searched for a to-do list.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.reactSource,
  });

  final String title;
  final String reactSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '"$title" is not converted yet.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Original React source: $reactSource',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
