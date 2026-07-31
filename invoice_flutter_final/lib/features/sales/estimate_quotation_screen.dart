import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/permissions.dart';

/// Port of `src/Sales/EstimateQuotation.js` (internally
/// `ViewSaleInvoices`-shaped, routed at `/view/estimateinvoice`).
///
/// Structurally identical to `ViewInvoiceSaleScreen` (same source file
/// family, same layout/filters/summary-card/table), with these real
/// differences confirmed against the source:
///  - `getPermission(MODULES.ESTIMATE_QUOTATION, ...)` instead of
///    `MODULES.SALE_INVOICE`
///  - `billTypes=ESTIMATE` instead of `SALE,POS`
///  - "Add Estimate" -> `/addestimate`, View -> `/addestimate/{id}`,
///    Edit -> `/editestimate/{id}`
///  - Title "Estimate Quotation" / summary card "Total Estimate Amount"
///
/// Same caveats as `ViewInvoiceSaleScreen`: the source's View modal is
/// dead code (not reproduced), and PDF download fetches bytes but
/// doesn't yet save/open them on-device.
class EstimateQuotationScreen extends StatefulWidget {
  const EstimateQuotationScreen({super.key});

  @override
  State<EstimateQuotationScreen> createState() => _EstimateQuotationScreenState();
}

class _EstimateQuotationScreenState extends State<EstimateQuotationScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = false;
  String _searchQuery = '';
  String _filterMonth = 'All Estimates';
  String _filterUser = 'All Users';
  DateTime _dateFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dateTo = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  num _totalSales = 0;
  num _received = 0;
  num _balance = 0;

  static const _monthOptions = ['All Estimates', 'This Month', 'Last Month', 'This Year'];
  static const _userOptions = ['All Users', 'Admin', 'Cashier'];

  bool get _canCreate => getPermission(Modules.estimateQuotation, 'canCreate');
  bool get _canEdit => getPermission(Modules.estimateQuotation, 'canEdit');
  bool get _canDelete => getPermission(Modules.estimateQuotation, 'canDelete');

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_filterMonth == 'All Estimates') {
        params['fromDate'] = '2000-01-01';
        params['toDate'] = '2099-12-31';
      } else {
        params['fromDate'] = _dateFrom.toIso8601String().split('T').first;
        params['toDate'] = _dateTo.toIso8601String().split('T').first;
      }
      if (_filterUser != 'All Users') params['createdBy'] = _filterUser;
      params['billTypes'] = 'ESTIMATE';

      final res = await ApiClient.instance.dio.get('/getBillsFiltered', queryParameters: params);
      final data = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      data.sort((a, b) {
        final da = DateTime.tryParse('${a['invoiceDate']}') ?? DateTime(2000);
        final db = DateTime.tryParse('${b['invoiceDate']}') ?? DateTime(2000);
        return db.compareTo(da);
      });

      final total = data.fold<num>(0, (s, i) => s + (num.tryParse('${i['grandTotal']}') ?? 0));
      final recv = data.fold<num>(0, (s, i) => s + (num.tryParse('${i['amountReceived']}') ?? 0));
      final bal = data.fold<num>(0, (s, i) => s + (num.tryParse('${i['balanceAmount']}') ?? 0));

      setState(() {
        _invoices = data;
        _totalSales = total;
        _received = recv;
        _balance = bal;
      });
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDateRange(String option) {
    final now = DateTime.now();
    setState(() {
      _filterMonth = option;
      if (option == 'This Month') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0);
      } else if (option == 'Last Month') {
        _dateFrom = DateTime(now.year, now.month - 1, 1);
        _dateTo = DateTime(now.year, now.month, 0);
      } else if (option == 'This Year') {
        _dateFrom = DateTime(now.year, 1, 1);
        _dateTo = DateTime(now.year, 12, 31);
      }
    });
    _fetchInvoices();
  }

  Future<void> _handleDelete(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.dio.delete('/deleteBill/${idParam(id)}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice deleted successfully.')));
      }
      _fetchInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete invoice.')));
      }
    }
  }

  Future<void> _handleDownload(dynamic id, dynamic invoiceNumber) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/downloadBill/${idParam(id)}',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(List<int>.from(res.data as List));
      if (bytes.isEmpty) throw Exception('Empty PDF response');
      // BUGFIX: see the identical fix in view_invoice_sale_screen.dart -
      // this previously never actually delivered the PDF anywhere.
      await Printing.sharePdf(bytes: bytes, filename: 'Estimate_$invoiceNumber.pdf');
    } catch (e) {
      debugPrint('Download failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download invoice.')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _invoices;
    return _invoices.where((inv) =>
        '${inv['billType'] ?? ''}'.toLowerCase().contains(q) ||
        '${inv['invoiceNumber'] ?? ''}'.contains(q) ||
        '${inv['partyName'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0', 'en_IN');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate / Quotation'),
        actions: [
          if (_canCreate)
            IconButton(icon: const Icon(Icons.add), tooltip: 'Add Estimate', onPressed: () => context.go('/addestimate')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search Transactions', isDense: true),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DropdownButton<String>(
                  value: _filterMonth,
                  items: _monthOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => v != null ? _applyDateRange(v) : null,
                ),
                DropdownButton<String>(
                  value: _filterUser,
                  items: _userOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) {
                    setState(() => _filterUser = v ?? 'All Users');
                    _fetchInvoices();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Estimate Amount', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text('₹ ${currency.format(_totalSales)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      Text('Received: ₹ ${currency.format(_received)}', style: const TextStyle(fontSize: 12)),
                      Text('Balance: ₹ ${currency.format(_balance)}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? _emptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) => constraints.maxWidth >= 700 ? _table() : _cardList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 56, color: Color(0xFF2F80ED)),
          const SizedBox(height: 16),
          const Text('No Transactions to show', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("You haven't added any transactions yet.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          if (_canCreate)
            ElevatedButton.icon(
              onPressed: () => context.go('/addestimate'),
              icon: const Icon(Icons.add),
              label: const Text('Add Estimate'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
            ),
        ],
      ),
    );
  }

  Widget _cardList() {
    final currency = NumberFormat('#,##0', 'en_IN');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredInvoices.length,
      itemBuilder: (context, i) {
        final inv = _filteredInvoices[i];
        final balance = num.tryParse('${inv['balanceAmount']}') ?? 0;
        final isPaid = balance <= 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => context.go('/addestimate/${inv['id']}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BUGFIX (RenderFlex overflow): Expanded lets the
                      // name/subtitle shrink+ellipsize instead of pushing
                      // the amount column past the card's right edge.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${inv['partyName'] ?? '—'}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${inv['billType'] ?? ''} · #${inv['invoiceNumber'] ?? ''} · ${inv['invoiceDate'] ?? ''}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹ ${currency.format(num.tryParse('${inv['grandTotal']}') ?? 0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(isPaid ? 'Paid' : 'Unpaid',
                              style: TextStyle(fontSize: 11, color: isPaid ? const Color(0xFF137333) : const Color(0xFFD93025))),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Explicit, always-visible action row (was previously
                  // only reachable via a long-press bottom sheet, which
                  // is what made Download seem missing on mobile).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        tooltip: 'View',
                        onPressed: () => context.go('/addestimate/${inv['id']}'),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_outlined, size: 20),
                        tooltip: 'Download',
                        onPressed: () => _handleDownload(inv['id'], inv['invoiceNumber']),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      if (_canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () => context.go('/editestimate/${inv['id']}'),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                        ),
                      if (_canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => _handleDelete(inv['id']),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _table() {
    final currency = NumberFormat('#,##0', 'en_IN');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Invoice No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Party Name')),
          DataColumn(label: Text('Payment Type')),
          DataColumn(label: Text('Amount (₹)')),
          DataColumn(label: Text('Balance (₹)')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: _filteredInvoices.map((inv) {
          final balance = num.tryParse('${inv['balanceAmount']}') ?? 0;
          final isPaid = balance <= 0;
          return DataRow(cells: [
            DataCell(Text('${inv['billType'] ?? '—'}')),
            DataCell(Text('${inv['invoiceNumber'] ?? '—'}')),
            DataCell(Text('${inv['invoiceDate'] ?? '—'}')),
            DataCell(Text('${inv['partyName'] ?? '—'}')),
            DataCell(Text('${inv['paymentMode'] ?? '—'}')),
            DataCell(Text('₹ ${currency.format(num.tryParse('${inv['grandTotal']}') ?? 0)}')),
            DataCell(Text('₹ ${currency.format(balance)}', style: TextStyle(color: isPaid ? const Color(0xFF27AE60) : const Color(0xFFE74C3C)))),
            DataCell(Text(isPaid ? 'Paid' : 'Unpaid')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.visibility, size: 18), onPressed: () => context.go('/addestimate/${inv['id']}')),
              IconButton(icon: const Icon(Icons.download, size: 18), onPressed: () => _handleDownload(inv['id'], inv['invoiceNumber'])),
              if (_canEdit) IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => context.go('/editestimate/${inv['id']}')),
              if (_canDelete) IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => _handleDelete(inv['id'])),
            ])),
          ]);
        }).toList(),
      ),
    );
  }
}
