import '../routing/app_router.dart';

/// Direct port of `src/utils/modules.js`.
///
/// NOTE: `SETTINGS` and `MY_COMPANY` are commented out in the original
/// JS object (so `MODULES.SETTINGS` / `MODULES.MY_COMPANY` are
/// `undefined` there). `getPermission(undefined, "canView")` always
/// evaluates false, which means the "Settings" and "My Company" sidebar
/// sections **never actually render for CASHIER users** in the original
/// app - that's preserved here by simply omitting those two keys rather
/// than "fixing" the apparent bug.
class Modules {
  static const saleInvoice = 'Sale Invoice';
  static const invoicePos = 'Invoice POS';
  static const estimateQuotation = 'Estimate Quotation';
  static const addItem = 'Add Item';
  static const viewItem = 'View Item';
  static const customer = 'Customer';
  static const parties = 'Parties';
  static const stockAdjustment = 'Stock Adjustment';
}

/// Port of `src/utils/permissionUtils.js` `getPermission`.
///
/// Original:
///   const role = sessionStorage.getItem("role");
///   if (role === "ADMIN" || role === "SYSADMIN") return true;
///   const permissions = secureGet("permissions") || {};
///   return permissions[moduleName]?.[action] === true;
bool getPermission(String? moduleName, String action) {
  final role = AuthSnapshot.role;
  if (role == 'ADMIN' || role == 'SYSADMIN') return true;
  if (moduleName == null) return false;
  final modulePerms = AuthSnapshot.permissions[moduleName];
  if (modulePerms is Map) {
    return modulePerms[action] == true;
  }
  return false;
}
