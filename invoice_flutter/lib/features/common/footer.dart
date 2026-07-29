import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session_manager.dart';

/// Port of `src/Common Components/Footer.js`.
///
/// In the original, `<Footer />` is rendered as a sibling of `<Routes>`
/// (outside the Router switch), so it appears on every page including
/// the login screen - reproduced here via `MaterialApp.router`'s
/// `builder` in `main.dart`, which wraps every routed page with this
/// widget rather than nesting it per-screen.
///
/// Preserves: `GET /all/get/FooterDetails` fired only when
/// `Activeprofile == "VPS"`; falls back to the same hardcoded defaults
/// on 204/error.
class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  Map<String, String> _details = const {
    'copyright': '',
    'contact': '',
    'supportmail': '',
    'institutionmail': '',
  };

  static const _defaults = {
    'copyright': '© 2024 All rights reserved',
    'supportmail': 'support@vsmartengine.com',
    'contact': 'Ph : 91-9566191759',
    'institutionmail': 'learnhub.vsmartengine.com',
  };

  @override
  void initState() {
    super.initState();
    _loadFooterDetails();
  }

  Future<void> _loadFooterDetails() async {
    final activeProfile = await SessionManager.instance.activeProfile;
    if (activeProfile != 'VPS') return;
    try {
      final res = await ApiClient.instance.dio.get('/all/get/FooterDetails');
      if (res.statusCode == 200) {
        setState(() => _details = Map<String, String>.from(
            (res.data as Map).map((k, v) => MapEntry('$k', '$v'))));
      } else if (res.statusCode == 204) {
        setState(() => _details = const {
              'copyright': '',
              'contact': '',
              'supportmail': '',
              'institutionmail': '',
            });
      }
    } catch (e) {
      debugPrint('footer error: $e');
      setState(() => _details = const {
            'copyright': '',
            'contact': '',
            'supportmail': '',
            'institutionmail': '',
          });
    }
  }

  String _value(String key) => _details[key]?.isNotEmpty == true ? _details[key]! : (_defaults[key] ?? '');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFFF4F6F8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: [
          Text(_value('copyright'), style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B79))),
          Text(_value('supportmail'), style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B79))),
          Text(_value('contact'), style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B79))),
          Text(_value('institutionmail'), style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B79))),
        ],
      ),
    );
  }
}
