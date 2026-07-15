import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'general_settings.dart';
import 'tax_settings.dart';
import 'user_settings_page.dart';
import 'items_settings_page.dart'; // Import the new settings subpage

class SettingsLayout extends StatefulWidget {
  final List<UserModel> users;
  const SettingsLayout({super.key, required this.users});

  @override
  State<SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends State<SettingsLayout> {
  String _activeTab = 'General'; // Initializing active display track tab status

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Column Sub-Navigation Side Panel Menu Options
        Container(
          width: 220,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Settings Options', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              _settingsTabRow('General Settings', 'General'),
              _settingsTabRow('Tax & GST Settings', 'Taxes'),
              _settingsTabRow('Items Settings', 'Items'), // Changed from Print
              _settingsTabRow('User Management', 'Users'),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        
        // Right Active view display router content panel switcher
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: _buildActiveSettingsView(),
          ),
        )
      ],
    );
  }

  Widget _settingsTabRow(String title, String tabId) {
    final bool isSelected = _activeTab == tabId;
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF132E47),
      selectedTileColor: Colors.blue.withOpacity(0.05),
      onTap: () => setState(() => _activeTab = tabId),
    );
  }

  Widget _buildActiveSettingsView() {
    switch (_activeTab) {
      case 'General':
        return const GeneralSettings();
      case 'Taxes':
        return const TaxSettings();
      case 'Items':
        return const ItemsSettingsPage(); // Routes to your interactive item dashboard form layout
      case 'Users':
        return UserSettingsPage(
          users: widget.users,
          onNavigateToAddUser: () {},
        );
      default:
        return const Center(child: Text("Module Error Layout View"));
    }
  }
}
