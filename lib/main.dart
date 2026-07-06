import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'signature_picker.dart';

void main() {
  runApp(const BusinessDetailsApp());
}

class BusinessDetailsApp extends StatelessWidget {
  const BusinessDetailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008FCF),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const BusinessDetailsPage(),
    );
  }
}

class BusinessDetailsPage extends StatelessWidget {
  const BusinessDetailsPage({super.key});

  static const double _columnGap = 40;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool stacked = constraints.maxWidth < 900;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LogoPlaceholder(),
                    const SizedBox(height: 40),
                    if (stacked)
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BusinessDetailsColumn(),
                          SizedBox(height: 36),
                          _MoreDetailsColumn(),
                          SizedBox(height: 36),
                          _BusinessAddressColumn(),
                        ],
                      )
                    else
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _BusinessDetailsColumn()),
                          SizedBox(width: _columnGap),
                          Expanded(child: _MoreDetailsColumn()),
                          SizedBox(width: _columnGap),
                          Expanded(child: _BusinessAddressColumn()),
                        ],
                      ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 170,
                      height: 50,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF008FCF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessDetailsColumn extends StatelessWidget {
  const _BusinessDetailsColumn();

  @override
  Widget build(BuildContext context) {
    return const _FormColumn(
      title: 'Business Details',
      children: [
        CustomTextField(label: 'Business Name *', hintText: 'Enter Business Name'),
        CustomTextField(label: 'Phone Number', hintText: 'Enter Phone Number'),
        CustomTextField(label: 'GSTIN', hintText: 'Enter GSTIN'),
        CustomTextField(label: 'Email ID', hintText: 'Enter Email ID'),
      ],
    );
  }
}

class _MoreDetailsColumn extends StatelessWidget {
  const _MoreDetailsColumn();

  @override
  Widget build(BuildContext context) {
    return const _FormColumn(
      title: 'More Details',
      children: [
        CustomDropdown(
          label: 'Business Type',
          hintText: 'Select Business Type',
          options: [
            'Sole Proprietorship',
            'Partnership',
            'Limited Liability Partnership',
            'Private Limited Company',
            'Public Limited Company',
          ],
        ),
        CustomDropdown(
          label: 'Business Category',
          hintText: 'Select Business Category',
          options: [
            'Retail',
            'Wholesale',
            'Manufacturing',
            'Services',
            'Food and Beverage',
            'Healthcare',
            'Education',
            'Technology',
          ],
        ),
        CustomDropdown(
          label: 'State',
          hintText: 'Select State',
          options: [
            'Andhra Pradesh',
            'Arunachal Pradesh',
            'Assam',
            'Bihar',
            'Chhattisgarh',
            'Delhi',
            'Goa',
            'Gujarat',
            'Haryana',
            'Himachal Pradesh',
            'Jharkhand',
            'Karnataka',
            'Kerala',
            'Madhya Pradesh',
            'Maharashtra',
            'Odisha',
            'Punjab',
            'Rajasthan',
            'Tamil Nadu',
            'Telangana',
            'Uttar Pradesh',
            'West Bengal',
          ],
        ),
        CustomTextField(label: 'Pincode', hintText: 'Enter Pincode'),
      ],
    );
  }
}

class _BusinessAddressColumn extends StatelessWidget {
  const _BusinessAddressColumn();

  @override
  Widget build(BuildContext context) {
    return const _FormColumn(
      title: 'Business Address',
      children: [
        CustomTextField(
          label: 'Business Address',
          hintText: 'Enter Business Address',
          maxLines: 5,
          height: 150,
        ),
        UploadSignatureBox(),
      ],
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF008FCF),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
    this.height = 48,
  });

  final String label;
  final String hintText;
  final int maxLines;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: SizedBox(
        height: height,
        child: TextField(
          minLines: maxLines > 1 ? null : 1,
          maxLines: maxLines > 1 ? null : 1,
          expands: maxLines > 1,
          textAlignVertical: maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
          style: const TextStyle(fontSize: 14, letterSpacing: 0),
          decoration: _fieldDecoration(hintText).copyWith(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.options,
  });

  final String label;
  final String hintText;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: SizedBox(
        height: 48,
        child: DropdownButtonFormField<String>(
          value: null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 24,
            color: Color(0xFF555555),
          ),
          items:
              options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (_) {},
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 14,
            letterSpacing: 0,
          ),
          decoration: _fieldDecoration(hintText).copyWith(
            contentPadding: const EdgeInsets.only(left: 14, right: 10),
          ),
          hint: Text(
            hintText,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class UploadSignatureBox extends StatefulWidget {
  const UploadSignatureBox({super.key});

  @override
  State<UploadSignatureBox> createState() => _UploadSignatureBoxState();
}

class _UploadSignatureBoxState extends State<UploadSignatureBox> {
  Uint8List? _signatureBytes;

  Future<void> _pickSignature() async {
    final bytes = await pickSignatureImage();
    if (bytes == null) return;

    setState(() {
      _signatureBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Signature',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickSignature,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD6D6D6)),
            ),
            child:
                _signatureBytes == null
                    ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_upload_outlined,
                            color: Color(0xFF6F6F6F),
                            size: 34,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload Signature',
                            style: TextStyle(
                              color: Color(0xFF6F6F6F),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.memory(
                        _signatureBytes!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
          ),
        ),
        if (_signatureBytes != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _pickSignature,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Change'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF008FCF),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _LogoPlaceholder extends StatefulWidget {
  const _LogoPlaceholder();

  @override
  State<_LogoPlaceholder> createState() => _LogoPlaceholderState();
}

class _LogoPlaceholderState extends State<_LogoPlaceholder> {
  Uint8List? _logoBytes;

  Future<void> _pickLogo() async {
    final bytes = await pickSignatureImage();
    if (bytes == null) return;

    setState(() {
      _logoBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickLogo,
      customBorder: const CircleBorder(),
      child: Container(
        width: 90,
        height: 90,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F1F1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child:
            _logoBytes == null
                ? const Text(
                  'Add\nLogo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                )
                : Image.memory(
                  _logoBytes!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hintText) {
  const borderColor = Color(0xFFD6D6D6);

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: Color(0xFF9E9E9E),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF008FCF), width: 1.2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: borderColor),
    ),
  );
}
