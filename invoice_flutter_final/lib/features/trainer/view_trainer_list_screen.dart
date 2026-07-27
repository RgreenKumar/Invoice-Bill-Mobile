import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/permissions.dart';

/// Port of `src/Trainer/ViewTrainerList.js` (component internally named
/// `ViewSuppliers` - routed at `/view/Trainer`, entirely about
/// "Suppliers", not trainers in the LMS sense - preserved as-is, mirrors
/// `ViewStudentListScreen` almost exactly but against MODULES.PARTIES and
/// the `/getSuppliers` endpoint instead of MODULES.CUSTOMER + `/getCustomers`).
///
/// Preserves:
///  - GET /getSuppliers on mount
///  - GET /getPartyTransactions?partyName=<name> per supplier (list
///    balances) and again for the selected supplier's transaction table
///  - DELETE /deleteBill/{id} with a confirm dialog
///  - canCreate/canEdit/canDelete gated by getPermission(MODULES.PARTIES, ...)
///  - Paid/Unpaid/All filter, search-by-name, search-within-transactions
///  - "Add Supplier" -> /addSupplier, edit pencil -> /editSupplier/{id}
class ViewTrainerListScreen extends StatefulWidget {
  const ViewTrainerListScreen({super.key});

  @override
  State<ViewTrainerListScreen> createState() => _ViewTrainerListScreenState();
}

class _ViewTrainerListScreenState extends State<ViewTrainerListScreen> {
  List<Map<String, dynamic>> _suppliers = [];
  Map<String, dynamic>? _selectedSupplier;
  List<Map<String, dynamic>> _transactions = [];
  final Map<dynamic, num> _balanceMap = {};

  bool _loading = false;
  bool _txnLoading = false;
  String _searchQuery = '';
  String _txnSearch = '';
  String _filterOption = 'All';

  bool get _canCreate => getPermission(Modules.parties, 'canCreate');
  bool get _canEdit => getPermission(Modules.parties, 'canEdit');
  bool get _canDelete => getPermission(Modules.parties, 'canDelete');

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getSuppliers');
      final list = (res.data is List ? res.data as List : []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => _suppliers = list);
      _fetchAllBalances(list);
      if (list.isNotEmpty && _selectedSupplier == null) {
        _handleSupplierClick(list.first);
      }
    } catch (e) {
      debugPrint('Failed to fetch suppliers: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchAllBalances(List<Map<String, dynamic>> suppliers) async {
    await Future.wait(suppliers.map((s) async {
      try {
        final res = await ApiClient.instance.dio
            .get('/getPartyTransactions', queryParameters: {'partyName': s['name']});
        final data = res.data is List ? res.data as List : (res.data?['content'] as List? ?? []);
        final total = data.fold<num>(0, (sum, t) => sum + (num.tryParse('${t['balanceAmount']}') ?? 0));
        _balanceMap[s['id']] = total;
      } catch (_) {
        _balanceMap[s['id']] = 0;
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

  void _handleSupplierClick(Map<String, dynamic> supplier) {
    setState(() {
      _selectedSupplier = supplier;
      _transactions = [];
    });
    _fetchTransactions('${supplier['name']}');
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
      _fetchTransactions('${_selectedSupplier?['name']}');
      _fetchAllBalances(_suppliers);
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

  List<Map<String, dynamic>> get _filteredSuppliers => _suppliers
      .where((s) => '${s['name'] ?? ''}'.toLowerCase().contains(_searchQuery.toLowerCase()))
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
    // BUGFIX: "Add Supplier" used to live only inside the detail panel's
    // header, which meant it was unreachable whenever no supplier was
    // selected yet (e.g. an empty supplier list) - exactly the reported
    // "there is no add supplier button" bug. A FloatingActionButton is
    // now attached to every branch below so it's always visible.
    final fab = _canCreate
        ? FloatingActionButton.extended(
            onPressed: () => context.go('/addSupplier'),
            icon: const Icon(Icons.add),
            label: const Text('Add Supplier'),
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
                SizedBox(width: 320, child: _supplierListPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: _detailPanel(isWide: true)),
              ],
            ),
          );
        }
        if (_selectedSupplier == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Suppliers')),
            floatingActionButton: fab,
            body: _supplierListPanel(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedSupplier = null),
            ),
            title: Text('${_selectedSupplier!['name'] ?? ''}'),
          ),
          floatingActionButton: fab,
          body: _detailPanel(isWide: false),
        );
      },
    );
  }

  Widget _supplierListPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Suppliers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Chip(label: Text('${_filteredSuppliers.length}')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search supplier name...',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSuppliers.isEmpty
                  ? const Center(child: Text('No suppliers found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filteredSuppliers.length,
                      itemBuilder: (context, i) {
                        final s = _filteredSuppliers[i];
                        final isSelected = _selectedSupplier?['id'] == s['id'];
                        final balance = isSelected ? _totalBalance : (_balanceMap[s['id']] ?? 0);
                        return ListTile(
                          selected: isSelected,
                          title: Text('${s['name'] ?? ''}'),
                          trailing: Text(
                            balance.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: balance > 0 ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                            ),
                          ),
                          onTap: () => _handleSupplierClick(s),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _detailPanel({required bool isWide}) {
    if (_selectedSupplier == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Select a supplier to view details', style: TextStyle(color: Colors.grey)),
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
                    Text('${_selectedSupplier!['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => context.go('/editSupplier/${_selectedSupplier!['id']}'),
                      ),
                  ],
                )
              else if (_canEdit)
                TextButton.icon(
                  onPressed: () => context.go('/editSupplier/${_selectedSupplier!['id']}'),
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
                      onPressed: () => context.go('/addSupplier'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Supplier'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isWide ? 200 : double.infinity,
                child: _summaryCard('TOTAL PURCHASES', _totalGrandTotal, const Color(0xFF1A73E8)),
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
