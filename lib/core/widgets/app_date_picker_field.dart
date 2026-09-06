import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../constants/app_dimensions.dart';
import '../utils/date_formatter.dart';

class AppDatePickerField extends StatelessWidget {
  final String label;
  final String? jalaliValue;
  final String? initialValueJalali;
  final ValueChanged<String?> onDateSelected;
  final bool isRequired;

  const AppDatePickerField({
    super.key,
    required this.label,
    this.jalaliValue,
    this.initialValueJalali,
    required this.onDateSelected,
    this.isRequired = false,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = Jalali.now();
    Jalali initial = now;
    final val = jalaliValue ?? initialValueJalali;
    if (val != null && val.isNotEmpty) {
      try {
        final p = val.split('/');
        initial = Jalali(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } catch (_) {}
    }

    final picked = await showPersianDatePicker(
      context: context,
      initialDate: initial,
      firstDate: Jalali(1390, 1, 1),
      lastDate: Jalali(1420, 12, 29),
    );

    if (picked != null) {
      final y = picked.year.toString();
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      onDateSelected("$y/$m/$d");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayVal = jalaliValue ?? initialValueJalali;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? "$label *" : label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isRequired ? theme.colorScheme.primary : null,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: theme.dividerColor, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayVal ?? "انتخاب تاریخ...",
                    style: TextStyle(
                      color: displayVal != null ? theme.textTheme.bodyLarge?.color : theme.hintColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (displayVal != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => onDateSelected(null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
