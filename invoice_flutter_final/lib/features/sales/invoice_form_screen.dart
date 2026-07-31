import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
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
///  - GET /searchCustomer?keyword=, GET /searchItem?keyword= (2+ chars,
///    debounced 300ms - matches AddSale.js's `itemSearchTimer` /
///    `handleItemNameInput`) autocomplete, with the same
///    auto-fill-from-item logic (MRP items skip GST; sale-price-
///    inclusive-of-tax items get back-calculated to a tax-exclusive
///    price)
///  - Per-row tax/discount math (`calcRow`): gross = qty*price, discount
///    is either % of gross or a manually-typed amount, taxable =
///    gross-discount, CGST/SGST = taxable * (gst/2)/100 each, plus a
///    flat additional-cess-per-unit, row total = taxable+cgst+sgst+cess
///  - Sub Total shown in the totals summary = sum of `taxable` (post-
///    discount, pre-tax), matching `subTotal` in AddSale.js's bill
///    renderer - NOT sum of gross. (BUGFIX: this screen previously
///    summed `gross` here, overstating the sub-total whenever any row
///    had a discount.)
///  - SALE-only: "Received" must be checked before saving (source
///    literally blocks save via `alert()` otherwise), payment
///    type+amount, round-off toggle
///  - Validation: at least one item row with a non-empty item name
///  - POST /saveBill (create) or PUT /updateBill/{id} (edit)
///
/// BUGFIX (critical): every text field in this screen used to be built
/// as `TextEditingController(text: someValue)` created *inline inside
/// build()*, instead of a controller stored once in State/`_LineItem`.
/// Because typing in Qty/Price called `setState` on every keystroke
/// (and typing an Item Name triggers a rebuild once the debounced
/// search resolves), a **brand new controller replaced the old one on
/// every rebuild** - which resets the text-editing cursor to the start
/// of the field. The next character then gets inserted *before* what
/// was already typed instead of after it, which is what was reported as
/// "item name and price display right-to-left": digits/letters were
/// actually being prepended, not rendered in the wrong text direction.
/// The same corruption fed into `_calcRow`, so wrong digit order also
/// explains the reported bad totals, and a corrupted item-name keyword
/// being sent to `/searchItem` explains items appearing not to be
/// found. All per-row fields (and Invoice Number / State of Supply,
/// which had the same latent bug) now use controllers created once and
/// reused across rebuilds; `.text` is only ever reassigned
/// programmatically (loading a bill, selecting an autocomplete result).
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
  _LineItem()
      : itemCtl = TextEditingController(),
        qtyCtl = TextEditingController(text: '1'),
        priceCtl = TextEditingController(),
        discountPctCtl = TextEditingController();

  String hsn = '';
  String unit = 'NONE';
  bool discAmtManual = false;
  String discountAmt = '';
  String tax = 'Select';
  String addcess = '';
  String mrp = '';

  // Persistent controllers - created once per row and reused across
  // rebuilds (see class-level BUGFIX note above). `.text` is only ever
  // set programmatically (never recreated) so the cursor position the
  // person is actively typing at is preserved.
  final TextEditingController itemCtl;
  final TextEditingController qtyCtl;
  final TextEditingController priceCtl;
  final TextEditingController discountPctCtl;

  String get item => itemCtl.text;
  String get qty => qtyCtl.text;
  String get priceWithoutTax => priceCtl.text;
  String get discountPct => discountPctCtl.text;

  /// Overwrites all editable fields at once (loading a bill / picking an
  /// autocomplete result) without swapping out the controller instances.
  void setValues({String? item, String? qty, String? price, String? discountPct}) {
    if (item != null) itemCtl.text = item;
    if (qty != null) qtyCtl.text = qty;
    if (price != null) priceCtl.text = price;
    if (discountPct != null) discountPctCtl.text = discountPct;
  }

  void dispose() {
    itemCtl.dispose();
    qtyCtl.dispose();
    priceCtl.dispose();
    discountPctCtl.dispose();
  }
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
  final _invoiceNumberCtl = TextEditingController(text: '1');
  final _invoiceDateCtl = TextEditingController();
  final _stateOfSupplyCtl = TextEditingController();

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
    _invoiceDateCtl.text = _invoiceDate.toIso8601String().split('T').first;
    if (widget.isEditMode) {
      _fetchBill(widget.invoiceId!);
    } else {
      _fetchNextInvoiceNumber();
    }
  }

  @override
  void dispose() {
    _customerSearchTimer?.cancel();
    _itemSearchTimer?.cancel();
    for (final item in _items) {
      item.dispose();
    }
    _partyNameCtl.dispose();
    _phoneCtl.dispose();
    _descriptionCtl.dispose();
    _termsCtl.dispose();
    _receivedAmountCtl.dispose();
    _invoiceNumberCtl.dispose();
    _invoiceDateCtl.dispose();
    _stateOfSupplyCtl.dispose();
    super.dispose();
  }

  Future<void> _fetchNextInvoiceNumber() async {
    try {
      final res = await ApiClient.instance.dio.get('/getNextInvoiceNumber');
      final n = res.data is int ? res.data as int : int.tryParse('${res.data}') ?? 1;
      setState(() {
        _invoiceNumber = n;
        _invoiceNumberCtl.text = '$n';
      });
    } catch (e) {
      debugPrint('Failed to fetch invoice number: $e');
    }
  }

  Future<void> _fetchBill(String id) async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getBill/${idParam(id)}');
      final bill = res.data as Map;
      setState(() {
        _partyNameCtl.text = '${bill['partyName'] ?? ''}';
        _phoneCtl.text = '${bill['phoneNo'] ?? ''}';
        _invoicePrefix = '${bill['invoicePrefix'] ?? 'INV'}';
        _invoiceNumber = int.tryParse('${bill['invoiceNumber']}') ?? 1;
        _invoiceNumberCtl.text = '$_invoiceNumber';
        _invoiceDate = DateTime.tryParse('${bill['invoiceDate']}') ?? DateTime.now();
        _invoiceDateCtl.text = _invoiceDate.toIso8601String().split('T').first;
        _stateOfSupply = '${bill['stateOfSupply'] ?? ''}';
        _stateOfSupplyCtl.text = _stateOfSupply;
        _roundOff = bill['roundOffEnabled'] == true;
        _received = bill['received'] == true;
        _receivedAmountCtl.text = bill['amountReceived'] != null ? '${bill['amountReceived']}' : '';
        _paymentType = '${bill['paymentMode'] ?? 'Cash'}';
        _descriptionCtl.text = '${bill['description'] ?? ''}';
        _termsCtl.text = '${bill['termsConditions'] ?? 'Thanks for doing business with us!'}';

        final rows = (bill['items'] as List?) ?? [];
        for (final old in _items) {
          old.dispose();
        }
        _items.clear();
        for (final r in rows) {
          final row = r as Map;
          final taxPct = num.tryParse('${row['taxPct']}') ?? 0;
          _items.add(_LineItem()
            ..setValues(
              item: '${row['itemName'] ?? ''}',
              qty: '${row['qty'] ?? '1'}',
              price: '${row['priceWithoutTax'] ?? ''}',
              discountPct: '${row['discountPct'] ?? ''}',
            )
            ..hsn = '${row['hsnCode'] ?? ''}'
            ..unit = '${row['unit'] ?? 'NONE'}'
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
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to load invoice. Please try again.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Timer? _customerSearchTimer;
  void _onPartyNameChanged(String keyword) {
    _customerSearchTimer?.cancel();
    if (keyword.trim().length < 2) {
      setState(() => _customerResults = []);
      return;
    }
    _customerSearchTimer = Timer(const Duration(milliseconds: 300), () => _searchCustomer(keyword));
  }

  Future<void> _searchCustomer(String keyword) async {
    try {
      final res = await ApiClient.instance.dio.get('/searchCustomer', queryParameters: {'keyword': keyword});
      if (!mounted) return;
      setState(() => _customerResults = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      debugPrint('Customer search failed: $e');
    }
  }

  void _selectCustomer(Map<String, dynamic> c) {
    setState(() {
      _partyNameCtl.text = '${c['name'] ?? ''}';
      _phoneCtl.text = '${c['phone'] ?? ''}';
      if (c['state'] != null) {
        _stateOfSupply = '${c['state']}';
        _stateOfSupplyCtl.text = _stateOfSupply;
      }
      _customerResults = [];
    });
  }

  Timer? _itemSearchTimer;
  void _onItemNameChanged(int rowIndex, String keyword) {
    _itemSearchTimer?.cancel();
    if (keyword.trim().length < 2) {
      setState(() {
        _itemResults = [];
        _activeItemSearchIndex = null;
      });
      return;
    }
    _itemSearchTimer = Timer(const Duration(milliseconds: 300), () => _searchItem(rowIndex, keyword));
  }

  Future<void> _searchItem(int rowIndex, String keyword) async {
    try {
      final res = await ApiClient.instance.dio.get('/searchItem', queryParameters: {'keyword': keyword});
      if (!mounted) return;
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
      row.setValues(
        item: '${selected['itemName'] ?? ''}',
        qty: '1',
        price: priceToUse.toString(),
        discountPct: selected['discountOnSale'] != null ? '${selected['discountOnSale']}' : '',
      );
      row.hsn = '${selected['itemHsn'] ?? ''}';
      row.unit = '${selected['unit'] ?? 'NONE'}';
      row.tax = taxString;
      row.mrp = mrp != null ? '$mrp' : '';
      row.addcess = selected['additionalCessPerUnit'] != null ? '${selected['additionalCessPerUnit']}' : '';
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
    setState(() => _items.removeAt(i).dispose());
  }

  Future<void> _downloadBill() async {
    if (widget.invoiceId == null) return;
    try {
      final res = await ApiClient.instance.dio.get(
        '/downloadBill/${idParam(widget.invoiceId)}',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(List<int>.from(res.data as List));
      if (bytes.isEmpty) throw Exception('Empty PDF response');
      await Printing.sharePdf(bytes: bytes, filename: '${widget.isSale ? 'Invoice' : 'Estimate'}_$_invoiceNumber.pdf');
    } catch (e) {
      debugPrint('Download failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download PDF.')));
      }
    }
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
        await ApiClient.instance.dio.put('/updateBill/${idParam(widget.invoiceId)}', data: payload);
      } else {
        await ApiClient.instance.dio.post('/saveBill', data: payload);
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved!'),
            content: Text('${widget.isSale ? 'Sale' : 'Estimate'} ${widget.isEditMode ? 'updated' : 'saved'} successfully!'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) {
          safeBack(context, fallback: widget.isSale ? '/view/salesinvoice' : '/view/estimateinvoice');
        }
      }
    } on DioException catch (e) {
      debugPrint('Save failed: ${e.response?.statusCode} ${e.response?.data} ${e.message}');
      _alert(_describeSaveError(e, isUpdate: widget.isEditMode));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Turns a failed save/update DioException into a message that actually
  /// says something useful, instead of a dead-end "please try again" -
  /// this was the reported "Update" always failing with no way to tell
  /// why. Shows the server's own error text when it sends one (most
  /// backends return a validation message in the response body), falls
  /// back to a status-code-specific explanation otherwise.
  String _describeSaveError(DioException e, {required bool isUpdate}) {
    final action = isUpdate ? 'update' : 'save';
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMessage;
    if (data is Map) {
      serverMessage = (data['message'] ?? data['error'] ?? data['detail'])?.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      serverMessage = data.trim();
    }

    if (status == 404) {
      return isUpdate
          ? 'Could not $action: this bill no longer exists on the server (404). It may have been deleted.'
          : 'Could not $action bill (404 - endpoint not found).';
    }
    if (status == 400) {
      return 'Could not $action bill: ${serverMessage ?? 'the server rejected the data (400 Bad Request). Please check all fields.'}';
    }
    if (status == 401 || status == 403) {
      return 'Could not $action bill: you are not authorized to do this (${status}).';
    }
    if (status != null && status >= 500) {
      return 'Could not $action bill: the server had a problem (${status}). ${serverMessage ?? ''}'.trim();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not $action bill: could not reach the server. Check your connection and the API URL.';
    }
    if (serverMessage != null) return 'Could not $action bill: $serverMessage';
    return 'Failed to $action bill. Please try again.';
  }

  void _alert(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
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
          if (widget.isEditMode)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Download PDF',
              onPressed: () => _downloadBill(),
            ),
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
                controller: _invoiceNumberCtl,
                onChanged: (v) => _invoiceNumber = int.tryParse(v) ?? _invoiceNumber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Invoice Date'),
          readOnly: true,
          controller: _invoiceDateCtl,
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: _invoiceDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (date != null) {
              setState(() {
                _invoiceDate = date;
                _invoiceDateCtl.text = date.toIso8601String().split('T').first;
              });
            }
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
          onChanged: _onPartyNameChanged,
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
          controller: _stateOfSupplyCtl,
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
                    controller: item.itemCtl,
                    textDirection: TextDirection.ltr,
                    onChanged: (v) => _onItemNameChanged(index, v),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    controller: item.qtyCtl,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Price', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    controller: item.priceCtl,
                    onChanged: (_) => setState(() {}),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    controller: item.discountPctCtl,
                    onChanged: (_) => setState(() => item.discAmtManual = false),
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
    // BUGFIX: Sub Total must be the sum of *taxable* amounts (gross minus
    // discount, before tax) - matches `subTotal = rows.reduce((s, r) =>
    // s + r.taxable, 0)` in AddSale.js. This previously summed `gross`
    // here instead, which overstated Sub Total whenever any row had a
    // discount (Discount + Sub Total no longer matched Grand Total).
    final subTotal = _items.fold<double>(0, (s, i) => s + _calcRow(i)['taxable']!);
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
