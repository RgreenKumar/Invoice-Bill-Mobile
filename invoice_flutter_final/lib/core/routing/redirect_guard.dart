import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session_manager.dart';

/// Port of `src/RedirectComponent.js`.
///
/// Wraps registration routes with the same async guard logic as the
/// original: fetches `GET /Active/Environment` (caching Activeprofile +
/// Currency) if not already cached, optionally fetches `GET /count/admin`
/// when [admincount] is set, then redirects per the same rules:
///   - [sasonly] && Activeprofile != "SAS"  -> /notfound
///   - [admincount] && adminCount > 0       -> /notfound
///   - [vpsonly] && Activeprofile != "VPS"  -> /login
///
/// NOTE: the original's `checkvisible` / `showInLandingPage` branch reads
/// a `showInLandingPage` state that's fetched by a `useEffect` which is
/// commented out in the source (dead code, always stays `null`) - so that
/// branch never actually fires in the live app. It's omitted here to
/// match; only the `vpsonly` fallback of that same condition is reachable
/// and is already covered above.
class RedirectGuard extends StatefulWidget {
  const RedirectGuard({
    super.key,
    required this.child,
    this.vpsOnly = false,
    this.sasOnly = false,
    this.adminCount = false,
  });

  final Widget child;
  final bool vpsOnly;
  final bool sasOnly;
  final bool adminCount;

  @override
  State<RedirectGuard> createState() => _RedirectGuardState();
}

class _RedirectGuardState extends State<RedirectGuard> {
  bool _loading = true;
  String? _activeProfile;
  int _adminCountValue = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    _activeProfile = await SessionManager.instance.activeProfile;
    if (_activeProfile == null) {
      try {
        final res = await ApiClient.instance.dio.get('/Active/Environment');
        final env = res.data?['environment'];
        final currency = res.data?['currency'];
        if (env != null) {
          _activeProfile = env.toString();
          await SessionManager.instance.setActiveProfile(_activeProfile!);
        }
        if (currency != null) {
          await SessionManager.instance.setCurrency(currency.toString());
        }
      } catch (e) {
        debugPrint('RedirectGuard Active/Environment error: $e');
      }
    }

    if (widget.adminCount) {
      try {
        final res = await ApiClient.instance.dio.get('/count/admin');
        _adminCountValue = res.data is int ? res.data as int : int.tryParse('${res.data}') ?? 0;
      } catch (e) {
        debugPrint('RedirectGuard count/admin error: $e');
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String? redirect;
    if (widget.sasOnly && _activeProfile != 'SAS') {
      redirect = '/notfound';
    } else if (widget.adminCount && _adminCountValue > 0) {
      redirect = '/notfound';
    } else if (widget.vpsOnly && _activeProfile != 'VPS') {
      redirect = '/login';
    }

    if (redirect != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(redirect!));
      return const Scaffold(body: SizedBox.shrink());
    }

    return widget.child;
  }
}
