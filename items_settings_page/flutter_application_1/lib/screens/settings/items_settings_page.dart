import 'package:flutter/material.dart';

class ItemsSettingsPage extends StatefulWidget {
  const ItemsSettingsPage({super.key});

  @override
  State<ItemsSettingsPage> createState() => _ItemsSettingsPageState();
}

class _ItemsSettingsPageState extends State<ItemsSettingsPage> {
  bool _isEditing = false; // Controls editable access locking criteria parameters

  // Left Column Layout Properties States Mapping Matrix
  bool _enableItem = true;
  bool _stockMaintenance = true;
  bool _showLowStockDialog = true;
  bool _itemsUnit = true;
  bool _defaultUnit = false;
  bool _itemCategory = true;
  bool _description = false;
  bool _itemWiseTax = true;
  bool _itemWiseDiscount = true;
  int _decimalPlaces = 2;
  bool _wholesalePrice = true;

  // Right Column Layout Properties Additional Fields State
  bool _mrp = false;
  bool _calcTaxOnMrp = false;
  bool _expDate = true;
  bool _mfgDate = true;
  bool _modelNo = false;
  bool _size = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Item Settings Dashboard Form Panel
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Item Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Divider(height: 24),
                          _buildCheckbox('Enable Item', _enableItem, (v) => setState(() => _enableItem = v!)),
                          _buildCheckbox('Stock Maintenance', _stockMaintenance, (v) => setState(() => _stockMaintenance = v!)),
                          _buildCheckbox('Show Low Stock Dialog', _showLowStockDialog, (v) => setState(() => _showLowStockDialog = v!)),
                          _buildCheckbox('Items Unit', _itemsUnit, (v) => setState(() => _itemsUnit = v!)),
                          _buildCheckbox('Default Unit', _defaultUnit, (v) => setState(() => _defaultUnit = v!)),
                          _buildCheckbox('Item Category', _itemCategory, (v) => setState(() => _itemCategory = v!)),
                          _buildCheckbox('Description (Change Text)', _description, (v) => setState(() => _description = v!)),
                          _buildCheckbox('Item wise Tax', _itemWiseTax, (v) => setState(() => _itemWiseTax = v!)),
                          _buildCheckbox('Item wise Discount', _itemWiseDiscount, (v) => setState(() => _itemWiseDiscount = v!)),
                          
                          // Quantity Decimal Layout Counter Row Block
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Text('Quantity (upto Decimal Places)', style: TextStyle(color: _isEditing ? Colors.black87 : Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 6),
                                Icon(Icons.help_outline, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    children: [
                                      Text('$_decimalPlaces', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(onTap: _isEditing ? () => setState(() => _decimalPlaces++) : null, child: const Icon(Icons.arrow_drop_up, size: 18)),
                                          InkWell(onTap: _isEditing && _decimalPlaces > 0 ? () => setState(() => _decimalPlaces--) : null, child: const Icon(Icons.arrow_drop_down, size: 18)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('e.g. 0.00', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                          ),
                          _buildCheckbox('Wholesale Price', _wholesalePrice, (v) => setState(() => _wholesalePrice = v!)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 48),

                    // RIGHT COLUMN: Additional Item Structural Metadata Subfields
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Additional Item Fields', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Divider(height: 24),
                          const Text('MRP/Price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 12),
                          
                          _buildFormCheckboxRow('MRP', _mrp, 'MRP', (v) => setState(() => _mrp = v!)),
                          _buildCheckbox('Calculate Tax based on MRP', _calcTaxOnMrp, (v) => setState(() => _calcTaxOnMrp = v!)),
                          const SizedBox(height: 12),
                          
                          _buildDropdownFormCheckboxRow('Exp Date', _expDate, 'Exp. Date', (v) => setState(() => _expDate = v!)),
                          _buildDropdownFormCheckboxRow('Mfg Date', _mfgDate, 'Mfg. Date', (v) => setState(() => _mfgDate = v!)),
                          _buildFormCheckboxRow('Model No.', _modelNo, 'Model No.', (v) => setState(() => _modelNo = v!)),
                          _buildFormCheckboxRow('Size', _size, 'Size', (v) => setState(() => _size = v!)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // BOTTOM CONTROL ROW PANEL: Confirm edit criteria state mapping button
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16), // Green tone accent design
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    setState(() => _isEditing = !_isEditing);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isEditing ? 'Fields Unlocked' : 'Configurations Saved Successfully.')),
                    );
                  },
                  child: Text(_isEditing ? 'Save Changes' : 'Edit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Helper Widget for standard checkboxes
  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: _isEditing ? onChanged : null,
            activeColor: const Color(0xFF132E47),
          ),
          Text(title, style: TextStyle(color: value && _isEditing ? Colors.black87 : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Icon(Icons.help_outline, size: 14, color: Colors.grey[300]),
        ],
      ),
    );
  }

  // Helper Widget for mixed rows with text input fields
  Widget _buildFormCheckboxRow(String title, bool value, String hint, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Checkbox(value: value, onChanged: _isEditing ? onChanged : null, activeColor: const Color(0xFF132E47)),
                Text(title, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Icon(Icons.help_outline, size: 14, color: Colors.grey[300]),
              ],
            ),
          ),
          if (value)
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    hintText: hint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            )
          else
            const Spacer()
        ],
      ),
    );
  }

  // Helper Widget for specialized date rows with date format selection boxes
  Widget _buildDropdownFormCheckboxRow(String title, bool value, String hint, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Checkbox(value: value, onChanged: _isEditing ? onChanged : null, activeColor: const Color(0xFF132E47)),
                Text(title, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          if (value) ...[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'dd/mm/yy',
                  items: const [DropdownMenuItem(value: 'dd/mm/yy', child: Text('dd/mm/yy', style: TextStyle(fontSize: 12)))],
                  onChanged: _isEditing ? (v) {} : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    hintText: hint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            )
          ] else
            const Spacer()
        ],
      ),
    );
  }
}