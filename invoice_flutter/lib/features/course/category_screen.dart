import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/routing/app_router.dart';
import 'items_section_tab_bar.dart';

/// Port of `src/course/Components/Category.js`, routed at
/// `/dashboard/category`.
///
/// Preserves:
///  - Tab bar (All Items / Category / Unit) that navigates to
///    `/dashboard/viewitem` / stays here / `/dashboard/unit`
///  - GET /getCategories on load, auto-selects the first category
///  - GET /getItemsByCategory/{id} whenever a category is selected
///  - ADMIN-only "Add Category" (POST /admin/addCategory), edit
///    (PUT /admin/updateCategory/{id}), delete
///    (DELETE /admin/deleteCategory/{id}) - hidden entirely for
///    non-ADMIN roles, and hidden per-row for DEFAULT categories
///    (`item.company == "DEFAULT"`)
///  - Same error-status handling: 403 access-denied/duplicate, 404 not
///    found/default category, 409 name already exists
///
/// Rebuilt mobile-first: category list / item table becomes a
/// list-then-detail flow on narrow screens (same pattern as
/// ViewStudentListScreen), side-by-side on wide screens.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selectedCategory;
  bool _loading = true;
  bool _itemsLoading = false;
  String _searchQuery = '';
  String _itemSearch = '';

  bool get _isAdmin => AuthSnapshot.role == 'ADMIN';
  bool _isDefault(Map c) => c['company'] == 'DEFAULT';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getCategories');
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _categories = list;
        // UX FIX: previously auto-selected `list.first` here, matching
        // the source's desktop master-detail behavior. On mobile that
        // immediately jumped straight into a category's item list,
        // hiding the category picker - reported as confusing. Now the
        // person lands on the category list and taps to select.
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load categories!')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectCategory(Map<String, dynamic> category) {
    setState(() => _selectedCategory = category);
    _fetchItemsByCategory('${category['id']}');
  }

  Future<void> _fetchItemsByCategory(String categoryId) async {
    setState(() => _itemsLoading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getItemsByCategory/$categoryId');
      setState(() => _items = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _itemsLoading = false);
    }
  }

  Future<void> _handleAddCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'e.g., Grocery')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await ApiClient.instance.dio.post('/admin/addCategory', data: {'name': name.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added successfully!')));
      }
      _fetchCategories();
    } on DioException catch (e) {
      _showError(e.response?.statusCode == 403
          ? '${e.response?.data ?? 'Access Denied or Duplicate Category!'}'
          : 'Failed to add category!');
    }
  }

  Future<void> _handleEditCategory(Map<String, dynamic> item) async {
    final controller = TextEditingController(text: '${item['name']}');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Update')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await ApiClient.instance.dio.put('/admin/updateCategory/${item['id']}', data: {'name': name.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category updated successfully!')));
      }
      _fetchCategories();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _showError(status == 403
          ? '${e.response?.data ?? 'Access Denied!'}'
          : status == 404
              ? 'Category not found or is a Default Category!'
              : status == 409
                  ? 'Category name already exists!'
                  : 'Failed to update category!');
    }
  }

  Future<void> _handleDeleteCategory(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${item['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE03535)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await ApiClient.instance.dio.delete('/admin/deleteCategory/${item['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res.data ?? 'Category deleted successfully!'}')));
      }
      if (_selectedCategory?['id'] == item['id']) setState(() => _selectedCategory = null);
      _fetchCategories();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _showError(status == 403
          ? '${e.response?.data ?? 'Access Denied or Category is used by items!'}'
          : status == 404
              ? 'Category not found!'
              : 'Failed to delete category!');
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

  List<Map<String, dynamic>> get _filteredCategories => _categories
      .where((c) => '${c['name'] ?? ''}'.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  List<Map<String, dynamic>> get _filteredItems => _items
      .where((i) => '${i['itemName'] ?? ''}'.toLowerCase().contains(_itemSearch.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Category'),
            bottom: const ItemsSectionTabBar(active: 'category'),
            actions: [
              if (_isAdmin)
                IconButton(icon: const Icon(Icons.add), onPressed: _handleAddCategory, tooltip: 'Add Category'),
            ],
          ),
          body: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: _categoryListPanel()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _itemsPanel()),
                  ],
                )
              : (_selectedCategory == null
                  ? _categoryListPanel()
                  : Column(
                      children: [
                        ListTile(
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setState(() => _selectedCategory = null),
                          ),
                          title: Text('${_selectedCategory!['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: _itemsPanel()),
                      ],
                    )),
        );
      },
    );
  }

  Widget _categoryListPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search...', isDense: true),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCategories.isEmpty
                  ? const Center(child: Text('No categories found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, i) {
                        final item = _filteredCategories[i];
                        final active = _selectedCategory?['id'] == item['id'];
                        return ListTile(
                          selected: active,
                          title: Text('${item['name'] ?? '—'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                child: Text('${item['itemCount'] ?? 0}', style: const TextStyle(fontSize: 10)),
                              ),
                              if (_isAdmin && !_isDefault(item))
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _handleEditCategory(item);
                                    if (v == 'delete') _handleDeleteCategory(item);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                            ],
                          ),
                          onTap: () => _selectCategory(item),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _itemsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text(
                _selectedCategory != null ? 'Items in "${_selectedCategory!['name']}"' : 'Items',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search, size: 16), hintText: 'Search items...'),
                  onChanged: (v) => setState(() => _itemSearch = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _itemsLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedCategory == null
                  ? const Center(child: Text('Select a category to view items', style: TextStyle(color: Colors.grey)))
                  : _filteredItems.isEmpty
                      ? const Center(child: Text('No items found in this category', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = _filteredItems[i];
                            final stock = (item['stock'] as Map?)?['openingStock'] ?? 0;
                            return ListTile(
                              title: Text('${item['itemName'] ?? '—'}'),
                              subtitle: Text('Code: ${item['itemCode'] ?? '—'}'),
                              trailing: Text('Stock: $stock'),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
