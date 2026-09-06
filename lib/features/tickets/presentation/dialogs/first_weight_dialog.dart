import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/weight_input_field.dart';

class FirstWeightDialog extends StatefulWidget {
  final int ticketId;
  final String serialNumber;
  final double currentWeight;
  final Future<void> Function(double weight) onSubmit;

  const FirstWeightDialog({
    super.key,
    required this.ticketId,
    required this.serialNumber,
    required this.currentWeight,
    required this.onSubmit,
  });

  @override
  State<FirstWeightDialog> createState() => _FirstWeightDialogState();
}

class _FirstWeightDialogState extends State<FirstWeightDialog> {
  late final TextEditingController _weightController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.currentWeight > 0 ? widget.currentWeight.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final clean = _weightController.text.replaceAll(',', '').trim();
    final weight = double.tryParse(clean);
    if (weight == null || weight <= 0) {
      setState(() => _error = "لطفاً مقدار معتبر وزن اول را وارد کنید.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(weight);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ثبت وزن اول - قبض ${widget.serialNumber}", style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              WeightInputField(
                label: "مقدار وزن اول (باسکول)",
                controller: _weightController,
                isRequired: true,
              ),
              const SizedBox(height: AppDimensions.lg),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("ثبت و ارسال به سرور", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
