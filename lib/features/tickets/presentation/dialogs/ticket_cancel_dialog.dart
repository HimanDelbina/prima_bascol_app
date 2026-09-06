import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';

class TicketCancelDialog extends StatefulWidget {
  final int ticketId;
  final String serialNumber;
  final Future<void> Function(String reason) onCancel;

  const TicketCancelDialog({
    super.key,
    required this.ticketId,
    required this.serialNumber,
    required this.onCancel,
  });

  @override
  State<TicketCancelDialog> createState() => _TicketCancelDialogState();
}

class _TicketCancelDialogState extends State<TicketCancelDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.length < 3) {
      setState(() => _error = "وارد کردن دلیل ابطال (حداقل ۳ حرف) اجباری است.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onCancel(reason);
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      title: Text("ابطال قبض شماره ${widget.serialNumber}", style: const TextStyle(color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("سند ابطال خواهد شد و امکان بازگشت آن وجود ندارد."),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "دلیل ابطال سند *",
              hintText: "علت ابطال این قبض را شرح دهید...",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("انصراف"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white))
              : const Text("ابطال قطعی سند"),
        ),
      ],
    );
  }
}
