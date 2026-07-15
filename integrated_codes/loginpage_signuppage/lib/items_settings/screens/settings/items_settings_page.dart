import 'package:flutter/material.dart';
import '../../../app_feature_settings.dart';

class ItemsSettingsPage extends StatefulWidget {
  const ItemsSettingsPage({super.key});

  @override
  State<ItemsSettingsPage> createState() => _ItemsSettingsPageState();
}

class _ItemsSettingsPageState extends State<ItemsSettingsPage> {
  bool _isEditing =
      false; // Controls editable access locking criteria parameters

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppFeatureSettings>(
      valueListenable: appFeatureSettings,
      builder: (context, settings, _) {
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
                              const Text(
                                'Item Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Divider(height: 24),
                              _buildCheckbox(
                                'Enable Item',
                                settings.enableItems,
                                (v) => _update(
                                  settings.copyWith(enableItems: v ?? false),
                                ),
                              ),
                              _buildCheckbox(
                                'Stock Maintenance',
                                settings.stockMaintenance,
                                (v) => _update(
                                  settings.copyWith(
                                    stockMaintenance: v ?? false,
                                  ),
                                ),
                              ),
                              _buildCheckbox(
                                'Show Low Stock Dialog',
                                settings.showLowStockDialog,
                                (v) => _update(
                                  settings.copyWith(
                                    showLowStockDialog: v ?? false,
                                  ),
                                ),
                              ),
                              _buildCheckbox(
                                'Items Unit',
                                settings.itemsUnit,
                                (v) => _update(
                                  settings.copyWith(itemsUnit: v ?? false),
                                ),
                              ),
                              _buildCheckbox(
                                'Default Unit',
                                settings.defaultUnit,
                                (v) => _update(
                                  settings.copyWith(defaultUnit: v ?? false),
                                ),
                              ),
                              _buildCheckbox(
                                'Item Category',
                                settings.itemCategory,
                                (v) => _update(
                                  settings.copyWith(itemCategory: v ?? false),
                                ),
                              ),
                              _buildCheckbox(
                                'Description (Change Text)',
                                settings.description,
                                (v) => _update(
                                  settings.copyWith(description: v ?? false),
                                ),
                              ),
                              _buildCheckbox(
                                'Item wise Tax',
                                settings.itemWiseTax,
                                (v) => _update(
                                  settings.copyWith(itemWiseTax: v ?? false),
                                ),
                              ),
                              _buildCheckbox(
                                'Item wise Discount',
                                settings.itemWiseDiscount,
                                (v) => _update(
                                  settings.copyWith(
                                    itemWiseDiscount: v ?? false,
                                  ),
                                ),
                              ),

                              // Quantity Decimal Layout Counter Row Block
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Quantity (upto Decimal Places)',
                                      style: TextStyle(
                                        color: _isEditing
                                            ? Colors.black87
                                            : Colors.grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.help_outline,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${settings.quantityDecimalPlaces}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: _isEditing
                                                    ? () => _update(
                                                        settings.copyWith(
                                                          quantityDecimalPlaces:
                                                              settings
                                                                  .quantityDecimalPlaces +
                                                              1,
                                                        ),
                                                      )
                                                    : null,
                                                child: const Icon(
                                                  Icons.arrow_drop_up,
                                                  size: 18,
                                                ),
                                              ),
                                              InkWell(
                                                onTap:
                                                    _isEditing &&
                                                        settings.quantityDecimalPlaces >
                                                            0
                                                    ? () => _update(
                                                        settings.copyWith(
                                                          quantityDecimalPlaces:
                                                              settings
                                                                  .quantityDecimalPlaces -
                                                              1,
                                                        ),
                                                      )
                                                    : null,
                                                child: const Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'e.g. 0.00',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildCheckbox(
                                'Wholesale Price',
                                settings.wholesalePrice,
                                (v) => _update(
                                  settings.copyWith(wholesalePrice: v ?? false),
                                ),
                              ),
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
                              const Text(
                                'Additional Item Fields',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Divider(height: 24),
                              const Text(
                                'MRP/Price',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildFormCheckboxRow(
                                'MRP',
                                settings.mrp,
                                'MRP',
                                (v) =>
                                    _update(settings.copyWith(mrp: v ?? false)),
                              ),
                              _buildCheckbox(
                                'Calculate Tax based on MRP',
                                settings.calculateTaxOnMrp,
                                (v) => _update(
                                  settings.copyWith(
                                    calculateTaxOnMrp: v ?? false,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildDropdownFormCheckboxRow(
                                'Exp Date',
                                settings.expDate,
                                'Exp. Date',
                                (v) => _update(
                                  settings.copyWith(expDate: v ?? false),
                                ),
                              ),
                              _buildDropdownFormCheckboxRow(
                                'Mfg Date',
                                settings.mfgDate,
                                'Mfg. Date',
                                (v) => _update(
                                  settings.copyWith(mfgDate: v ?? false),
                                ),
                              ),
                              _buildFormCheckboxRow(
                                'Model No.',
                                settings.modelNo,
                                'Model No.',
                                (v) => _update(
                                  settings.copyWith(modelNo: v ?? false),
                                ),
                              ),
                              _buildFormCheckboxRow(
                                'Size',
                                settings.size,
                                'Size',
                                (v) => _update(
                                  settings.copyWith(size: v ?? false),
                                ),
                              ),
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
                        backgroundColor: const Color(
                          0xFF84CC16,
                        ), // Green tone accent design
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEditing
                                  ? 'Fields Unlocked'
                                  : 'Configurations Saved Successfully.',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _isEditing ? 'Save Changes' : 'Edit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _update(AppFeatureSettings settings) {
    appFeatureSettings.value = settings;
  }

  // Helper Widget for standard checkboxes
  Widget _buildCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: _isEditing ? onChanged : null,
            activeColor: const Color(0xFF132E47),
          ),
          Text(
            title,
            style: TextStyle(
              color: value && _isEditing ? Colors.black87 : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.help_outline, size: 14, color: Colors.grey[300]),
        ],
      ),
    );
  }

  // Helper Widget for mixed rows with text input fields
  Widget _buildFormCheckboxRow(
    String title,
    bool value,
    String hint,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: _isEditing ? onChanged : null,
                  activeColor: const Color(0xFF132E47),
                ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  // Helper Widget for specialized date rows with date format selection boxes
  Widget _buildDropdownFormCheckboxRow(
    String title,
    bool value,
    String hint,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: _isEditing ? onChanged : null,
                  activeColor: const Color(0xFF132E47),
                ),
                Text(title, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          if (value) ...[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'dd/mm/yy',
                  items: const [
                    DropdownMenuItem(
                      value: 'dd/mm/yy',
                      child: Text('dd/mm/yy', style: TextStyle(fontSize: 12)),
                    ),
                  ],
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}
