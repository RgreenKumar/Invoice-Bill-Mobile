import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../session/session_manager.dart';
import '../routing/redirect_guard.dart';
import '../../features/auth/admin_register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/licence_expired_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/refresh_token_screen.dart';
import '../../features/auth/sysadmin_licence_upload_screen.dart';
import '../../features/common/app_shell.dart';
import '../../features/common/my_company_screen.dart';
import '../../features/common/profile_screen.dart';
import '../../features/course/add_item_screen.dart';
import '../../features/course/category_screen.dart';
import '../../features/course/units_screen.dart';
import '../../features/course/view_item_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/errors/missing_screen.dart';
import '../../features/errors/unauthorized_screen.dart';
import '../../features/placeholder/dead_route_stub_screen.dart';
import '../../features/placeholder/placeholder_screen.dart';
import '../../features/sales/estimate_quotation_screen.dart';
import '../../features/sales/invoice_form_screen.dart';
import '../../features/sales/view_invoice_sale_screen.dart';
import '../../features/settings/add_user_screen.dart';
import '../../features/settings/display_name_screen.dart';
import '../../features/settings/footer_settings_screen.dart';
import '../../features/settings/item_settings_screen.dart';
import '../../features/settings/mail_settings_screen.dart';
import '../../features/settings/manage_users_screen.dart';
import '../../features/settings/settings_home_screen.dart';
import '../../features/settings/taxes_gst_screen.dart';
import '../../features/settings/weightage_settings_screen.dart';
import '../../features/student/add_customer_screen.dart';
import '../../features/student/view_student_list_screen.dart';
import '../../features/trainer/add_supplier_screen.dart';
import '../../features/trainer/view_trainer_list_screen.dart';

/// Route guard flags - direct mirror of the props passed to
/// `<PrivateRoute .../>` in `src/AuthenticationPages/PrivateRoute.js`:
///
///   authenticationRequired, authorizationRequired, onlyadmin, onlyuser,
///   onlytrainer, sysadmin, sysandadmin
class _Guard {
  const _Guard({
    this.authenticationRequired = false,
    this.authorizationRequired = false,
    this.onlyAdmin = false,
    this.onlyUser = false,
    this.onlyTrainer = false,
    this.sysAdmin = false,
    this.sysAndAdmin = false,
  });

  final bool authenticationRequired;
  final bool authorizationRequired;
  final bool onlyAdmin;
  final bool onlyUser;
  final bool onlyTrainer;
  final bool sysAdmin;
  final bool sysAndAdmin;

  /// Faithful port of the if/else chain in PrivateRoute.js. Returns the
  /// redirect path, or null if navigation should proceed.
  String? evaluate({required bool isAuthenticated, required String? role}) {
    if (authenticationRequired && !isAuthenticated) return '/login';

    if (authorizationRequired) {
      if (role == 'USER') return '/unauthorized';
      if (role == null) return '/login';
    }

    if (onlyAdmin && (role == 'TRAINER' || role == 'USER')) return '/unauthorized';

    if (sysAdmin && (role == 'TRAINER' || role == 'USER' || role == 'ADMIN')) {
      return '/unauthorized';
    }

    if (onlyTrainer && (role == 'ADMIN' || role == 'USER')) return '/unauthorized';

    if (onlyUser && (role == 'ADMIN' || role == 'TRAINER')) return '/unauthorized';

    if (sysAndAdmin && role != 'ADMIN' && role != 'SYSADMIN') return '/unauthorized';

    return null;
  }
}

/// One entry per <Route> in App.js. `builder` is the converted screen if
/// it exists yet, otherwise a PlaceholderScreen naming the original file.
class _RouteEntry {
  const _RouteEntry(this.path, this.builder, this.guard);
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;
  final _Guard guard;
}

Widget _placeholder(String title, String reactSource) =>
    PlaceholderScreen(title: title, reactSource: reactSource);

final List<_RouteEntry> _routes = [
  // ── Public routes ──
  _RouteEntry('/', (c, s) => const _RedirectToLogin(), const _Guard()),
  _RouteEntry('/login', (c, s) => const LoginScreen(), const _Guard()),
  _RouteEntry('/unauthorized', (c, s) => const UnauthorizedScreen(), const _Guard()),
  _RouteEntry('/forgot-password', (c, s) => const ForgotPasswordScreen(), const _Guard()),
  _RouteEntry('/LicenceExpired', (c, s) => const LicenceExpiredScreen(), const _Guard()),
  _RouteEntry('/RegisterInstitute', (c, s) => const RedirectGuard(
        sasOnly: true,
        child: AdminRegisterScreen(),
      ), const _Guard()),
  _RouteEntry('/adminRegistration', (c, s) => const RedirectGuard(
        adminCount: true,
        vpsOnly: true,
        child: AdminRegisterScreen(),
      ), const _Guard()),
  _RouteEntry('/TrainerRegistration', (c, s) => RedirectGuard(
        vpsOnly: true,
        child: const DeadRouteStubScreen(reactSource: 'Registration/TrainerRegistration.js'),
      ), const _Guard()),
  _RouteEntry('/StudentRegistration', (c, s) => RedirectGuard(
        vpsOnly: true,
        child: const DeadRouteStubScreen(reactSource: 'Registration/StudentRegister.js'),
      ), const _Guard()),

  // ── Authenticated (session only) ──
  _RouteEntry('/refresh', (c, s) => const RefreshTokenScreen(), const _Guard(authenticationRequired: true)),
  _RouteEntry('/updatePayment', (c, s) => _placeholder('Update Stripe Payment', 'course/Payments/UpdateStripepayment.js'), const _Guard(authenticationRequired: true, onlyUser: true)),
  _RouteEntry('/updatePaypalPayment', (c, s) => _placeholder('Update PayPal Payment', 'course/Payments/UpdatePaypalPayment.js'), const _Guard(authenticationRequired: true, onlyUser: true)),

  // ── Authenticated + authorized (main app, inside Layout in React) ──
  _RouteEntry('/admin/dashboard', (c, s) => const DashboardScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/dashboard/viewitem', (c, s) => const ViewItemScreen(), const _Guard(authenticationRequired: true)),
  _RouteEntry('/dashboard/category', (c, s) => const CategoryScreen(), const _Guard(authenticationRequired: true)),
  _RouteEntry('/dashboard/unit', (c, s) => const UnitsScreen(), const _Guard(authenticationRequired: true)),
  _RouteEntry('/item/additem', (c, s) => const AddItemScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/edititem/:id', (c, s) => AddItemScreen(itemId: s.pathParameters['id']), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/course/admin/edit', (c, s) => _placeholder('Edit Courses (Admin)', 'course/Update/EditCourse.js'), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/course/edit/:courseId', (c, s) => _placeholder('Edit Course', 'course/Update/EditCourseForm.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/course/dashboard/profile', (c, s) => const ProfileScreen(), const _Guard(authenticationRequired: true)),
  _RouteEntry('/lessonList/:courseName/:courseId', (c, s) => _placeholder('Lesson List', 'course/Components/LessonList.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/edit/:courseName/:courseId/:lessonTitle/:lessonId', (c, s) => _placeholder('Edit Lesson', 'course/Update/EditLesson.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/courses/:courseName/:courseId', (c, s) => _placeholder('View Video', 'course/Components/ViewVideo.js'), const _Guard(authenticationRequired: true)),
  _RouteEntry('/courses/:courseName/:courseId/:current', (c, s) => _placeholder('Custom View Video', 'course/Components/CustomViewvideo.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/course/Addlesson/:courseName/:courseId', (c, s) => _placeholder('Upload Video', 'course/Components/UploadVideo.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/viewDocument/:documentPath/:lessonId/:docid', (c, s) => _placeholder('Slide Viewer', 'course/Components/SlideViewer.js'), const _Guard(authenticationRequired: true)),
  _RouteEntry('/mycourses', (c, s) => const DeadRouteStubScreen(reactSource: 'Student/Mycourse.js'), const _Guard(authenticationRequired: true)),
  _RouteEntry('/pendingInstallments', (c, s) => const DeadRouteStubScreen(reactSource: 'Student/PendingInstallments.js'), const _Guard(authenticationRequired: true, onlyUser: true)),
  _RouteEntry('/MyCertificateList', (c, s) => _placeholder('My Certificates', 'certificate/MyCertificateList.js'), const _Guard(authenticationRequired: true)),
  _RouteEntry('/template/:activityId', (c, s) => _placeholder('Certificate Template', 'certificate/Template.js'), const _Guard(authenticationRequired: true)),
  _RouteEntry('/myPayments', (c, s) => const DeadRouteStubScreen(reactSource: 'Student/MyPayments.js'), const _Guard(authenticationRequired: true, onlyUser: true)),

  // Trainer / supplier
  _RouteEntry('/addSupplier', (c, s) => const AddSupplierScreen(partyType: 'SUPPLIER'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/view/Trainer', (c, s) => const ViewTrainerListScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/view/Trainer/profile/:traineremail', (c, s) => const DeadRouteStubScreen(reactSource: 'Trainer/TrainerProfile.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/trainer/edit/:email', (c, s) => const DeadRouteStubScreen(reactSource: 'Trainer/EditTrainer.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/assignCourse/Student/:userId', (c, s) => const DeadRouteStubScreen(reactSource: 'Student/AssignCourse.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),

  // Student / customer
  _RouteEntry('/addCustomer', (c, s) => const AddCustomerScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/view/Students', (c, s) => const ViewStudentListScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/view/Student/profile/:studentemail', (c, s) => const DeadRouteStubScreen(reactSource: 'Student/StudentProfile.js (+ Student/Profile.js)'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/student/edit/:email', (c, s) => const DeadRouteStubScreen(reactSource: 'Student/EditStudent.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),

  // Approvals / about / payments settings
  _RouteEntry('/view/Approvals', (c, s) => _placeholder('Approvals', 'Registration/Approvals.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/payment/keys', (c, s) => _placeholder('Payment Gateway Keys', 'course/Payments/MainPaymentSettingPage.js'), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/payment/transactionHitory', (c, s) => _placeholder('Payment Transactions', 'course/Components/Paymenttransactions.js'), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/certificate', (c, s) => _placeholder('Certificate Inputs', 'certificate/CertificateInputs.js'), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/about', (c, s) => _placeholder('About Us', 'AuthenticationPages/AboutUs.js'), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/licenceDetails', (c, s) => const DeadRouteStubScreen(reactSource: 'AuthenticationPages/LicenceDetails.js'), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),

  // Settings
  _RouteEntry('/settings/Weightage', (c, s) => const WeightageSettingsScreen(), const _Guard(authenticationRequired: true, onlyAdmin: true)),
  _RouteEntry('/settings/mailSettings', (c, s) => const MailSettingsScreen(), const _Guard(authenticationRequired: true, onlyAdmin: true)),
  _RouteEntry('/settings/footer', (c, s) => const FooterSettingsScreen(), const _Guard(authenticationRequired: true, onlyAdmin: true)),
  _RouteEntry('/settings/displayname', (c, s) => const DisplayNameScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true, onlyAdmin: true)),
  _RouteEntry('/settings/viewsettings', (c, s) => const SettingsHomeScreen(), const _Guard(authorizationRequired: true, onlyAdmin: true)),
  // React's `/settings` (UserCommonSetting.js) only ever rendered a
  // commented-out OpenRouterKeys block behind its header - there's no
  // real content there to port, so this now goes straight to the actual
  // Settings hub instead of showing a near-empty page.
  _RouteEntry('/settings', (c, s) => const SettingsHomeScreen(), const _Guard(authenticationRequired: true, onlyUser: true)),
  _RouteEntry('/settings/taxes&gstpage', (c, s) => const TaxesGstScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/settings/Items', (c, s) => const ItemSettingsScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/settings/users', (c, s) => const ManageUsersScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/addusers', (c, s) => const AddUserScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/addusers/:email', (c, s) => AddUserScreen(editEmail: s.pathParameters['email']), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/batch/save/partpay/:batchTitle/:batchId', (c, s) => _placeholder('Partial Payment Setting', 'course/Components/Partialpaymentsetting.js'), const _Guard(authorizationRequired: true, onlyAdmin: true)),

  // My Company
  _RouteEntry('/admin/mycompany', (c, s) => const MyCompanyScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),

  // Sales / invoices / estimates / POS
  _RouteEntry('/view/salesinvoice', (c, s) => const ViewInvoiceSaleScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/view/estimateinvoice', (c, s) => const EstimateQuotationScreen(), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/addsale', (c, s) => const InvoiceFormScreen(billType: 'SALE'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/addsale/:id', (c, s) => InvoiceFormScreen(billType: 'SALE', invoiceId: s.pathParameters['id']), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/editsale/:id', (c, s) => InvoiceFormScreen(billType: 'SALE', invoiceId: s.pathParameters['id']), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/addestimate', (c, s) => const InvoiceFormScreen(billType: 'ESTIMATE'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/addestimate/:id', (c, s) => InvoiceFormScreen(billType: 'ESTIMATE', invoiceId: s.pathParameters['id']), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/editestimate/:id', (c, s) => InvoiceFormScreen(billType: 'ESTIMATE', invoiceId: s.pathParameters['id']), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/view/POSform', (c, s) => _placeholder('POS Form', 'Sales/InvoicePOS.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),

  // Backup / restore
  _RouteEntry('/admin/backup-shedule', (c, s) => _placeholder('Backup Schedule', 'backupmanager/BackupManager.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/admin/driveCredentials', (c, s) => _placeholder('Drive Backup Keys', 'backupmanager/DriveBackupKeys.js'), const _Guard(authenticationRequired: true, authorizationRequired: true)),
  _RouteEntry('/restore', (c, s) => _placeholder('Restore', 'backupmanager/RestorePage.js'), const _Guard(authenticationRequired: true, sysAndAdmin: true)),

  // ── SysAdmin (SaaS-model login) ──
  _RouteEntry('/viewAll/Admins', (c, s) => _placeholder('All Admins', 'SysAdmin/ViewAdmin.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/viewAll/Trainers', (c, s) => _placeholder('All Trainers', 'SysAdmin/ViewTrainers.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/viewAll/Students', (c, s) => _placeholder('All Students', 'SysAdmin/ViewStudents.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/viewAll/Cashiers', (c, s) => _placeholder('All Cashiers', 'SysAdmin/ViewCashier.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/licenceupload', (c, s) => const SysadminLicenceUploadScreen(), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/getlicence', (c, s) => const DeadRouteStubScreen(reactSource: 'AuthenticationPages/LicenceFileCreation.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/Affiliates', (c, s) => _placeholder('Affiliates', 'SysAdmin/Affiliates.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),
  _RouteEntry('/viewAdmin/profile/:adminemail', (c, s) => _placeholder('Admin Profile', 'SysAdmin/AdminProfileView.js'), const _Guard(authenticationRequired: true, sysAdmin: true)),

  // Missing / catch-all handled separately as errorBuilder.
];

/// `PrivateRoute.js` reads `sessionStorage` synchronously on every render.
/// go_router's `redirect` must be sync too, so this reads a snapshot of
/// auth state that's refreshed via `refreshListenable` whenever
/// SessionManager mutates auth (see AuthChangeNotifier below).
class AuthSnapshot {
  static bool isAuthenticated = false;
  static String? role;
  static Map<String, dynamic> permissions = const {};

  static Future<void> refresh() async {
    isAuthenticated = await SessionManager.instance.isAuthenticated;
    role = await SessionManager.instance.role;
    permissions = await SessionManager.instance.permissions ?? {};
  }
}

class _RedirectToLogin extends StatelessWidget {
  const _RedirectToLogin();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
    return const SizedBox.shrink();
  }
}

/// Paths rendered OUTSIDE `<Route element={<Layout/>}>` in App.js (i.e. no
/// Sidebar/Header chrome). Everything else in `_routes` was nested inside
/// that Layout route and is wrapped in `AppShell` via a `ShellRoute` below.
const _standalonePaths = {
  '/', '/login', '/refresh', '/unauthorized', '/forgot-password',
  '/RegisterInstitute', '/adminRegistration', '/TrainerRegistration',
  '/StudentRegistration', '/LicenceExpired', '/updatePayment',
  '/updatePaypalPayment',
};

GoRoute _buildRoute(_RouteEntry entry) {
  return GoRoute(
    path: entry.path,
    builder: (context, state) {
      final redirect = entry.guard.evaluate(
        isAuthenticated: AuthSnapshot.isAuthenticated,
        role: AuthSnapshot.role,
      );
      if (redirect != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => context.go(redirect));
        return const SizedBox.shrink();
      }
      return entry.builder(context, state);
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    for (final entry in _routes)
      if (_standalonePaths.contains(entry.path)) _buildRoute(entry),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        for (final entry in _routes)
          if (!_standalonePaths.contains(entry.path)) _buildRoute(entry),
      ],
    ),
  ],
  errorBuilder: (context, state) => const MissingScreen(),
);
