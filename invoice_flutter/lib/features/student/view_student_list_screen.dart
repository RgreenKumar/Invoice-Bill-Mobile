import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/permissions.dart';

/// Port of `src/Student/ViewStudentList.js` (component internally named
/// `ViewCustomers` - the file is imported as `ViewStudentList` and routed
/// at `/view/Students`, and its UI/API calls are entirely about
/// "Customers", not students in the LMS sense - preserved as-is).
///
/// Preserves:
///  - GET /getCustomers on mount
///  - GET /getPartyTransactions?partyName=<name> per customer, to compute
///    each row's outstanding balance for the list, and again for the
///    selected customer's full transaction table
///  - DELETE /deleteBill/{id} with a confirm dialog
///  - canCreate/canEdit/canDelete gated by getPermission(MODULES.CUSTOMER, ...)
///  - Paid/Unpaid/All filter, search-by-name, search-within-transactions
///  - Totals footer row (grand total + balance) across filtered transactions
class ViewStudentListScreen extends StatefulWidget {
  const ViewStudentListScreen({super.key});

  @override
  State<ViewStudentListScreen> createState() => _ViewStudentListScreenState();
}

class _ViewStudentListScreenState extends State<ViewStudentListScreen> {
  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _transactions = [];
  final Map<dynamic, num> _balanceMap = {};

  bool _loading = false;
  bool _txnLoading = false;
  String _searchQuery = '';
  String _txnSearch = '';
  String _filterOption = 'All';

  bool get _canCreate => getPermission(Modules.customer, 'canCreate');
  bool get _canEdit => getPermission(Modules.customer, 'canEdit');
  bool get _canDelete => getPermission(Modules.customer, 'canDelete');

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getCustomers');
      final list = (res.data is List ? res.data as List : []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => _customers = list);
      _fetchAllBalances(list);
      if (list.isNotEmpty && _selectedCustomer == null) {
        _handleCustomerClick(list.first);
      }
    } catch (e) {
      debugPrint('Failed to fetch customers: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchAllBalances(List<Map<String, dynamic>> customers) async {
    await Future.wait(customers.map((c) async {
      try {
        final res = await ApiClient.instance.dio
            .get('/getPartyTransactions', queryParameters: {'partyName': c['name']});
        final data = res.data is List ? res.data as List : (res.data?['content'] as List? ?? []);
        final total = data.fold<num>(0, (sum, t) => sum + (num.tryParse('${t['balanceAmount']}') ?? 0));
        _balanceMap[c['id']] = total;
      } catch (_) {
        _balanceMap[c['id']] = 0;
      }
    }));
    if (mounted) setState(() {});
  }

  Future<void> _fetchTransactions(String partyName) async {
    if (partyName.isEmpty) return;
    setState(() => _txnLoading = true);
    try {
      final res = await ApiClient.instance.dio
          .get('/getPartyTransactions', queryParameters: {'partyName': partyName});
      final data = res.data is List ? res.data as List : (res.data?['content'] as List? ?? []);
      setState(() => _transactions = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      debugPrint('Failed to fetch transactions: $e');
      setState(() => _transactions = []);
    } finally {
      if (mounted) setState(() => _txnLoading = false);
    }
  }

  void _handleCustomerClick(Map<String, dynamic> customer) {
    setState(() {
      _selectedCustomer = customer;
      _transactions = [];
    });
    _fetchTransactions('${customer['name']}');
  }

  Future<void> _handleDeleteTxn(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.dio.delete('/deleteBill/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully.')));
      }
      _fetchTransactions('${_selectedCustomer?['name']}');
      _fetchAllBalances(_customers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to delete transaction.')));
      }
    }
  }

  String _getViewPath(Map<String, dynamic> txn) => txn['billType'] == 'ESTIMATE'
      ? '/addestimate/${txn['id']}'
      : '/addsale/${txn['id']}';

  String _getEditPath(Map<String, dynamic> txn) => txn['billType'] == 'ESTIMATE'
      ? '/editestimate/${txn['id']}'
      : '/editsale/${txn['id']}';

  List<Map<String, dynamic>> get _filteredCustomers => _customers
      .where((c) => '${c['name'] ?? ''}'.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  List<Map<String, dynamic>> get _filteredTxns {
    var list = _transactions.where((t) {
      final bal = num.tryParse('${t['balanceAmount']}') ?? 0;
      if (_filterOption == 'Paid') return bal <= 0;
      if (_filterOption == 'Unpaid') return bal > 0;
      return true;
    }).toList();
    if (_txnSearch.isNotEmpty) {
      final q = _txnSearch.toLowerCase();
      list = list.where((t) =>
          '${t['billType'] ?? ''}'.toLowerCase().contains(q) ||
          '${t['invoiceNumber'] ?? ''}'.contains(q)).toList();
    }
    return list;
  }

  num get _totalBalance =>
      _transactions.fold<num>(0, (s, t) => s + (num.tryParse('${t['balanceAmount']}') ?? 0));
  num get _totalGrandTotal =>
      _transactions.fold<num>(0, (s, t) => s + (num.tryParse('${t['grandTotal']}') ?? 0));

  @override
  Widget build(BuildContext context) {
    // MOBILE-FIRST: below 700px, show list OR detail (one at a time,
    // with a back button) instead of the desktop side-by-side split.
    //
    // Same fix applied to ViewTrainerListScreen for "Add Supplier": a
    // persistent FAB so "Add Customer" is reachable even with an empty
    // list / no selection.
    final fab = _canCreate
        ? FloatingActionButton.extended(
            onPressed: () => context.go('/addCustomer'),
            icon: const Icon(Icons.add),
            label: const Text('Add Customer'),
            backgroundColor: const Color(0xFFE74C3C),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        if (isWide) {
          return Scaffold(
            floatingActionButton: fab,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: _customerListPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: _detailPanel(isWide: true)),
              ],
            ),
          );
        }
        if (_selectedCustomer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customers')),
            floatingActionButton: fab,
            body: _customerListPanel(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedCustomer = null),
            ),
            title: Text('${_selectedCustomer!['name'] ?? ''}'),
          ),
          floatingActionButton: fab,
          body: _detailPanel(isWide: false),
        );
      },
    );
  }

  Widget _customerListPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Chip(label: Text('${_filteredCustomers.length}')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search customer name...',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCustomers.isEmpty
                  ? const Center(child: Text('No customers found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, i) {
                        final c = _filteredCustomers[i];
                        final isSelected = _selectedCustomer?['id'] == c['id'];
                        final balance = isSelected ? _totalBalance : (_balanceMap[c['id']] ?? 0);
                        return ListTile(
                          selected: isSelected,
                          title: Text('${c['name'] ?? ''}'),
                          trailing: Text(
                            balance.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: balance > 0 ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                            ),
                          ),
                          onTap: () => _handleCustomerClick(c),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _detailPanel({required bool isWide}) {
    if (_selectedCustomer == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Select a customer to view details', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              if (isWide)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_selectedCustomer!['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => context.go('/editCustomer/${_selectedCustomer!['id']}'),
                      ),
                  ],
                )
              else if (_canEdit)
                TextButton.icon(
                  onPressed: () => context.go('/editCustomer/${_selectedCustomer!['id']}'),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _filterOption,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                    ],
                    onChanged: (v) => setState(() => _filterOption = v ?? 'All'),
                  ),
                  if (_canCreate)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/addCustomer'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Customer'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // MOBILE-FIRST: Wrap instead of a fixed 3-column Row so summary
          // cards stack naturally on narrow screens instead of overflowing.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isWide ? 200 : double.infinity,
                child: _summaryCard('TOTAL SALES', _totalGrandTotal, const Color(0xFF1A73E8)),
              ),
              SizedBox(
                width: isWide ? 200 : double.infinity,
                child: _summaryCard('OUTSTANDING BALANCE', _totalBalance,
                    _totalBalance > 0 ? const Color(0xFFE74C3C) : const Color(0xFF27AE60)),
              ),
              SizedBox(
                width: isWide ? 200 : double.infinity,
                child: _summaryCardText('TRANSACTIONS', '${_transactions.length}', const Color(0xFFAAAAAA)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Text('Transactions Details', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(isDense: true, hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 16)),
                  onChanged: (v) => setState(() => _txnSearch = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _transactionsTable(),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, num value, Color color) => _summaryCardText(label, value.toStringAsFixed(2), color);

  Widget _summaryCardText(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _transactionsTable() {
    if (_txnLoading) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    final rows = _filteredTxns;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey))),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Invoice Number')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Total Amount')),
          DataColumn(label: Text('Balance / Unused')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('')),
        ],
        rows: rows.map((txn) {
          final bal = num.tryParse('${txn['balanceAmount']}') ?? 0;
          final isPaid = bal <= 0;
          return DataRow(cells: [
            DataCell(Text('${txn['billType'] ?? '—'}')),
            DataCell(Text('${txn['invoiceNumber'] ?? '—'}')),
            DataCell(Text('${txn['invoiceDate'] ?? '—'}')),
            DataCell(Text('${txn['grandTotal'] ?? '—'}')),
            DataCell(Text(bal.toStringAsFixed(2),
                style: TextStyle(color: isPaid ? const Color(0xFF27AE60) : const Color(0xFFE74C3C)))),
            DataCell(Text(txn['billType'] == 'ESTIMATE' ? '—' : (isPaid ? 'Paid' : 'Unpaid'))),
            DataCell(PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'view') context.go(_getViewPath(txn));
                if (v == 'edit') context.go(_getEditPath(txn));
                if (v == 'delete') _handleDeleteTxn(txn['id']);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                const PopupMenuItem(value: 'print', child: Text('Print')),
                if (_canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (_canDelete) const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
