import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/session/session_manager.dart';
import '../../core/state/global_state_provider.dart';
import '../../theme/app_theme.dart';
import 'notification_panel.dart';

/// Port of `src/Common Components/Header.js`.
///
/// Preserves:
///  - GET /Edit/profiledetails on load (name + profileImage), cached
///  - GET /unreadCount on load (skipped for SYSADMIN)
///  - GET /getLowStockItems on load (skipped for SYSADMIN), feeds the
///    warning badge on the bell icon (via GlobalStateProvider.lowStockItems)
///  - POST /logoutuser + sessionStorage.clear() + localStorage.clear() on
///    logout, with a confirmation dialog (SweetAlert2 -> AlertDialog)
///  - Profile dropdown: "Profile" (hidden for SYSADMIN) + "Logout"
class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _AppHeaderState extends State<AppHeader> {
  Map<String, dynamic> _profile = {'name': '', 'profileImage': null};
  int _unreadCount = 0;
  bool _notifOpen = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchUnreadCount();
    _fetchLowStock();
  }

  Future<void> _loadProfile() async {
    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/Edit/profiledetails');
      if (res.statusCode == 200) {
        setState(() => _profile = Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchUnreadCount() async {
    final role = AuthSnapshot.role;
    final token = await SessionManager.instance.token;
    if (role == 'SYSADMIN' || token == null) return;
    try {
      final res = await ApiClient.instance.dio.get('/unreadCount');
      if (res.statusCode == 200) {
        setState(() => _unreadCount = res.data is int ? res.data as int : int.tryParse('${res.data}') ?? 0);
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> _fetchLowStock() async {
    final role = AuthSnapshot.role;
    final token = await SessionManager.instance.token;
    if (token == null || role == 'SYSADMIN') return;
    if (!mounted) return;
    try {
      final res = await ApiClient.instance.dio.get('/getLowStockItems');
      if (!mounted) return;
      context.read<GlobalStateProvider>().setLowStockItems(res.data as List<dynamic>);
    } catch (e) {
      debugPrint('Low stock fetch failed: $e');
    }
  }

  Future<void> _markAllAsRead(List<dynamic> notificationIds) async {
    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.post('/MarkAllASRead', data: notificationIds);
      if (res.statusCode == 200) _fetchUnreadCount();
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await SessionManager.instance.token;
    if (token == null) return;
    try {
      final res = await ApiClient.instance.dio.post('/logoutuser');
      if (res.statusCode == 200) {
        await SessionManager.instance.clear();
        await AuthSnapshot.refresh();
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error!'),
            content: const Text('An error occurred while logging out. Please try again later.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthSnapshot.role;
    final itemSettings = context.watch<GlobalStateProvider>().itemSettings;
    final lowStockItems = context.watch<GlobalStateProvider>().lowStockItems;
    final showLowStockWarning = itemSettings['showLowStockDialog'] == true && lowStockItems.isNotEmpty;

    final name = (_profile['name'] as String?)?.isNotEmpty == true ? _profile['name'] as String : 'Admin';
    final displayName = name.length > 15 ? '${name.substring(0, 15)}…' : name;
    final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return AppBar(
      backgroundColor: AppColors.darkMid,
      // Mobile-first: AppShell always provides a Drawer now, so let the
      // AppBar auto-generate its hamburger menu icon instead of hiding it.
      automaticallyImplyLeading: true,
      title: GestureDetector(
        onTap: () => context.go('/admin/dashboard'),
        child: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.white),
            const SizedBox(width: 8),
            const Text('InvoiceBill', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
      actions: [
        if (role != 'SYSADMIN')
          PopupMenuButton<void>(
            icon: Badge(
              isLabelVisible: showLowStockWarning || _unreadCount > 0,
              label: Text(showLowStockWarning ? '!' : (_unreadCount > 99 ? '99+' : '$_unreadCount')),
              backgroundColor: showLowStockWarning ? Colors.orange : Colors.red,
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onOpened: () {
              setState(() => _notifOpen = true);
              _fetchUnreadCount();
              _fetchLowStock();
            },
            onCanceled: () => setState(() => _notifOpen = false),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                child: SizedBox(
                  width: 340,
                  child: NotificationPanel(onMarkAllAsRead: _markAllAsRead),
                ),
              ),
            ],
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'profile') context.go('/course/dashboard/profile');
            if (value == 'logout') _handleLogout();
          },
          itemBuilder: (context) => [
            if (role != 'SYSADMIN')
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  backgroundImage: _profile['profileImage'] != null
                      ? MemoryImage(_decodeBase64('${_profile['profileImage']}'))
                      : null,
                  child: _profile['profileImage'] == null
                      ? Text(firstLetter, style: const TextStyle(color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 8),
                Text(displayName, style: const TextStyle(color: Colors.white)),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Uint8List _decodeBase64(String data) {
  try {
    return const Base64Decoder().convert(data);
  } catch (_) {
    return Uint8List(0);
  }
}
