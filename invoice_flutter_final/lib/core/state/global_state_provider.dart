import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../session/session_manager.dart';

/// Flutter equivalent of `src/Context/GlobalStateProvider.js`.
///
/// The original React provider, on mount, fired 4 requests:
///   GET /Active/Environment        -> Activeprofile, Currency
///   GET /settings/general/get      -> generalSettings   (auth'd)
///   GET /settings/gst/get          -> gstSettings        (auth'd)
///   GET /settings/item/get         -> itemSettings       (auth'd)
///   GET /Get/labellings            -> siteSettings       (auth'd, ADMIN only)
///   GET /all/get/labellings        -> siteSettings       (everyone else)
///   GET /get/displayName           -> displayname        (auth'd)
///
/// Same endpoints, same fallbacks/defaults, same caching-in-storage
/// behavior (siteSettings + displayname were cached in sessionStorage in
/// React; mirrored here via SessionManager/SharedPreferences).
class GlobalStateProvider extends ChangeNotifier {
  Map<String, dynamic> displayname = const {
    'admin_name': '',
    'trainer_name': '',
    'student_name': '',
  };

  Map<String, dynamic> siteSettings = const {
    'siteUrl': '',
    'title': '',
    'sitelogo': null,
    'siteicon': null,
    'titleicon': null,
  };

  String activeProfile = '';

  Map<String, dynamic> generalSettings = const {
    'gstinNumber': true,
    'estimateQuotation': true,
    'salesInvoiceOrder': true,
    'amountDecimalPlaces': 2,
    'otpservice': true,
  };

  Map<String, dynamic> gstSettings = const {
    'enableGST': true,
    'enableHSN': true,
    'additionalCess': false,
    'enablePlaceOfSupply': true,
  };

  Map<String, dynamic> itemSettings = const {
    'enableItem': true,
    'stockMaintenance': true,
    'showLowStockDialog': true,
    'itemsUnit': true,
    'defaultUnit': '',
    'itemCategory': true,
    'description': false,
    'itemWiseTax': true,
    'itemWiseDiscount': true,
    'quantityDecimalPlaces': 2,
    'wholesalePrice': true,
    'mrp': false,
    'calculateTaxBasedOnMrp': false,
    'expDate': true,
    'expDateFormat': 'mm/yy',
    'mfgDate': true,
    'mfgDateFormat': 'dd/mm/yy',
    'modelNo': false,
    'size': false,
  };

  List<dynamic> lowStockItems = [];

  /// Mirrors the `setLowStockItems` setter exposed via GlobalStateContext
  /// and called from Header.js's `fetchLowStock`.
  void setLowStockItems(List<dynamic> items) {
    lowStockItems = items;
    notifyListeners();
  }

  /// Mirrors `setGeneralSettings` from GlobalStateContext, called by
  /// `UserSettings/SettingsComponent.js` right after a successful
  /// `POST /settings/general/save`.
  void setGeneralSettings(Map<String, dynamic> settings) {
    generalSettings = {...generalSettings, ...settings};
    notifyListeners();
  }

  /// Mirrors `setGstSettings`, called by `UserSettings/TaxesGST.js` after
  /// `POST /settings/gst/save`.
  void setGstSettings(Map<String, dynamic> settings) {
    gstSettings = {...gstSettings, ...settings};
    notifyListeners();
  }

  /// Mirrors `setItemSettings`, called by `UserSettings/Itemsettings.js`
  /// after `POST /settings/item/save`.
  void setGlobalItemSettings(Map<String, dynamic> settings) {
    itemSettings = {...itemSettings, ...settings};
    notifyListeners();
  }

  /// Mirrors the `sessionStorage.setItem("displayname", ...)` +
  /// GlobalStateContext refresh done by `UserSettings/DisplayName.js`
  /// after a successful save, so the sidebar's custom Trainer/Student
  /// labels update immediately without a full re-login.
  Future<void> setDisplayNameMap(Map<String, dynamic> data) async {
    displayname = data;
    await SessionManager.instance.setDisplayName(data);
    notifyListeners();
  }

  /// Mirrors `Sitesettings.js` writing straight to the labellings cache
  /// after a successful `POST /save/labellings`.
  Future<void> setSiteSettingsMap(Map<String, dynamic> data) async {
    siteSettings = data;
    await SessionManager.instance.setSiteSettings(data);
    notifyListeners();
  }

  Future<void> init() async {
    await Future.wait([
      _fetchActiveProfile(),
      _fetchGeneralSettings(),
      _fetchGstSettings(),
      _fetchItemSettings(),
      _fetchLabels(),
      _fetchDisplayName(),
    ]);
  }

  Future<void> _fetchActiveProfile() async {
    try {
      final res = await ApiClient.instance.dio.get('/Active/Environment');
      final env = res.data?['environment'];
      final cur = res.data?['currency'];
      if (env != null) {
        activeProfile = env.toString();
        await SessionManager.instance.setActiveProfile(activeProfile);
      }
      if (cur != null) {
        await SessionManager.instance.setCurrency(cur.toString());
      }
    } catch (e) {
      debugPrint('Active/Environment error: $e');
    }
    notifyListeners();
  }

  Future<void> _fetchGeneralSettings() async {
    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/settings/general/get');
      // BUGFIX: merge onto defaults instead of replacing the whole map -
      // if the backend response omits a key, it must fall back to the
      // default rather than silently becoming null/missing.
      if (res.data is Map) generalSettings = {...generalSettings, ...Map<String, dynamic>.from(res.data as Map)};
    } catch (e) {
      debugPrint('Failed to load general settings: $e');
    }
    notifyListeners();
  }

  Future<void> _fetchGstSettings() async {
    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/settings/gst/get');
      if (res.data is Map) gstSettings = {...gstSettings, ...Map<String, dynamic>.from(res.data as Map)};
    } catch (e) {
      debugPrint('Failed to load GST settings: $e');
    }
    notifyListeners();
  }

  Future<void> _fetchItemSettings() async {
    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/settings/item/get');
      // BUGFIX (root cause of "low stock notifications never appear"):
      // this used to replace `itemSettings` outright with whatever the
      // backend returned. If that response didn't include
      // `showLowStockDialog` (e.g. an item-settings row saved before that
      // field existed, or the backend simply omits false/never-set
      // fields), the key became missing entirely, `itemSettings
      // ['showLowStockDialog'] == true` evaluated to false, and the low-
      // stock badge/notification was permanently hidden regardless of
      // actual stock levels. Merging onto the default (`true`) means a
      // missing key can no longer silently turn the feature off.
      if (res.data is Map) itemSettings = {...itemSettings, ...Map<String, dynamic>.from(res.data as Map)};
    } catch (e) {
      debugPrint('Failed to load item settings: $e');
    }
    notifyListeners();
  }

  Future<void> _fetchLabels() async {
    try {
      final cached = await SessionManager.instance.siteSettings;
      if (cached != null) {
        siteSettings = cached;
        notifyListeners();
        return;
      }
      final token = await SessionManager.instance.token;
      final role = await SessionManager.instance.role;
      final res = (token != null && role == 'ADMIN')
          ? await ApiClient.instance.dio.get('/Get/labellings')
          : await ApiClient.instance.dio.get('/all/get/labellings');
      // BUGFIX: backend can return "" (empty body) instead of a JSON
      // object when no labels are configured yet - guard the cast so
      // that just falls back to defaults instead of throwing.
      if (res.data is Map) {
        siteSettings = Map<String, dynamic>.from(res.data as Map);
        await SessionManager.instance.setSiteSettings(siteSettings);
      }
    } catch (e) {
      debugPrint('Error fetching site settings: $e');
    }
    notifyListeners();
  }

  Future<void> _fetchDisplayName() async {
    final cached = await SessionManager.instance.displayName;
    if (cached != null) {
      displayname = cached;
      notifyListeners();
      return;
    }
    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/get/displayName');
      if (res.statusCode == 200 && res.data is Map) {
        displayname = Map<String, dynamic>.from(res.data as Map);
        await SessionManager.instance.setDisplayName(displayname);
      } else if (res.statusCode == 204) {
        displayname = {};
        await SessionManager.instance.setDisplayName({});
      }
    } catch (e) {
      // React: on 404 it reset to blank defaults instead of surfacing error.
      displayname = {
        'admin_name': '',
        'trainer_name': '',
        'student_name': '',
      };
      await SessionManager.instance.setDisplayName(displayname);
    }
    notifyListeners();
  }
}
