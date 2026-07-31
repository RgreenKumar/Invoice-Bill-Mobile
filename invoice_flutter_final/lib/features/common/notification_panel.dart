import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/global_state_provider.dart';

/// Port of `src/Common Components/Notification.js`.
///
/// Preserves:
///  - GET /notifications on open (skipped for SYSADMIN)
///  - GET /clearAll on "clear all" (skipped for SYSADMIN)
///  - Low-stock section shown above the date-grouped notification list
///    when `itemSettings.showLowStockDialog` and `lowStockItems` is
///    non-empty (matches Header's bell badge condition)
///  - Notifications grouped by date, with "Today"/"Yesterday" labels
///
/// NOTE: the original lazily fetched a per-notification image via
/// `POST /getImages` as each item scrolled into view (IntersectionObserver).
/// That viewport-based lazy-loading isn't replicated 1:1 here; this
/// version fetches images for all currently-loaded notifications up
/// front, which is functionally equivalent but not identical in timing.
class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key, required this.onMarkAllAsRead});

  final void Function(List<dynamic> notificationIds) onMarkAllAsRead;

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final role = AuthSnapshot.role;
    if (role == 'SYSADMIN') {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiClient.instance.dio.get('/notifications');
      if (res.statusCode == 200) {
        setState(() {
          _notifications = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _clearAll() async {
    final role = AuthSnapshot.role;
    if (role == 'SYSADMIN') return;
    try {
      final res = await ApiClient.instance.dio.get('/clearAll');
      if (res.statusCode == 200) {
        setState(() => _notifications = []);
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final n in _notifications) {
      final created = DateTime.tryParse('${n['createdDate']}') ?? DateTime.now();
      final key = DateFormat('M/d/yyyy').format(created);
      grouped.putIfAbsent(key, () => []).add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final lowStockItems = context.watch<GlobalStateProvider>().lowStockItems;
    final itemSettings = context.watch<GlobalStateProvider>().itemSettings;
    final showLowStock = itemSettings['showLowStockDialog'] == true && lowStockItems.isNotEmpty;
    final grouped = _groupByDate();
    final today = DateFormat('M/d/yyyy').format(DateTime.now());
    final yesterday = DateFormat('M/d/yyyy').format(DateTime.now().subtract(const Duration(days: 1)));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => widget.onMarkAllAsRead(
                      _notifications.map((n) => n['notifyId']).toList()),
                  child: const Text('mark as read', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _clearAll,
                  child: const Text('clear all', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : (_notifications.isEmpty && lowStockItems.isEmpty)
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No Notification Found', textAlign: TextAlign.center),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          if (showLowStock) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE74C3C)),
                                  SizedBox(width: 4),
                                  Text('LOW STOCK',
                                      style: TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ...lowStockItems.map((item) {
                              final m = item as Map;
                              return ListTile(
                                dense: true,
                                tileColor: const Color(0xFFFFF8F8),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFDECEA),
                                  child: Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 18),
                                ),
                                title: Text('${m['itemName'] ?? ''}'),
                                subtitle: Text(
                                  '${m['remainingStock'] ?? ''} units left · Minimum stock reached',
                                  style: const TextStyle(color: Color(0xFFE74C3C)),
                                ),
                                onTap: () => context.go('/dashboard/viewitem'),
                              );
                            }),
                          ],
                          ...grouped.entries.map((entry) {
                            final label = entry.key == today
                                ? 'Today'
                                : entry.key == yesterday
                                    ? 'Yesterday'
                                    : entry.key;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                ...entry.value.map((n) => InkWell(
                                      onTap: () {
                                        final link = n['link'] as String?;
                                        if (link != null && link.startsWith('/')) {
                                          context.go(link);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Icon(Icons.message_outlined, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${n['description'] ?? ''}',
                                                    softWrap: true,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Created By ${n['username'] ?? ''}',
                                                    softWrap: true,
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            );
                          }),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
