import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/app_dimensions.dart';

class WeightInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final bool isRequired;
  final bool isReadOnly;
  final ValueChanged<String>? onChanged;

  const WeightInputField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.isRequired = false,
    this.isReadOnly = false,
    this.onChanged,
  });

  @override
  State<WeightInputField> createState() => _WeightInputFieldState();
}

class _WeightInputFieldState extends State<WeightInputField> {
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  void _formatInput(String val) {
    final clean = val.replaceAll(',', '').trim();
    if (clean.isEmpty) {
      widget.onChanged?.call('');
      return;
    }
    final numVal = int.tryParse(clean);
    if (numVal != null) {
      final formatted = _formatter.format(numVal);
      if (formatted != widget.controller.text) {
        widget.controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      widget.onChanged?.call(clean);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(widget.label, style: theme.textTheme.titleSmall)),
            if (widget.isRequired)
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          readOnly: widget.isReadOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: "مقدار وزن را وارد کنید",
            suffixText: "کیلوگرم",
            errorText: widget.errorText,
            prefixIcon: const Icon(Icons.scale_rounded, size: 20),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          onChanged: _formatInput,
        ),
      ],
    );
  }
}
