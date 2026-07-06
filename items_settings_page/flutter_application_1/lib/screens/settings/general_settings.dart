import 'package:flutter/material.dart';
// Import the new package
import 'package:file_picker/file_picker.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({super.key});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  // 1. STATE MANAGEMENT

  // Determines if the form fields are editable or locked
  bool _isEditing = false;

  // Controllers to store and display the selected filenames
  final _logoController = TextEditingController(text: 'Choose file...');
  final _iconController = TextEditingController(text: 'Choose file...');
  final _faviconController = TextEditingController(text: 'Choose file...');

  // 2. FILE PICKER LOGIC

  /// Opens the native file explorer to pick a single image file.
  /// Updates the provided controller with the chosen filename.
  Future<void> _pickFile(TextEditingController controller) async {
    // Only allow picking if currently in 'Edit' mode
    if (!_isEditing) return;

    try {
      // Use FilePicker to select a single file restricted to image types
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image, // Filters explorer to show only images
        allowMultiple: false,
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        // Update the state with the new filename to display it immediately
        setState(() {
          controller.text = result.files.single.name;
        });
      } else {
        // User canceled the picker dialog
        debugPrint("No file selected.");
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  // Clean up controllers when widget is destroyed
  @override
  void dispose() {
    _logoController.dispose();
    _iconController.dispose();
    _faviconController.dispose();
    super.dispose();
  }

  // 3. UI LAYOUT BUILD

  @override
  Widget build(BuildContext context) {
    // Styling constants matching previous screenshots
    const Color primaryBlueHex = Color(0xFF1E3A8A); // Blue Save button
    const Color accentGreenHex = Color(0xFF84CC16); // Green Edit/Save toggle button

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP HEADER + PRIMARY SAVE BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Settings',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlueHex),
                  onPressed: () {
                    // Logic to save non-form settings would go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings Saved!')),
                    );
                  },
                  child: const Text('Save Settings',
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Amount / Decimal configs (Locked frontend view for prototype)
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey)),
                    Text('(upto Decimal Places)',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 32),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: '2',
                    textAlign: TextAlign.center,
                    enabled: false, // Locked for this prototype iteration
                    decoration: const InputDecoration(border: UnderlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('e.g. 0.00',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),

            // SYSTEM FEATURE OPTIONS
            _buildCheckboxRow('GSTIN Number'),
            _buildCheckboxRow('Estimate/Quotation'),
            _buildCheckboxRow('SalesInvoice Order'),
            _buildCheckboxRow('OtpService'),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(),
            ),

            // LOWER SECTION: SITE SETTINGS (Dynamically lockable)
            const Text('Site Settings',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 20),

            _buildFormRow('Site Url', 'Site Url'),
            _buildFormRow('Tab title', 'Tab title'),

            // Functional File Pickers
            _buildFilePickerRow('Site Logo', _logoController),
            _buildFilePickerRow('Site Icon', _iconController),
            _buildFilePickerRow('Favicon', _faviconController),

            const SizedBox(height: 20),

            // DYNAMIC EDIT/SAVE TOGGLE BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreenHex,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  // Toggle edit state
                  setState(() {
                    _isEditing = !_isEditing;
                  });

                  // Inform user of state change
                  String message = _isEditing
                      ? 'Edit Mode Enabled: Click Browse to change files.'
                      : 'Form locked. Changes staged locally.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(message), duration: const Duration(seconds: 2)),
                  );
                },
                // Dynamic Icon and Label
                icon: Icon(_isEditing ? Icons.lock_open : Icons.edit,
                    size: 16, color: Colors.white),
                label: Text(_isEditing ? 'Confirm & Lock' : 'Edit Form',
                    style: const TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 4. HELPER WIDGETS

  /// Standard Input Field (Locked/Unlocked by _isEditing)
  Widget _buildFormRow(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: TextFormField(
              // The enabled property reacts to state change
              enabled: _isEditing,
              decoration: InputDecoration(
                hintText: hint,
                fillColor: const Color(0xFFF1F5F9),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom File Picker Input matching UI screenshots
  Widget _buildFilePickerRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
                // Visual indicator that it's locked when _isEditing is false
                color: _isEditing ? Colors.white : const Color(0xFFF1F5F9),
              ),
              child: Row(
                children: [
                  // Filename display area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        controller.text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),
                  // Functional Browse Button block
                  GestureDetector(
                    // Calls picker ONLY if editing
                    onTap: () => _pickFile(controller),
                    child: Container(
                      height: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isEditing ? Colors.grey[200] : Colors.grey[300],
                        border:
                            Border(left: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text('Browse',
                          style: TextStyle(
                              fontSize: 13,
                              // Visually gray out text if not in edit mode
                              color: _isEditing ? Colors.black87 : Colors.grey)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// System settings checkbox placeholder (static)
  Widget _buildCheckboxRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.check_box, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black87)),
          const SizedBox(width: 6),
          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
