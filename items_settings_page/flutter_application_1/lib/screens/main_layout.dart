import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import 'items/items_view_page.dart';
import 'items/add_item_page.dart';
import 'settings/settings_layout.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentView = 'view_item'; // 'view_item', 'add_item', or 'settings'
  
  final List<Item> _allItems = []; 
  final List<UserModel> _allUsers = [
    UserModel(name: "John Doe", phone: "9876543210", email: "john@company.com", role: "Admin"),
  ]; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Sidebar Panel
          Container(
            width: 240,
            color: const Color(0xFF132E47),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('Invoice', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _sidebarItem(Icons.dashboard_outlined, 'Dashboard', false, isSelected: false, onTap: () {}),
                
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: _currentView == 'view_item' || _currentView == 'add_item',
                    leading: const Icon(Icons.inventory_2_outlined, color: Colors.white70),
                    title: const Text('Items', style: TextStyle(color: Colors.white)),
                    children: [
                      _sidebarSubItem('Add Item', _currentView == 'add_item', () {
                        setState(() => _currentView = 'add_item');
                      }),
                      _sidebarSubItem('View Item', _currentView == 'view_item', () {
                        setState(() => _currentView = 'view_item');
                      }),
                    ],
                  ),
                ),
                
                _sidebarItem(Icons.people_alt_outlined, 'Parties', false, isSelected: false, onTap: () {}),
                
                // Settings Sidebar Row Navigation Selection
                _sidebarItem(
                  Icons.settings_outlined, 
                  'Settings', 
                  false, 
                  isSelected: _currentView == 'settings',
                  onTap: () => setState(() => _currentView = 'settings'),
                ),
              ],
            ),
          ),
          
          // Primary Subsystem Content View Router Screen Switcher
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentView) {
      case 'view_item':
        return ItemsViewPage(
          items: _allItems,
          onNavigateToAddItem: () => setState(() => _currentView = 'add_item'),
        );
      case 'add_item':
        return AddItemPage(
          onSaveItem: (item) => setState(() {
            _allItems.add(item);
            _currentView = 'view_item';
          }),
          onCancel: () => setState(() => _currentView = 'view_item'),
        );
      case 'settings':
        return SettingsLayout(users: _allUsers);
      default:
        return const Center(child: Text("Page Not Found"));
    }
  }

  Widget _sidebarItem(IconData icon, String title, bool hasTrailing, {required bool isSelected, required VoidCallback onTap}) => Container(
        color: isSelected ? const Color(0xFF264663) : Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: Colors.white70, size: 20),
          title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          onTap: onTap,
        ),
      );

  Widget _sidebarSubItem(String title, bool isSelected, VoidCallback onTap) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF264663) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 40),
          title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13)),
          onTap: onTap,
        ),
      );
}