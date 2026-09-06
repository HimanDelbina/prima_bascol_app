import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';

class TicketCorrectDialog extends StatefulWidget {
  final int ticketId;
  final String serialNumber;
  final Future<void> Function(String field, String newValue, String reason) onCorrect;

  const TicketCorrectDialog({
    super.key,
    required this.ticketId,
    required this.serialNumber,
    required this.onCorrect,
  });

  @override
  State<TicketCorrectDialog> createState() => _TicketCorrectDialogState();
}

class _TicketCorrectDialogState extends State<TicketCorrectDialog> {
  String _selectedField = 'first_weight';
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  final Map<String, String> _fields = {
    'first_weight': 'وزن اول',
    'second_weight': 'وزن دوم',
    'sent_weight': 'وزن ارسالی',
    'loss_percent': 'درصد افت',
    'loss_weight': 'وزن افت',
    'license_plate_display': 'شماره پلاک',
    'waybill_number': 'شماره بارنامه',
  };

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final val = _valueController.text.trim();
    final reason = _reasonController.text.trim();

    if (val.isEmpty || reason.length < 3) {
      setState(() => _error = "مقدار جدید و دلیل اصلاح (حداقل ۳ حرف) اجباری هستند.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onCorrect(_selectedField, val, reason);
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
                  Text("اصلاح مدیریتی قبض ${widget.serialNumber}", style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              DropdownButtonFormField<String>(
                value: _selectedField,
                decoration: const InputDecoration(labelText: "فیلد مورد نظر جهت اصلاح"),
                items: _fields.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedField = val);
                },
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: "مقدار جدید *",
                  hintText: "مقدار جایگزین را وارد کنید",
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "دلیل اصلاح مدیریتی (ثبت در ممیزی) *",
                  hintText: "علت تغییر را بنویسید...",
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("ثبت اصلاحیه و محاسبه مجدد"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
