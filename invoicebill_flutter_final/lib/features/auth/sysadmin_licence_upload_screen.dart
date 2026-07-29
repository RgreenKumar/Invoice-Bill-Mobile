import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

/// Port of `src/AuthenticationPages/SysadminLicenceupload.js`.
///
/// Preserves: `.xml`-only file picker, `POST /api/Sysadmin/uploadLicence`
/// as multipart form data (field name `audioFile`, matching the original
/// - kept as-is even though the field name is clearly a copy/paste
/// leftover, since the backend contract must match exactly), success
/// dialog with a "Reload" action, and a distinct message for 401s.
class SysadminLicenceUploadScreen extends StatefulWidget {
  const SysadminLicenceUploadScreen({super.key});

  @override
  State<SysadminLicenceUploadScreen> createState() => _SysadminLicenceUploadScreenState();
}

class _SysadminLicenceUploadScreenState extends State<SysadminLicenceUploadScreen> {
  PlatformFile? _selectedFile;
  bool _submitting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) return;
    setState(() => _submitting = true);
    try {
      final formData = dio.FormData.fromMap({
        // Field name kept as "audioFile" to match the original request
        // exactly, even though it's a copy/paste leftover from an
        // unrelated upload form.
        'audioFile': dio.MultipartFile.fromBytes(
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      });
      final res = await ApiClient.instance.dio.post('/api/Sysadmin/uploadLicence', data: formData);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Licence Updated!'),
            content: const Text('Licence Have been updated successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Reload'),
              ),
            ],
          ),
        );
      }
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Error!'),
            content: const Text('you are unAuthorized to access this page'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
      } else {
        rethrow;
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licence Upload')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add New License File'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose file...'),
                ),
                if (_selectedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Selected File : ${_selectedFile!.name}'),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_selectedFile == null || _submitting) ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
