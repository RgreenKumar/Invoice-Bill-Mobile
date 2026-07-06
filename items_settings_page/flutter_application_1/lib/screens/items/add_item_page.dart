import 'package:flutter/material.dart';
import '../../models/item_model.dart';

class AddItemPage extends StatefulWidget {
  final Function(Item) onSaveItem;
  final VoidCallback onCancel;

  const AddItemPage({super.key, required this.onSaveItem, required this.onCancel});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers to grab explicit dynamic text values
  final _nameController = TextEditingController();
  final _hsnController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();

  // Selected default dropdown states
  String _selectedUnit = 'BOX';
  String _selectedCategory = 'Electronics';
  String _selectedTaxStatus = 'Without Tax';

  // Configured Dropdown Option Arrays
  final List<String> _units = ['BOX', 'PCS', 'KGS', 'LTRS', 'NOS', 'NONE'];
  final List<String> _categories = ['Electronics', 'Apparel', 'Grocery', 'Services', 'Hardware', 'None'];
  final List<String> _taxStatuses = ['Without Tax', 'With Tax'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _hsnController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item Name is required field!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final enteredPrice = double.tryParse(_priceController.text) ?? 0.0;

    final newItem = Item(
      name: _nameController.text.trim(),
      hsn: _hsnController.text.trim(),
      unit: _selectedUnit,
      category: _selectedCategory,
      code: _codeController.text.trim(),
      salePrice: enteredPrice,
      taxStatus: _selectedTaxStatus,
    );

    widget.onSaveItem(newItem); // Bubbles new data item structure state to main layout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: widget.onCancel)],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildTextField('Item Name *', _nameController)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildTextField('Item HSN Code', _hsnController, suffixIcon: Icons.search)),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildDropdownField('Unit', _selectedUnit, _units, (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDropdownField('Category', _selectedCategory, _categories, (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildTextField('Item Code', _codeController)),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                        onPressed: () {},
                        child: const Text('Assign Code'),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.black,
                    indicatorColor: Colors.blue,
                    tabs: const [Tab(text: 'PRICING'), Tab(text: 'STOCK')],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sale Price', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(width: 180, child: _buildTextField('Sale Price', _priceController)),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  child: _buildDropdownField('Tax Type', _selectedTaxStatus, _taxStatuses, (val) {
                                    if (val != null) setState(() => _selectedTaxStatus = val);
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Center(child: Text('Stock Configuration Screen')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel', style: TextStyle(color: Colors.black))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF132E47)),
                  onPressed: _submitData,
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? suffixIcon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, String currentSelection, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
      initialValue: currentSelection,
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }
}
