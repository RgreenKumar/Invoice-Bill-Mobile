import 'package:flutter/material.dart';
import '../../../app_feature_settings.dart';
import '../../models/item_model.dart';

class ItemsViewPage extends StatefulWidget {
  final List<Item> items;
  final VoidCallback onNavigateToAddItem;

  const ItemsViewPage({
    super.key,
    required this.items,
    required this.onNavigateToAddItem,
  });

  @override
  State<ItemsViewPage> createState() => _ItemsViewPageState();
}

class _ItemsViewPageState extends State<ItemsViewPage> {
  Item? _selectedItem; // Tracks currently active selected item split pane

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppFeatureSettings>(
      valueListenable: appFeatureSettings,
      builder: (context, settings, _) {
        return Column(
          children: [
            // Navbar header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'ALL ITEMS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text('CATEGORY', style: TextStyle(color: Colors.grey[600])),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: settings.enableItems
                        ? widget.onNavigateToAddItem
                        : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            Expanded(
              child: Row(
                children: [
                  // Left Column List Pane
                  Container(
                    width: 350,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search items...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Colors.grey[100],
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ITEM NAME',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                'SALE PRICE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reactive List Builder layout view switching
                        Expanded(
                          child: !settings.enableItems
                              ? const Center(
                                  child: Text(
                                    'Item module is disabled in settings',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : widget.items.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No items found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: widget.items.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = widget.items[index];
                                    final isCurrent = _selectedItem == item;
                                    return ListTile(
                                      tileColor: isCurrent
                                          ? Colors.blue.withValues(alpha: 0.05)
                                          : null,
                                      title: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _itemSubtitle(item, settings),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Text(
                                        '₹${item.salePrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      onTap: () =>
                                          setState(() => _selectedItem = item),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),

                  // Right Column Details Panel View Pane
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: !settings.enableItems
                          ? const Center(
                              child: Text(
                                'Enable Item in Settings to use item features.',
                              ),
                            )
                          : _selectedItem == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select an item to view details',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedItem!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (settings.itemCategory)
                                  Chip(
                                    label: Text(_selectedItem!.category),
                                    backgroundColor: Colors.blue[50],
                                  ),
                                const SizedBox(height: 24),
                                if (settings.enableGst && settings.enableHsn)
                                  _buildDetailRow(
                                    'HSN Code',
                                    _selectedItem!.hsn,
                                  ),
                                if (settings.itemsUnit)
                                  _buildDetailRow(
                                    'Measurement Unit',
                                    _selectedItem!.unit,
                                  ),
                                _buildDetailRow(
                                  'Item Unique Code',
                                  _selectedItem!.code,
                                ),
                                _buildDetailRow(
                                  'Base Sale Price',
                                  '₹${_selectedItem!.salePrice.toStringAsFixed(2)} (${_selectedItem!.taxStatus})',
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _itemSubtitle(Item item, AppFeatureSettings settings) {
    final parts = <String>[];
    if (settings.itemCategory) parts.add(item.category);
    if (settings.itemsUnit) parts.add('Unit: ${item.unit}');
    return parts.isEmpty ? 'Item details' : parts.join(' • ');
  }

  Widget _buildDetailRow(String title, String data) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          data.isNotEmpty ? data : '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
