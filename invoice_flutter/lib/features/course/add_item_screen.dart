import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';
import '../../core/utils/safe_back.dart';

/// Port of `src/course/Components/CourseCreation.js` (internally
/// `AddItem`), routed at `/item/additem` (create) and `/edititem/:id`
/// (edit - `isEditMode` there).
///
/// Preserves:
///  - GET /getCategories, /getUnits, /getTaxes on load
///  - Edit mode: GET /getItem/{id} pre-fills the whole form, including
///    auto-expanding the Wholesale section if wholesale/purchase price
///    already exist
///  - Default unit auto-selection from `itemSettings.defaultUnit`
///    (create mode only)
///  - Debounced (400ms) item-name autocomplete via GET
///    /searchItems?name=..., same suggestion-click merge behavior
///  - "Assign Code" -> GET /generateItemCode
///  - Validation: Item Name required, Sale Price required, HSN must be
///    4/6/8 digits if provided
///  - Submit: POST /addItem or PUT /updateItem/{id} with the exact same
///    DTO shape (pricing + stock sub-objects); 403/409/other error
///    handling matches
///  - Every field's visibility gated by the same `itemSettings`/
///    `gstSettings` flags as the source (MRP, HSN, unit, category,
///    item-wise tax/discount, additional cess, stock tab only if
///    `stockMaintenance` AND `getPermission(MODULES.STOCK_ADJUSTMENT, "canView")`)
///
/// NOT ported: the item-image upload UI is commented-out JSX in the
/// source (dead code, `handleFileChange`/`previewImage` exist but are
/// never reachable) - omitted here to match actual current behavior.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.itemId});

  final String? itemId;
  bool get isEditMode => itemId != null;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  String _activeTab = 'pricing';
  bool _showWholesale = false;
  bool _loadingItem = false;
  bool _saving = false;
  bool _generatingCode = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _taxes = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _searchDebounce;

  final _formData = <String, dynamic>{
    'itemName': '', 'itemHSN': '', 'unitId': '', 'categoryId': '', 'itemCode': '',
    'mrp': '', 'calculateTaxOnMRP': false, 'salePrice': '', 'taxType': 'without_tax',
    'additionalCessPerUnit': '', 'discount': '', 'discountType': 'Percentage',
    'wholesalePrice': '', 'wholesaleTaxType': 'without_tax', 'purchasePrice': '',
    'purchaseTaxType': 'without_tax', 'taxId': '', 'openingStock': '', 'atPrice': '',
    'asOfDate': '', 'minStockQty': '', 'location': '',
  };
  final _errors = <String, String?>{};

  bool get _canViewStock => getPermission(Modules.stockAdjustment, 'canView');

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchUnits();
    _fetchTaxes();
    if (widget.isEditMode) _fetchItemById(widget.itemId!);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiClient.instance.dio.get('/getCategories');
      setState(() => _categories = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> _fetchUnits() async {
    try {
      final res = await ApiClient.instance.dio.get('/getUnits');
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => _units = list);
      if (!widget.isEditMode && mounted) {
        final defaultUnit = context.read<GlobalStateProvider>().itemSettings['defaultUnit'] as String?;
        if (defaultUnit != null && defaultUnit.isNotEmpty) {
          final matched = list.firstWhere(
            (u) => '${u['name']}'.toLowerCase() == defaultUnit.toLowerCase(),
            orElse: () => {},
          );
          if (matched.isNotEmpty) setState(() => _formData['unitId'] = '${matched['id']}');
        }
      }
    } catch (e) {
      debugPrint('Failed to load units: $e');
    }
  }

  Future<void> _fetchTaxes() async {
    try {
      final res = await ApiClient.instance.dio.get('/getTaxes');
      setState(() => _taxes = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      debugPrint('Failed to load taxes: $e');
    }
  }

  Future<void> _fetchItemById(String itemId) async {
    setState(() => _loadingItem = true);
    try {
      final res = await ApiClient.instance.dio.get('/getItem/$itemId');
      final item = res.data as Map;
      final pricing = (item['pricing'] as Map?) ?? {};
      final stock = (item['stock'] as Map?) ?? {};
      setState(() {
        _formData['itemName'] = '${item['itemName'] ?? ''}';
        _formData['itemHSN'] = '${item['itemHsn'] ?? ''}';
        _formData['unitId'] = item['unitId'] != null ? '${item['unitId']}' : '';
        _formData['categoryId'] = item['categoryId'] != null ? '${item['categoryId']}' : '';
        _formData['itemCode'] = '${item['itemCode'] ?? ''}';
        _formData['mrp'] = pricing['mrp'] != null ? '${pricing['mrp']}' : '';
        _formData['calculateTaxOnMRP'] = pricing['calculateTaxOnMrp'] == true;
        _formData['salePrice'] = pricing['salePrice'] != null ? '${pricing['salePrice']}' : '';
        _formData['taxType'] = pricing['salePriceTaxType'] ?? 'without_tax';
        _formData['additionalCessPerUnit'] = pricing['additionalCessPerUnit'] != null ? '${pricing['additionalCessPerUnit']}' : '';
        _formData['discount'] = pricing['discountOnSale'] != null ? '${pricing['discountOnSale']}' : '';
        final dType = pricing['discountType'] as String?;
        _formData['discountType'] = dType != null && dType.isNotEmpty ? '${dType[0].toUpperCase()}${dType.substring(1)}' : 'Percentage';
        _formData['wholesalePrice'] = pricing['wholesalePrice'] != null ? '${pricing['wholesalePrice']}' : '';
        _formData['wholesaleTaxType'] = pricing['wholesalePriceTaxType'] ?? 'without_tax';
        _formData['purchasePrice'] = pricing['purchasePrice'] != null ? '${pricing['purchasePrice']}' : '';
        _formData['purchaseTaxType'] = pricing['purchasePriceTaxType'] ?? 'without_tax';
        _formData['taxId'] = pricing['taxId'] != null ? '${pricing['taxId']}' : '';
        _formData['openingStock'] = stock['openingStock'] != null ? '${stock['openingStock']}' : '';
        _formData['atPrice'] = stock['stockAtPrice'] != null ? '${stock['stockAtPrice']}' : '';
        _formData['asOfDate'] = '${stock['stockAsOfDate'] ?? ''}';
        _formData['minStockQty'] = stock['minStockQty'] != null ? '${stock['minStockQty']}' : '';
        _formData['location'] = '${stock['location'] ?? ''}';
        if (pricing['wholesalePrice'] != null || pricing['purchasePrice'] != null) _showWholesale = true;
      });
    } catch (e) {
      debugPrint('Failed to fetch item: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to load item data!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingItem = false);
    }
  }

  void _handleNameChange(String value) {
    setState(() {
      _formData['itemName'] = value;
      _errors['itemName'] = null;
    });
    _searchDebounce?.cancel();
    if (value.length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 400), () => _searchSuggestions(value));
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _searchSuggestions(String name) async {
    try {
      final res = await ApiClient.instance.dio.get('/searchItems', queryParameters: {'name': name});
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) {
        setState(() {
          _suggestions = list;
          _showSuggestions = list.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Search failed: $e');
    }
  }

  void _handleSuggestionClick(Map<String, dynamic> item) {
    setState(() {
      if ('${item['itemName']}'.toLowerCase() == '${_formData['itemName']}'.toLowerCase()) {
        _formData['itemHSN'] = '${item['itemHsn'] ?? ''}';
        _formData['itemCode'] = '${item['itemCode'] ?? ''}';
      } else {
        _formData['itemName'] = '${item['itemName']}';
        _formData['itemHSN'] = '${item['itemHsn'] ?? ''}';
      }
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _handleHsnChange(String value) {
    setState(() {
      _formData['itemHSN'] = value;
      _errors['itemHSN'] = (value.isNotEmpty && value.length != 4 && value.length != 6 && value.length != 8)
          ? 'HSN must be 4, 6, or 8 digits'
          : null;
    });
  }

  Future<void> _handleGenerateCode() async {
    setState(() => _generatingCode = true);
    try {
      final res = await ApiClient.instance.dio.get('/generateItemCode');
      setState(() => _formData['itemCode'] = '${res.data}');
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to generate item code!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingCode = false);
    }
  }

  bool _validate() {
    final newErrors = <String, String?>{};
    if ('${_formData['itemName']}'.trim().isEmpty) newErrors['itemName'] = 'Item Name is required';
    if ('${_formData['salePrice']}'.isEmpty) newErrors['salePrice'] = 'Sale Price is required';
    final hsn = '${_formData['itemHSN']}';
    if (hsn.isNotEmpty && hsn.length != 4 && hsn.length != 6 && hsn.length != 8) {
      newErrors['itemHSN'] = 'HSN must be 4, 6, or 8 digits';
    }
    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });
    return newErrors.isEmpty;
  }

  Map<String, dynamic> _buildDto(bool stockMaintenance) {
    num? asNum(String key) => '${_formData[key]}'.isEmpty ? null : num.tryParse('${_formData[key]}');
    int? asInt(String key) => '${_formData[key]}'.isEmpty ? null : int.tryParse('${_formData[key]}');

    return {
      'itemName': '${_formData['itemName']}'.trim(),
      'itemHsn': '${_formData['itemHSN']}'.isEmpty ? null : _formData['itemHSN'],
      'itemCode': '${_formData['itemCode']}'.isEmpty ? null : _formData['itemCode'],
      'categoryId': asInt('categoryId'),
      'unitId': asInt('unitId'),
      'itemImage': null,
      'pricing': {
        'salePrice': asNum('salePrice'),
        'salePriceTaxType': _formData['taxType'],
        'discountOnSale': asNum('discount'),
        'discountType': '${_formData['discountType']}'.toLowerCase(),
        'wholesalePrice': asNum('wholesalePrice'),
        'wholesalePriceTaxType': _formData['wholesaleTaxType'],
        'purchasePrice': asNum('purchasePrice'),
        'purchasePriceTaxType': _formData['purchaseTaxType'],
        'taxId': asInt('taxId'),
        'mrp': asNum('mrp'),
        'calculateTaxOnMrp': _formData['calculateTaxOnMRP'],
        'additionalCessPerUnit': asNum('additionalCessPerUnit'),
      },
      'stock': stockMaintenance
          ? {
              'openingStock': asInt('openingStock'),
              'stockAtPrice': asNum('atPrice'),
              'stockAsOfDate': '${_formData['asOfDate']}'.isEmpty ? null : _formData['asOfDate'],
              'minStockQty': asInt('minStockQty'),
              'location': '${_formData['location']}'.isEmpty ? null : _formData['location'],
            }
          : null,
    };
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;
    final stockMaintenance = context.read<GlobalStateProvider>().itemSettings['stockMaintenance'] == true;
    setState(() => _saving = true);
    try {
      final dto = _buildDto(stockMaintenance);
      if (widget.isEditMode) {
        await ApiClient.instance.dio.put('/updateItem/${widget.itemId}', data: dto);
      } else {
        await ApiClient.instance.dio.post('/addItem', data: dto);
      }
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Success'),
            content: Text('Item ${widget.isEditMode ? 'updated' : 'saved'} successfully!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        if (mounted) safeBack(context, fallback: '/dashboard/viewitem');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _showError(status == 403
          ? 'Access Denied!'
          : status == 409
              ? '${e.response?.data ?? 'Duplicate item!'}'
              : 'Something went wrong!');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemSettings = context.watch<GlobalStateProvider>().itemSettings;
    final gstSettings = context.watch<GlobalStateProvider>().gstSettings;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Item' : 'Add Item'),
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => safeBack(context, fallback: '/dashboard/viewitem'))],
      ),
      body: _loadingItem
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _itemNameField(),
                  if (gstSettings['enableHSN'] == true) ...[
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(labelText: 'Item HSN (4, 6, or 8 digits)', errorText: _errors['itemHSN']),
                      controller: TextEditingController(text: _formData['itemHSN']),
                      maxLength: 8,
                      onChanged: _handleHsnChange,
                    ),
                  ],
                  if (itemSettings['itemsUnit'] == true) ...[
                    const SizedBox(height: 12),
                    _dropdown('Select Unit', 'unitId', _units.map((u) => MapEntry('${u['id']}', '${u['name']} (${u['symbol']})')).toList()),
                  ],
                  if (itemSettings['itemCategory'] == true) ...[
                    const SizedBox(height: 12),
                    _dropdown('Category', 'categoryId', _categories.map((c) => MapEntry('${c['id']}', '${c['name']}')).toList()),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Item Code'),
                          controller: TextEditingController(text: _formData['itemCode']),
                          onChanged: (v) => _formData['itemCode'] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _generatingCode ? null : _handleGenerateCode,
                        child: Text(_generatingCode ? '...' : 'Assign Code'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _tabBar(itemSettings),
                  const SizedBox(height: 16),
                  if (_activeTab == 'pricing') _pricingTab(itemSettings, gstSettings),
                  if (_activeTab == 'stock' && itemSettings['stockMaintenance'] == true && _canViewStock)
                    _stockTab(itemSettings),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => safeBack(context, fallback: '/dashboard/viewitem'),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _handleSubmit,
                          child: Text(_saving
                              ? (widget.isEditMode ? 'Updating...' : 'Saving...')
                              : (widget.isEditMode ? 'Update' : 'Save')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _itemNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          autofocus: !widget.isEditMode,
          decoration: InputDecoration(labelText: 'Item Name *', errorText: _errors['itemName']),
          controller: TextEditingController(text: _formData['itemName'])
            ..selection = TextSelection.collapsed(offset: '${_formData['itemName']}'.length),
          onChanged: _handleNameChange,
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
            child: ListView(
              shrinkWrap: true,
              children: _suggestions.map((item) {
                return ListTile(
                  dense: true,
                  title: Text('${item['itemName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: item['itemHsn'] != null ? Text('HSN: ${item['itemHsn']}', style: const TextStyle(fontSize: 11)) : null,
                  onTap: () => _handleSuggestionClick(item),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _dropdown(String hint, String key, List<MapEntry<String, String>> options) {
    final value = '${_formData[key]}'.isEmpty ? null : _formData[key];
    return DropdownButtonFormField<String>(
      value: options.any((o) => o.key == value) ? value : null,
      decoration: InputDecoration(labelText: hint),
      items: options.map((o) => DropdownMenuItem(value: o.key, child: Text(o.value))).toList(),
      onChanged: (v) => setState(() => _formData[key] = v ?? ''),
    );
  }

  Widget _tabBar(Map<String, dynamic> itemSettings) {
    final showStock = itemSettings['stockMaintenance'] == true && _canViewStock;
    return Row(
      children: [
        _tab('Pricing', 'pricing'),
        if (showStock) _tab('Stock', 'stock'),
      ],
    );
  }

  Widget _tab(String label, String key) {
    final active = _activeTab == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _activeTab = key),
      ),
    );
  }

  Widget _pricingTab(Map<String, dynamic> itemSettings, Map<String, dynamic> gstSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (itemSettings['mrp'] == true) ...[
          const Text('MRP', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'MRP Price'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _formData['mrp']),
            onChanged: (v) => _formData['mrp'] = v,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Calculate Tax based on MRP'),
            value: _formData['calculateTaxOnMRP'] == true,
            onChanged: (v) => setState(() => _formData['calculateTaxOnMRP'] = v ?? false),
          ),
          const SizedBox(height: 12),
        ],
        const Text('Sale Price', style: TextStyle(fontWeight: FontWeight.bold)),
        if (_errors['salePrice'] != null)
          Text(_errors['salePrice']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(labelText: 'Sale Price', errorText: _errors['salePrice']),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: _formData['salePrice']),
          onChanged: (v) {
            _formData['salePrice'] = v;
            if (_errors['salePrice'] != null) setState(() => _errors['salePrice'] = null);
          },
        ),
        if (itemSettings['itemWiseTax'] == true) ...[
          const SizedBox(height: 8),
          _dropdown('Tax Type', 'taxType', const [MapEntry('without_tax', 'Without Tax'), MapEntry('with_tax', 'With Tax')]),
        ],
        if (itemSettings['itemWiseDiscount'] == true) ...[
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Disc. On Sale Price'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _formData['discount']),
            onChanged: (v) => _formData['discount'] = v,
          ),
          const SizedBox(height: 8),
          _dropdown('Discount Type', 'discountType', const [MapEntry('Percentage', 'Percentage'), MapEntry('Amount', 'Amount')]),
        ],
        const SizedBox(height: 12),
        if (!_showWholesale)
          TextButton(
            onPressed: () => setState(() => _showWholesale = true),
            child: const Text('+ Add Wholesale Price'),
          ),
        if (_showWholesale) ...[
          const Text('Wholesale Price', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Wholesale Price'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _formData['wholesalePrice']),
            onChanged: (v) => _formData['wholesalePrice'] = v,
          ),
          if (itemSettings['itemWiseTax'] == true) ...[
            const SizedBox(height: 8),
            _dropdown('Wholesale Tax Type', 'wholesaleTaxType', const [MapEntry('without_tax', 'Without Tax'), MapEntry('with_tax', 'With Tax')]),
          ],
          const SizedBox(height: 12),
          const Text('Purchase Price', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Purchase Price'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _formData['purchasePrice']),
            onChanged: (v) => _formData['purchasePrice'] = v,
          ),
          if (itemSettings['itemWiseTax'] == true) ...[
            const SizedBox(height: 8),
            _dropdown('Purchase Tax Type', 'purchaseTaxType', const [MapEntry('without_tax', 'Without Tax'), MapEntry('with_tax', 'With Tax')]),
          ],
          if (gstSettings['enableGST'] == true) ...[
            const SizedBox(height: 12),
            const Text('Taxes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _dropdown('Select Tax', 'taxId', _taxes.map((t) => MapEntry('${t['id']}', '${t['name']} (${t['rate']}%)')).toList()),
          ],
          if (gstSettings['additionalCess'] == true) ...[
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Additional Cess Per Unit'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _formData['additionalCessPerUnit']),
              onChanged: (v) => _formData['additionalCessPerUnit'] = v,
            ),
          ],
        ],
      ],
    );
  }

  Widget _stockTab(Map<String, dynamic> itemSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Opening Stock', hintText: '0'),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: _formData['openingStock']),
          onChanged: (v) => _formData['openingStock'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'At Price (₹)', hintText: '0.00'),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: _formData['atPrice']),
          onChanged: (v) => _formData['atPrice'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'As of Date'),
          readOnly: true,
          controller: TextEditingController(text: _formData['asOfDate']),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _formData['asOfDate'] = date.toIso8601String().split('T').first);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Min Stock Qty', hintText: '0'),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: _formData['minStockQty']),
          onChanged: (v) => _formData['minStockQty'] = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Location', hintText: 'Warehouse / Location'),
          controller: TextEditingController(text: _formData['location']),
          onChanged: (v) => _formData['location'] = v,
        ),
      ],
    );
  }
}
