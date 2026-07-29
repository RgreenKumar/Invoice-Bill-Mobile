import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/permissions.dart';
import 'items_section_tab_bar.dart';

/// Port of `src/course/Components/CourseView.js` (internally `ViewItem`),
/// routed at `/dashboard/viewitem` - the item catalogue / "View Item"
/// screen, replacing the earlier placeholder `DashboardShellScreen`.
///
/// Preserves:
///  - GET /item/viewAll on load
///  - Auto-selects the LAST item in the response as the initial selection
///    (`filteredCourses[filteredCourses.length - 1]`, not the first)
///  - GET /getItemTransactions?itemName=<name> whenever an item is clicked
///  - Left list rendered in REVERSED order (`.slice().reverse()`)
///  - Tab bar navigating to Category / Unit
///  - canCreate/canEdit/canDelete via getPermission(MODULES.VIEW_ITEM, ...)
///  - "Add Item" button (canCreate) -> /additem, "Edit" (canEdit) ->
///    /edititem/{id}. NOTE: the source's per-row "Delete" button is a
///    dead no-op (closes the menu but never calls an API) - reproduced
///    exactly as a no-op here rather than inventing a delete call.
///  - Transaction table: status dot, colored billType chip
///    (SALE/POS/other), paid/unpaid badge, INR-formatted amount
class ViewItemScreen extends StatefulWidget {
  const ViewItemScreen({super.key});

  @override
  State<ViewItemScreen> createState() => _ViewItemScreenState();
}

class _ViewItemScreenState extends State<ViewItemScreen> {
  List<Map<String, dynamic>> _allItems = [];
  Map<String, dynamic>? _selectedItem;
  bool _loading = false;
  String _searchQuery = '';
  String _txnSearch = '';

  List<Map<String, dynamic>> _transactions = [];
  bool _txnLoading = false;

  bool get _canCreate => getPermission(Modules.viewItem, 'canCreate');
  bool get _canEdit => getPermission(Modules.viewItem, 'canEdit');
  bool get _canDelete => getPermission(Modules.viewItem, 'canDelete');

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/item/viewAll');
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _allItems = list;
        // UX FIX: previously auto-selected `list.last` here, matching the
        // source's desktop master-detail behavior. On mobile that jumped
        // straight into an item's transaction detail, hiding the item
        // list itself - reported as confusing. Now the person lands on
        // the item list and taps to select.
      });
    } catch (e) {
      debugPrint('Failed to fetch items: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchTransactions(String itemName) async {
    if (itemName.isEmpty) return;
    setState(() => _txnLoading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getItemTransactions', queryParameters: {'itemName': itemName});
      setState(() => _transactions = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      setState(() => _transactions = []);
    } finally {
      if (mounted) setState(() => _txnLoading = false);
    }
  }

  void _handleItemClick(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _transactions = [];
    });
    _fetchTransactions('${item['itemName'] ?? ''}');
  }

  dynamic _getSalePrice(Map item) => item['salePrice'] ?? (item['pricing'] as Map?)?['salePrice'];
  dynamic _getPurchasePrice(Map item) => item['purchasePrice'] ?? (item['pricing'] as Map?)?['purchasePrice'];

  List<Map<String, dynamic>> get _filteredItems {
    final reversed = _allItems.reversed.toList();
    return reversed.where((i) => '${i['itemName'] ?? ''}'.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<Map<String, dynamic>> get _filteredTxns {
    final q = _txnSearch.toLowerCase();
    if (q.isEmpty) return _transactions;
    return _transactions.where((t) =>
        '${t['billType'] ?? ''}'.toLowerCase().contains(q) ||
        '${t['invoiceNumber'] ?? ''}'.contains(q) ||
        '${t['partyName'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Items'),
            bottom: const ItemsSectionTabBar(active: 'all'),
            actions: [
              if (_canCreate)
                IconButton(icon: const Icon(Icons.add), tooltip: 'Add Item', onPressed: () => context.go('/item/additem')),
            ],
          ),
          body: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: _itemListPanel()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _detailPanel()),
                  ],
                )
              : (_selectedItem == null
                  ? _itemListPanel()
                  : Column(
                      children: [
                        ListTile(
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setState(() => _selectedItem = null),
                          ),
                          title: Text('${_selectedItem!['itemName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: _detailPanel()),
                      ],
                    )),
        );
      },
    );
  }

  Widget _itemListPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search items...', isDense: true),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                  ? const Center(child: Text('No items found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, i) {
                        final item = _filteredItems[i];
                        final id = item['itemId'] ?? item['id'];
                        final active = (_selectedItem?['itemId'] ?? _selectedItem?['id']) == id;
                        return ListTile(
                          selected: active,
                          title: Text('${item['itemName'] ?? '—'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(10)),
                                child: Text('${item['remainingStock'] ?? '—'}', style: const TextStyle(fontSize: 11, color: Color(0xFF137333))),
                              ),
                              if (_canEdit || _canDelete)
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') context.go('/edititem/$id');
                                    // "delete" intentionally a no-op - see class doc comment.
                                  },
                                  itemBuilder: (context) => [
                                    if (_canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    if (_canDelete) const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                            ],
                          ),
                          onTap: () => _handleItemClick(item),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _detailPanel() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_selectedItem == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Select an item to view transactions', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final salePrice = _getSalePrice(_selectedItem!);
    final purchasePrice = _getPurchasePrice(_selectedItem!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_selectedItem!['itemName'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _metaItem('Sale Price', salePrice != null ? '₹$salePrice (incl)' : '—'),
              _metaItem('Purchase Price', purchasePrice != null ? '₹$purchasePrice' : '-'),
              if (_selectedItem!['category'] != null) _metaItem('Category', '${_selectedItem!['category']}'),
              if (_selectedItem!['unit'] != null)
                _metaItem('Unit', (_selectedItem!['unit'] is Map) ? '${(_selectedItem!['unit'] as Map)['name']}' : '${_selectedItem!['unit']}'),
              _metaItem('Total Items', '${_allItems.length}'),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Text('TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _transactionsTable() {
    if (_txnLoading) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    final rows = _filteredTxns;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No transactions found for this item', style: TextStyle(color: Colors.grey))),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Invoice No')),
          DataColumn(label: Text('Customer/Supplier')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
        ],
        rows: rows.map((txn) {
          final balance = num.tryParse('${txn['balanceAmount']}') ?? 0;
          final isPaid = balance <= 0;
          final billType = '${txn['billType'] ?? ''}';
          final chipColor = billType == 'SALE'
              ? const Color(0xFF1A73E8)
              : billType == 'POS'
                  ? const Color(0xFFE65100)
                  : const Color(0xFF137333);
          final dateStr = txn['invoiceDate'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse('${txn['invoiceDate']}') ?? DateTime.now())
              : '—';
          final amount = txn['totalAmount'] != null
              ? '₹${NumberFormat('#,##0.00', 'en_IN').format(num.tryParse('${txn['totalAmount']}') ?? 0)}'
              : '—';
          return DataRow(cells: [
            DataCell(Icon(Icons.circle, size: 8, color: isPaid ? const Color(0xFF25A265) : const Color(0xFFF0A500))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: chipColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(billType.isEmpty ? '—' : billType, style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.w600)),
            )),
            DataCell(Text('${txn['invoiceNumber'] ?? '—'}')),
            DataCell(Text('${txn['partyName'] ?? '—'}')),
            DataCell(Text(dateStr)),
            DataCell(Text(txn['qty'] != null ? '${txn['qty']} ${(txn['unit'] != null && txn['unit'] != 'NONE') ? txn['unit'] : ''}' : '—')),
            DataCell(Text(amount, style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(isPaid ? 'Paid' : 'Unpaid',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPaid ? const Color(0xFF137333) : const Color(0xFFD93025))),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
