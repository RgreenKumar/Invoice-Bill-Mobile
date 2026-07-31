import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

/// Port of `src/UserSettings/WeightageSetting.js`, routed at
/// `/settings/Weightage`.
///
/// Preserves:
///  - GET /get/Weightage on load (200 = shown read-only, 204 = none saved
///    yet, starts in edit mode)
///  - POST /save/Weightage on save
///  - Live validation: no single weight can push the total (test + quiz +
///    attendance + assignment) over 100
///  - 401/403 -> redirect to /unauthorized
class WeightageSettingsScreen extends StatefulWidget {
  const WeightageSettingsScreen({super.key});

  @override
  State<WeightageSettingsScreen> createState() => _WeightageSettingsScreenState();
}

class _WeightageSettingsScreenState extends State<WeightageSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _notFound = true;

  int _passingPercentage = 60;
  final Map<String, int> _weights = {'test': 80, 'quiz': 10, 'attendance': 5, 'assignment': 5};

  static const _labels = {
    'test': 'Test (+ Module Test) Weightage (%)',
    'quiz': 'Quiz Weightage (%)',
    'attendance': 'Attendance Weightage (%)',
    'assignment': 'Assignment Weightage (%)',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/get/Weightage');
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        setState(() {
          _notFound = false;
          _passingPercentage = (data['passPercentage'] as num?)?.toInt() ?? 60;
          _weights
            ..['test'] = (data['testWeightage'] as num?)?.toInt() ?? 80
            ..['quiz'] = (data['quizzWeightage'] as num?)?.toInt() ?? 10
            ..['attendance'] = (data['attendanceWeightage'] as num?)?.toInt() ?? 5
            ..['assignment'] = (data['assignmentWeightage'] as num?)?.toInt() ?? 5;
        });
      } else if (res.statusCode == 204) {
        setState(() => _notFound = true);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if ((status == 401 || status == 403) && mounted) context.go('/unauthorized');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleWeightChange(String key, int newValue) {
    if (newValue < 0 || newValue > 100) return;
    final totalExcluding = _weights.entries.where((e) => e.key != key).fold<int>(0, (s, e) => s + e.value);
    if (totalExcluding + newValue > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total weightage cannot exceed 100%!')),
      );
      return;
    }
    setState(() => _weights[key] = newValue);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiClient.instance.dio.post('/save/Weightage', data: {
        'passPercentage': _passingPercentage,
        'testWeightage': _weights['test'],
        'quizzWeightage': _weights['quiz'],
        'assignmentWeightage': _weights['assignment'],
        'attendanceWeightage': _weights['attendance'],
      });
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved'),
            content: const Text('Weightage settings saved successfully'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        _load();
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (mounted) {
        if (status == 400) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${e.response?.data ?? 'Invalid weightage values'}')));
        } else if (status == 401 || status == 403) {
          context.go('/unauthorized');
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Failed to save weightage settings')));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grade Weightage')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _numberField('Passing Percentage (%)', _passingPercentage,
                    (v) => setState(() => _passingPercentage = v.clamp(0, 100))),
                for (final key in _weights.keys)
                  _numberField(_labels[key]!, _weights[key]!, (v) => _handleWeightChange(key, v)),
                const SizedBox(height: 16),
                if (!_notFound)
                  FilledButton.tonal(
                    onPressed: () => setState(() => _notFound = true),
                    child: const Text('Edit'),
                  )
                else
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
              ],
            ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 70,
            child: TextFormField(
              enabled: _notFound,
              initialValue: '$value',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            ),
          ),
        ],
      ),
    );
  }
}
