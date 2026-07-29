import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/session/session_manager.dart';
import '../../core/state/global_state_provider.dart';
import 'support_chart.dart';

/// Port of `src/AuthenticationPages/Dashboard.js`.
///
/// IMPORTANT: in the original source, BOTH data-fetching `useEffect`
/// blocks (the ADMIN one hitting `/course/countcourse`, `/dashboard/storage`,
/// `/dashboard/StudentSats`, `/dashboard/trainerSats`, and the SYSADMIN one
/// hitting `/sysadmin/dashboard[/institution]` + `/ViewAll/Admins`) are
/// commented out (dead code) - so every stat on this screen currently
/// renders its zero/empty default in the live React app. This port
/// preserves that exact (non-fetching) behavior rather than "fixing" it
/// by wiring up the endpoints; do that only if explicitly asked to restore
/// the original intent rather than the current shipped behavior.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _currency;

  // Same shape/defaults as the React useState calls.
  final Map<String, dynamic> _countDetails = {
    'coursecount': '', 'trainercount': '', 'usercount': '',
    'availableseats': '', 'paidcourse': '', 'amountRecived': '',
  };
  final List<Map<String, dynamic>> _trainerFest = [
    {'name': '', 'profile': null, 'freeCourses': '', 'paidCourses': '', 'totalStudents': ''}
  ];
  final List<Map<String, dynamic>> _studentFest = [
    {'name': '', 'profile': null, 'freeCourses': '', 'paidCourses': '', 'totalStudents': '', 'pending': ''}
  ];
  final List<Map<String, dynamic>> _studentFestSysAdmin = [
    {'name': '', 'batchName': '', 'courseName': '', 'amount': ''}
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final c = await SessionManager.instance.currency;
    if (mounted) setState(() => _currency = c);
  }

  num _n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final role = AuthSnapshot.role;
    final displayname = context.watch<GlobalStateProvider>().displayname;
    final isSysAdmin = role == 'SYSADMIN';
    final currencyIcon = _currency == 'INR' ? Icons.currency_rupee : Icons.attach_money;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          isSysAdmin
              ? _sysAdminBody(context, currencyIcon)
              : _adminBody(context, currencyIcon, displayname),
        ],
      ),
    );
  }

  Widget _adminBody(BuildContext context, IconData currencyIcon, Map<String, dynamic> displayname) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kpiStrip(context, [
          _Kpi(Icons.menu_book, Colors.amber, '${_countDetails['coursecount'] ?? 0}', 'Total Courses',
              onTap: () => context.go('/dashboard/viewitem')),
          _Kpi(Icons.people, Colors.red, '${_countDetails['usercount'] ?? 0}',
              (displayname['student_name'] as String?)?.isNotEmpty == true
                  ? displayname['student_name'] : 'Students',
              onTap: () => context.go('/view/Students')),
          _Kpi(Icons.verified_user, Colors.blueGrey, '${_countDetails['trainercount'] ?? 0}',
              (displayname['trainer_name'] as String?)?.isNotEmpty == true
                  ? displayname['trainer_name'] : 'Trainers',
              onTap: () => context.go('/view/Trainer')),
          _Kpi(Icons.grid_view, Colors.green, '${_countDetails['availableseats'] ?? 0}', 'Available Seats'),
          _Kpi(currencyIcon, Colors.blue, '${_countDetails['amountRecived'] ?? 0}', 'Total Revenue', dark: true),
        ]),
        const SizedBox(height: 24),
        _card(
          context,
          title: 'Revenue Overview',
          subtitle: 'Course payment trends',
          child: SupportChart(data: [
            0, _n(_countDetails['paidcourse']), _n(_countDetails['trainercount']),
            _n(_countDetails['coursecount']), 0,
          ]),
        ),
        const SizedBox(height: 24),
        _card(
          context,
          title: 'Parties',
          subtitle: 'Active trainer overview',
          action: TextButton(onPressed: () => context.go('/view/Trainer'), child: const Text('View all')),
          child: _table(['Name', 'Paid', 'Free', 'Students'], _trainerFest.map((t) => [
                '${t['name'] ?? '—'}', '${t['paidCourses'] ?? 0}', '${t['freeCourses'] ?? 0}', '${t['totalStudents'] ?? 0}',
              ]).toList()),
        ),
        const SizedBox(height: 24),
        _card(
          context,
          title: (displayname['student_name'] as String?)?.isNotEmpty == true
              ? displayname['student_name'] as String : 'Students',
          subtitle: 'Enrollment summary',
          action: TextButton(onPressed: () => context.go('/view/Students'), child: const Text('View all')),
          child: _table(['Name', 'Paid', 'Free', 'Pending'], _studentFest.map((s) => [
                '${s['name'] ?? '—'}', '${s['paidCourses'] ?? 0}', '${s['freeCourses'] ?? 0}', '${s['pending'] ?? 0}',
              ]).toList()),
        ),
      ],
    );
  }

  Widget _sysAdminBody(BuildContext context, IconData currencyIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kpiStrip(context, [
          _Kpi(Icons.menu_book, Colors.amber, '${_countDetails['coursecount'] ?? 0}', 'Courses'),
          _Kpi(Icons.people, Colors.red, '${_countDetails['usercount'] ?? 0}', 'Students'),
          _Kpi(Icons.verified_user, Colors.blueGrey, '${_countDetails['trainercount'] ?? 0}', 'Trainers'),
          _Kpi(currencyIcon, Colors.blue, '${_countDetails['amountRecived'] ?? 0}', 'Revenue', dark: true),
        ]),
        const SizedBox(height: 24),
        _card(
          context,
          title: 'Revenue Overview',
          subtitle: 'Payment trends across institutions',
          child: SupportChart(data: [
            0, _n(_countDetails['paidcourse']), _n(_countDetails['trainercount']),
            _n(_countDetails['coursecount']), 0,
          ]),
        ),
        const SizedBox(height: 24),
        _card(
          context,
          title: 'Recent Payments',
          subtitle: 'Student payment records',
          child: _table(['Name', 'Batch', 'Course', 'Amount'], _studentFestSysAdmin.map((s) => [
                '${s['name'] ?? '—'}', '${s['batchName'] ?? '—'}', '${s['courseName'] ?? '—'}', '${s['amount'] ?? 0}',
              ]).toList()),
        ),
      ],
    );
  }

  Widget _kpiStrip(BuildContext context, List<_Kpi> kpis) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis.map((k) {
        return InkWell(
          onTap: k.onTap,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: k.dark ? const Color(0xFF0F2027) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: k.color.withOpacity(0.15), child: Icon(k.icon, color: k.color)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.value,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: k.dark ? Colors.white : Colors.black)),
                      Text(k.label ?? '',
                          style: TextStyle(fontSize: 12, color: k.dark ? Colors.white70 : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _card(BuildContext context,
      {required String title, required String subtitle, required Widget child, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _table(List<String> headers, List<List<String>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows
            .map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList()))
            .toList(),
      ),
    );
  }
}

class _Kpi {
  _Kpi(this.icon, this.color, this.value, this.label, {this.dark = false, this.onTap});
  final IconData icon;
  final Color color;
  final String value;
  final String? label;
  final bool dark;
  final VoidCallback? onTap;
}
