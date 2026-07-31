import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent segmented tab row for the three connected Items screens
/// (`ViewItemScreen`, `CategoryScreen`, `UnitsScreen`).
///
/// UX FIX: previously this lived as the AppBar's `title`, which visually
/// competed with the add-button action and wasn't clearly a navigation
/// control - reported as effectively invisible/lost once a category or
/// unit's detail view took over the screen. It's now rendered as the
/// AppBar's `bottom`, a dedicated always-visible row directly under the
/// title, present on every layout branch (list view AND detail view,
/// wide AND narrow) so switching between All Items / Category / Unit is
/// always one tap away.
class ItemsSectionTabBar extends StatelessWidget implements PreferredSizeWidget {
  const ItemsSectionTabBar({super.key, required this.active});

  /// 'all' | 'category' | 'unit'
  final String active;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _segment(context, 'All Items', 'all', '/dashboard/viewitem'),
            const SizedBox(width: 8),
            _segment(context, 'Category', 'category', '/dashboard/category'),
            const SizedBox(width: 8),
            _segment(context, 'Unit', 'unit', '/dashboard/unit'),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, String label, String key, String path) {
    final isActive = key == active;
    return Material(
      color: isActive ? Colors.white.withOpacity(0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isActive ? null : () => context.go(path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
