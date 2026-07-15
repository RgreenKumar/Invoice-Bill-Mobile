import 'package:flutter/material.dart';
import '../../../app_feature_settings.dart';

class TaxSettings extends StatefulWidget {
  const TaxSettings({super.key});

  @override
  State<TaxSettings> createState() => _TaxSettingsState();
}

class _TaxSettingsState extends State<TaxSettings> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppFeatureSettings>(
      valueListenable: appFeatureSettings,
      builder: (context, settings, _) {
        return Container(
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.all(32.0),
          alignment: Alignment.topLeft,
          child: Container(
            width: 450,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'GST Settings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Master Top-Level Checkbox Row
                      _buildInteractiveGstRow(
                        'Enable GST',
                        settings.enableGst,
                        (val) =>
                            _update(settings.copyWith(enableGst: val ?? false)),
                      ),

                      // Dynamic Visibility Container matching your conditional logic rule
                      AnimatedCrossFade(
                        firstChild: const SizedBox(height: 0),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              _buildInteractiveGstRow(
                                'Enable HSN/SAC Code',
                                settings.enableHsn,
                                (val) => _update(
                                  settings.copyWith(enableHsn: val ?? false),
                                ),
                              ),
                              _buildInteractiveGstRow(
                                'Additional Cess On Item',
                                settings.additionalCess,
                                (val) => _update(
                                  settings.copyWith(
                                    additionalCess: val ?? false,
                                  ),
                                ),
                              ),
                              _buildInteractiveGstRow(
                                'Enable Place of Supply',
                                settings.enablePlaceOfSupply,
                                (val) => _update(
                                  settings.copyWith(
                                    enablePlaceOfSupply: val ?? false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: settings.enableGst
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF84CC16,
                            ), // Light green accent hex brand style
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'GST configuration matrix successfully cached.',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildInteractiveGstRow(
    String title,
    bool isChecked,
    ValueChanged<bool?> onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: onToggle,
            activeColor: Colors.blueGrey,
          ),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isChecked ? Colors.black87 : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
