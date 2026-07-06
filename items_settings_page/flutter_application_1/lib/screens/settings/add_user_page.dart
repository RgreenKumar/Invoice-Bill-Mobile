import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class AddUserPage extends StatefulWidget {
  final Function(UserModel) onSaveUser;
  final VoidCallback onCancel;

  const AddUserPage({super.key, required this.onSaveUser, required this.onCancel});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'Staff';
  final List<String> _roles = ['Admin', 'Staff', 'Accountant', 'Manager'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Phone values are required fields!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    widget.onSaveUser(
      UserModel(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _selectedRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onCancel),
              const SizedBox(width: 8),
              const Text('Create New Team User Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _field('Full Name *', _nameCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _field('Phone Contact Number *', _phoneCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field('Email ID Address', _emailCtrl)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Assigned App Role Profile', border: OutlineInputBorder()),
                  initialValue: _selectedRole,
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF132E47), foregroundColor: Colors.white),
                onPressed: _submit,
                child: const Text('Save Account'),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
