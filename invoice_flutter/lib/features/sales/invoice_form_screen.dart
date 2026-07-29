import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/safe_back.dart';

/// Shared port of `src/Sales/AddSale.js` (billType `SALE`) and
/// `src/Sales/AddEstimate.js` (billType `ESTIMATE`) - the two files are
/// near-identical (same `calcRow` tax/discount math, same item/customer
/// search, same `/saveBill` `/updateBill/{id}` payload shape); the real
/// differences are: AddEstimate has no payment section at all
/// (hardcodes `isCash: true, paymentMode: "Cash", received: false`) and
/// uses `billType: "ESTIMATE"`.
///
/// NOT converted here (per explicit request): `InvoicePOS.js` - the
/// dedicated point-of-sale screen is out of scope for this pass.
///
/// Preserves:
///  - GET /getNextInvoiceNumber for a new bill's invoice number
///  - GET /getBill/{id} to load + edit an existing bill
///  - GET /searchCustomer?keyword=, GET /searchItem?keyword= (2+ chars)
///    autocomplete, with the same auto-fill-from-item logic (MRP items
///    skip GST; sale-price-inclusive-of-tax items get back-calculated
///    to a tax-exclusive price)
///  - Per-row tax/discount math (`calcRow`): gross = qty*price, discount
///    is either % of gross or a manually-typed amount, taxable =
///    gross-discount, CGST/SGST = taxable * (gst/2)/100 each, plus a
///    flat additional-cess-per-unit, row total = taxable+cgst+sgst+cess
///  - SALE-only: "Received" must be checked before saving (source
///    literally blocks save via `alert()` otherwise), payment
///    type+amount, round-off toggle
///  - Validation: at least one item row with a non-empty item name
///  - POST /saveBill (create) or PUT /updateBill/{id} (edit)
///
/// MOBILE-FIRST SIMPLIFICATION (explicit, documented rather than
/// silent): the source supports multiple bill "tabs" open at once - a
/// desktop-oriented workflow. This screen edits one bill at a time. The
/// amount-in-words display and item image upload (also present in the
/// source) are likewise not reproduced here.
class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key, required this.billType, this.invoiceId});

  /// 'SALE' or 'ESTIMATE'
  final String billType;
  final String? invoiceId;
  bool get isEditMode => invoiceId != null;
  bool get isSale => billType == 'SALE';

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _LineItem {
  String item = '';
  String hsn = '';
  String qty = '1';
  String unit = 'NONE';
  String priceWithoutTax = '';
  String discountPct = '';
  String discountAmt = '';
  bool discAmtManual = false;
  String tax = 'Select';
  String addcess = '';
  String mrp = '';
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  static const _taxOptions = ['Select', 'GST 0%', 'GST 5%', 'GST 12%', 'GST 18%', 'GST 28%'];
  static const _prefixOptions = ['NONE', 'INV', 'SALE', 'SI'];
  static const _paymentTypes = ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Cheque'];

  final List<_LineItem> _items = [_LineItem(), _LineItem()];
  final _partyNameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _descriptionCtl = TextEditingController();
  final _termsCtl = TextEditingController(text: 'Thanks for doing business with us!');
  final _receivedAmountCtl = TextEditingController();

  String _invoicePrefix = 'INV';
  int _invoiceNumber = 1;
  DateTime _invoiceDate = DateTime.now();
  String _stateOfSupply = '';
  bool _roundOff = true;
  bool _received = false;
  String _paymentType = 'Cash';
  bool _saving = false;
  bool _loading = false;

  List<Map<String, dynamic>> _customerResults = [];
  int? _activeItemSearchIndex;
  List<Map<String, dynamic>> _itemResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _fetchBill(widget.invoiceId!);
    } else {
      _fetchNextInvoiceNumber();
    }
  }

  @override
  void dispose() {
    _partyNameCtl.dispose();
    _phoneCtl.dispose();
    _descriptionCtl.dispose();
    _termsCtl.dispose();
    _receivedAmountCtl.dispose();
    super.dispose();
  }

  Future<void> _fetchNextInvoiceNumber() async {
    try {
      final res = await ApiClient.instance.dio.get('/getNextInvoiceNumber');
      setState(() => _invoiceNumber = res.data is int ? res.data as int : int.tryParse('${res.data}') ?? 1);
    } catch (e) {
      debugPrint('Failed to fetch invoice number: $e');
    }
  }

  Future<void> _fetchBill(String id) async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getBill/$id');
      final bill = res.data as Map;
      setState(() {
        _partyNameCtl.text = '${bill['partyName'] ?? ''}';
        _phoneCtl.text = '${bill['phoneNo'] ?? ''}';
        _invoicePrefix = '${bill['invoicePrefix'] ?? 'INV'}';
        _invoiceNumber = int.tryParse('${bill['invoiceNumber']}') ?? 1;
        _invoiceDate = DateTime.tryParse('${bill['invoiceDate']}') ?? DateTime.now();
        _stateOfSupply = '${bill['stateOfSupply'] ?? ''}';
        _roundOff = bill['roundOffEnabled'] == true;
        _received = bill['received'] == true;
        _receivedAmountCtl.text = bill['amountReceived'] != null ? '${bill['amountReceived']}' : '';
        _paymentType = '${bill['paymentMode'] ?? 'Cash'}';
        _descriptionCtl.text = '${bill['description'] ?? ''}';
        _termsCtl.text = '${bill['termsConditions'] ?? 'Thanks for doing business with us!'}';

        final rows = (bill['items'] as List?) ?? [];
        _items.clear();
        for (final r in rows) {
          final row = r as Map;
          final taxPct = num.tryParse('${row['taxPct']}') ?? 0;
          _items.add(_LineItem()
            ..item = '${row['itemName'] ?? ''}'
            ..hsn = '${row['hsnCode'] ?? ''}'
            ..qty = '${row['qty'] ?? '1'}'
            ..unit = '${row['unit'] ?? 'NONE'}'
            ..priceWithoutTax = '${row['priceWithoutTax'] ?? ''}'
            ..discountPct = '${row['discountPct'] ?? ''}'
            ..tax = taxPct > 0 ? 'GST $taxPct%' : 'Select'
            ..addcess = row['addCess'] != null ? '${row['addCess']}' : '');
        }
        if (_items.isEmpty) _items.addAll([_LineItem(), _LineItem()]);
      });
    } catch (e) {
      debugPrint('Failed to load bill: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to load invoice. Please try again.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchCustomer(String keyword) async {
    if (keyword.length < 2) {
      setState(() => _customerResults = []);
      return;
    }
    try {
      final res = await ApiClient.instance.dio.get('/searchCustomer', queryParameters: {'keyword': keyword});
      setState(() => _customerResults = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      debugPrint('Customer search failed: $e');
    }
  }

  void _selectCustomer(Map<String, dynamic> c) {
    setState(() {
      _partyNameCtl.text = '${c['name'] ?? ''}';
      _phoneCtl.text = '${c['phone'] ?? ''}';
      if (c['state'] != null) _stateOfSupply = '${c['state']}';
      _customerResults = [];
    });
  }

  Future<void> _searchItem(int rowIndex, String keyword) async {
    if (keyword.length < 2) {
      setState(() => _itemResults = []);
      return;
    }
    try {
      final res = await ApiClient.instance.dio.get('/searchItem', queryParameters: {'keyword': keyword});
      setState(() {
        _activeItemSearchIndex = rowIndex;
        _itemResults = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      debugPrint('Item search failed: $e');
    }
  }

  void _selectItem(int rowIndex, Map<String, dynamic> selected) {
    final mrp = selected['mrp'];
    final taxPct = num.tryParse('${selected['taxPct'] ?? 0}') ?? 0;
    double priceToUse;
    String taxString;

    if (mrp != null && (num.tryParse('$mrp') ?? 0) > 0) {
      priceToUse = num.tryParse('$mrp')!.toDouble();
      taxString = 'Select';
    } else {
      priceToUse = (num.tryParse('${selected['salePrice'] ?? 0}') ?? 0).toDouble();
      taxString = taxPct > 0 ? 'GST ${taxPct}%' : 'Select';
      if (selected['salePriceTaxType'] == 'with_tax' && taxPct > 0) {
        priceToUse = priceToUse / (1 + taxPct / 100);
        priceToUse = (priceToUse * 100).round() / 100;
      }
    }

    setState(() {
      final row = _items[rowIndex];
      row.item = '${selected['itemName'] ?? ''}';
      row.hsn = '${selected['itemHsn'] ?? ''}';
      row.unit = '${selected['unit'] ?? 'NONE'}';
      row.priceWithoutTax = priceToUse.toString();
      row.tax = taxString;
      row.qty = '1';
      row.mrp = mrp != null ? '$mrp' : '';
      row.addcess = selected['additionalCessPerUnit'] != null ? '${selected['additionalCessPerUnit']}' : '';
      row.discountPct = selected['discountOnSale'] != null ? '${selected['discountOnSale']}' : '';
      row.discAmtManual = false;
      _itemResults = [];
      _activeItemSearchIndex = null;
    });
  }

  double _gstPct(String taxStr) {
    if (taxStr == 'Select' || taxStr.isEmpty) return 0;
    return double.tryParse(taxStr.replaceAll('GST ', '').replaceAll('%', '')) ?? 0;
  }

  Map<String, double> _calcRow(_LineItem item) {
    final qty = double.tryParse(item.qty) ?? 0;
    final price = double.tryParse(item.priceWithoutTax) ?? 0;
    final discPct = double.tryParse(item.discountPct) ?? 0;
    final taxPct = _gstPct(item.tax);
    final gross = qty * price;
    final discAmt = item.discAmtManual ? (double.tryParse(item.discountAmt) ?? 0) : (gross * discPct) / 100;
    final taxable = gross - discAmt;
    final cgst = (taxable * (taxPct / 2)) / 100;
    final sgst = (taxable * (taxPct / 2)) / 100;
    final cess = double.tryParse(item.addcess) ?? 0;
    final amount = taxable + cgst + sgst + cess;
    return {'gross': gross, 'discAmt': discAmt, 'taxable': taxable, 'cgst': cgst, 'sgst': sgst, 'amount': amount};
  }

  double get _grandTotal {
    var total = _items.fold<double>(0, (sum, i) => sum + _calcRow(i)['amount']!);
    if (_roundOff) total = total.roundToDouble();
    return total;
  }

  void _addRow() => setState(() => _items.add(_LineItem()));
  void _removeRow(int i) {
    if (_items.length == 1) return;
    setState(() => _items.removeAt(i));
  }

  Future<void> _handleSave() async {
    if (widget.isSale && !_received) {
      _alert('Please check Received before saving the bill.');
      return;
    }
    final filled = _items.where((i) => i.item.trim().isNotEmpty).toList();
    if (filled.isEmpty) {
      _alert('Please add at least one item.');
      return;
    }

    setState(() => _saving = true);
    try {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < filled.length; i++) {
        final item = filled[i];
        rows.add({
          'lineNumber': i + 1,
          'itemName': item.item,
          'itemCode': '',
          'hsnCode': item.hsn.isEmpty ? null : item.hsn,
          'mrp': item.mrp.isEmpty ? null : double.tryParse(item.mrp),
          'addCess': item.addcess.isEmpty ? null : double.tryParse(item.addcess),
          'qty': double.tryParse(item.qty) ?? 0,
          'unit': item.unit,
          'priceWithoutTax': double.tryParse(item.priceWithoutTax) ?? 0,
          'discountPct': double.tryParse(item.discountPct) ?? 0,
          'taxLabel': item.tax != 'Select' ? item.tax : null,
          'taxPct': _gstPct(item.tax),
        });
      }

      final payload = <String, dynamic>{
        'billType': widget.billType,
        'invoiceNumber': _invoiceNumber,
        'invoicePrefix': _invoicePrefix,
        'invoiceDate': _invoiceDate.toIso8601String().split('T').first,
        'partyName': _partyNameCtl.text,
        'phoneNo': _phoneCtl.text,
        'stateOfSupply': _stateOfSupply,
        'isCash': widget.isSale ? (_paymentType == 'Cash') : true,
        'paymentMode': widget.isSale ? _paymentType : 'Cash',
        'roundOffEnabled': _roundOff,
        'received': widget.isSale ? _received : false,
        'amountReceived': widget.isSale && _receivedAmountCtl.text.isNotEmpty ? double.tryParse(_receivedAmountCtl.text) : null,
        'description': _descriptionCtl.text,
        'termsConditions': _termsCtl.text,
        'items': rows,
        'payments': widget.isSale && _receivedAmountCtl.text.isNotEmpty
            ? [{'paymentType': _paymentType, 'amount': double.tryParse(_receivedAmountCtl.text)}]
            : [],
      };

      if (widget.isEditMode) {
        await ApiClient.instance.dio.put('/updateBill/${widget.invoiceId}', data: payload);
      } else {
        await ApiClient.instance.dio.post('/saveBill', data: payload);
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Saved!'),
            content: Text('${widget.isSale ? 'Sale' : 'Estimate'} ${widget.isEditMode ? 'updated' : 'saved'} successfully!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        if (mounted) {
          safeBack(context, fallback: widget.isSale ? '/view/salesinvoice' : '/view/estimateinvoice');
        }
      }
    } on DioException catch (e) {
      debugPrint('Save failed: $e');
      _alert('Failed to save bill. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _alert(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isSale ? 'Sale' : 'Estimate';
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.isEditMode ? 'Edit' : 'Add'} $label'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => safeBack(context, fallback: widget.isSale ? '/view/salesinvoice' : '/view/estimateinvoice'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _invoiceHeaderSection(),
                  const SizedBox(height: 16),
                  _customerSection(),
                  const SizedBox(height: 20),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((e) => _itemRow(e.key, e.value)),
                  TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('Add Row')),
                  const SizedBox(height: 16),
                  if (widget.isSale) ...[_paymentSection(), const SizedBox(height: 16)],
                  _totalsSection(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionCtl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _termsCtl,
                    decoration: const InputDecoration(labelText: 'Terms & Conditions'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.isEditMode ? 'Update' : 'Save'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _invoiceHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                value: _invoicePrefix,
                decoration: const InputDecoration(labelText: 'Prefix'),
                items: _prefixOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _invoicePrefix = v ?? 'INV'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: '$_invoiceNumber'),
                onChanged: (v) => _invoiceNumber = int.tryParse(v) ?? _invoiceNumber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Invoice Date'),
          readOnly: true,
          controller: TextEditingController(text: _invoiceDate.toIso8601String().split('T').first),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: _invoiceDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (date != null) setState(() => _invoiceDate = date);
          },
        ),
      ],
    );
  }

  Widget _customerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _partyNameCtl,
          decoration: const InputDecoration(labelText: 'Party Name'),
          onChanged: _searchCustomer,
        ),
        if (_customerResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
            child: ListView(
              shrinkWrap: true,
              children: _customerResults.map((c) => ListTile(
                    dense: true,
                    title: Text('${c['name'] ?? ''}'),
                    subtitle: Text('${c['phone'] ?? ''}'),
                    onTap: () => _selectCustomer(c),
                  )).toList(),
            ),
          ),
        const SizedBox(height: 12),
        TextField(controller: _phoneCtl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'State of Supply'),
          controller: TextEditingController(text: _stateOfSupply),
          onChanged: (v) => _stateOfSupply = v,
        ),
      ],
    );
  }

  Widget _itemRow(int index, _LineItem item) {
    final calc = _calcRow(item);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Item Name', isDense: true),
                    controller: TextEditingController(text: item.item),
                    onChanged: (v) {
                      item.item = v;
                      _searchItem(index, v);
                    },
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeRow(index)),
              ],
            ),
            if (_activeItemSearchIndex == index && _itemResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
                child: ListView(
                  shrinkWrap: true,
                  children: _itemResults.map((r) => ListTile(
                        dense: true,
                        title: Text('${r['itemName'] ?? ''}'),
                        onTap: () => _selectItem(index, r),
                      )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: item.qty),
                    onChanged: (v) => setState(() => item.qty = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Price', isDense: true),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: item.priceWithoutTax),
                    onChanged: (v) => setState(() => item.priceWithoutTax = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Discount %', isDense: true),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: item.discountPct),
                    onChanged: (v) => setState(() {
                      item.discountPct = v;
                      item.discAmtManual = false;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.tax,
                    decoration: const InputDecoration(labelText: 'Tax', isDense: true),
                    items: _taxOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => item.tax = v ?? 'Select'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Amount: ₹${calc['amount']!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Received'),
          value: _received,
          onChanged: (v) => setState(() => _received = v ?? false),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _paymentType,
                decoration: const InputDecoration(labelText: 'Payment Type'),
                items: _paymentTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _paymentType = v ?? 'Cash'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _receivedAmountCtl,
                decoration: const InputDecoration(labelText: 'Amount Received'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Round Off'),
          value: _roundOff,
          onChanged: (v) => setState(() => _roundOff = v ?? true),
        ),
      ],
    );
  }

  Widget _totalsSection() {
    final subTotal = _items.fold<double>(0, (s, i) => s + _calcRow(i)['gross']!);
    final discount = _items.fold<double>(0, (s, i) => s + _calcRow(i)['discAmt']!);
    final cgst = _items.fold<double>(0, (s, i) => s + _calcRow(i)['cgst']!);
    final sgst = _items.fold<double>(0, (s, i) => s + _calcRow(i)['sgst']!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _totalRow('Sub Total', subTotal),
          _totalRow('Discount', discount),
          _totalRow('CGST', cgst),
          _totalRow('SGST', sgst),
          const Divider(),
          _totalRow('Grand Total', _grandTotal, bold: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
