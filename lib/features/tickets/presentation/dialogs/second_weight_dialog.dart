import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/weight_input_field.dart';

class SecondWeightDialog extends StatefulWidget {
  final int ticketId;
  final String serialNumber;
  final double firstWeight;
  final Future<void> Function(double weight, double? lossPercent) onSubmit;

  const SecondWeightDialog({
    super.key,
    required this.ticketId,
    required this.serialNumber,
    required this.firstWeight,
    required this.onSubmit,
  });

  @override
  State<SecondWeightDialog> createState() => _SecondWeightDialogState();
}

class _SecondWeightDialogState extends State<SecondWeightDialog> {
  final _weightController = TextEditingController();
  final _lossController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _weightController.dispose();
    _lossController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final clean = _weightController.text.replaceAll(',', '').trim();
    final weight = double.tryParse(clean);
    if (weight == null || weight <= 0) {
      setState(() => _error = "لطفاً مقدار معتبر وزن دوم را وارد کنید.");
      return;
    }

    double? lossPct;
    if (_lossController.text.trim().isNotEmpty) {
      lossPct = double.tryParse(_lossController.text.trim());
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(weight, lossPct);
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ثبت وزن دوم - قبض ${widget.serialNumber}", style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              WeightInputField(
                label: "مقدار وزن دوم (باسکول)",
                controller: _weightController,
                isRequired: true,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _lossController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "درصد افت (اختیاری)",
                  hintText: "مثلاً 1.5",
                  suffixText: "%",
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("تکمیل قبض و محاسبه اوزان", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
