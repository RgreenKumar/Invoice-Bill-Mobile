import 'package:flutter/material.dart';
import '../../models/user_model.dart';

// Class representation mapping data metrics tracking the internal grid system state array row variables
class TransactionPermission {
  final String title;
  bool view;
  bool create;
  bool edit;
  bool delete;

  TransactionPermission({
    required this.title,
    this.view = false,
    this.create = false,
    this.edit = false,
    this.delete = false,
  });
}

class UserSettingsPage extends StatefulWidget {
  final List<UserModel> users;
  final VoidCallback onNavigateToAddUser;

  const UserSettingsPage({super.key, required this.users, required this.onNavigateToAddUser});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  bool _showAddUserForm = true; // Set to true to display the split screen layout directly

  // Pre-configured structured active grid map dataset matching your screenshots exactly
  final List<TransactionPermission> _permissionsMatrix = [
    TransactionPermission(title: 'Sale Invoice', view: true, create: true, edit: false, delete: false),
    TransactionPermission(title: 'Invoice POS', view: true, create: true, edit: false, delete: false),
    TransactionPermission(title: 'Estimate Quotation', view: true, create: true, edit: false, delete: false),
    TransactionPermission(title: 'Add Item', view: true, create: true, edit: false, delete: false),
    TransactionPermission(title: 'View Item', view: true, create: false, edit: false, delete: false),
    TransactionPermission(title: 'Customer', view: true, create: false, edit: false, delete: false),
    TransactionPermission(title: 'Parties', view: true, create: false, edit: false, delete: false),
    TransactionPermission(title: 'Stock Adjustment', view: false, create: false, edit: false, delete: false),
  ];

  // Restores standard framework baseline defaults when "Reset" is tapped
  void _resetMatrixToBaseline() {
    setState(() {
      for (var element in _permissionsMatrix) {
        element.view = element.title != 'Stock Adjustment';
        element.create = ['Sale Invoice', 'Invoice POS', 'Estimate Quotation', 'Add Item'].contains(element.title);
        element.edit = false;
        element.delete = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showAddUserForm && widget.users.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: ElevatedButton(
            onPressed: () => setState(() => _showAddUserForm = true),
            child: const Text('Add Users'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Input Block Form Layout Panel
          Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey[200]!))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 20),
                _formLabel('Enter Full Name *'),
                _formInput('Enter full name'),
                _formLabel('Enter Email *'),
                _formInput('Enter email'),
                const Text('Cashier will receive login credentials on this email.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                _formLabel('Enter Phone Number *'),
                _formInput('Enter phone number'),
                _formLabel('Choose User Role *'),
                DropdownButtonFormField<String>(
                  value: 'Cashier',
                  decoration: InputDecoration(
                    fillColor: Colors.grey[50],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
                  ),
                  items: const [DropdownMenuItem(value: 'Cashier', child: Text('Cashier', style: TextStyle(fontSize: 13)))],
                  onChanged: (v) {},
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showAddUserForm = false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF132E47), foregroundColor: Colors.white),
                        onPressed: () => setState(() => _showAddUserForm = false),
                        icon: const Icon(Icons.person_add, size: 14),
                        label: const Text('Add User', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Right Data Grid Matrix Permissions Overview Panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cashier Permissions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _resetMatrixToBaseline,
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Matrix Interactive Layout Execution
                  Table(
                    border: TableBorder.all(color: Colors.grey[200]!, width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1),
                    },
                    children: [
                      _buildTableHeader(),
                      ...List.generate(_permissionsMatrix.length, (index) {
                        final rowData = _permissionsMatrix[index];
                        return _buildTableRow(rowData, index);
                      }),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _formLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
      );

  Widget _formInput(String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
      );

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF132E47)),
      children: ['TRANSACTIONS', 'VIEW', 'CREATE', 'EDIT', 'DELETE'].map((head) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
          child: Text(
            head,
            textAlign: head == 'TRANSACTIONS' ? TextAlign.left : TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  TableRow _buildTableRow(TransactionPermission row, int rowIndex) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(row.title, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
        ),
        
        // Interactive cells wrapped with InkWell/GestureDetector targets
        _buildInteractiveCell(row.view, () => setState(() => row.view = !row.view)),
        _buildInteractiveCell(row.create, () => setState(() => row.create = !row.create)),
        _buildInteractiveCell(row.edit, () => setState(() => row.edit = !row.edit)),
        _buildInteractiveCell(row.delete, () => setState(() => row.delete = !row.delete)),
      ],
    );
  }

  Widget _buildInteractiveCell(bool value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.blue.withOpacity(0.05),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            value ? Icons.check : Icons.close,
            key: ValueKey<bool>(value),
            color: value ? Colors.green : Colors.redAccent,
            size: 16,
          ),
        ),
      ),
    );
  }
}
