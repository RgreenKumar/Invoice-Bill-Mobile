import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';

/// Port of `src/AuthenticationPages/useGlobalNavigation.js`.
void globalNavigate(BuildContext context) {
  final role = AuthSnapshot.role;
  if (role == 'ADMIN') {
    context.go('/course/admin/edit');
  } else if (role == 'TRAINER') {
    context.go('/AssignedCourses');
  } else {
    context.go('/unauthorized');
  }
}
