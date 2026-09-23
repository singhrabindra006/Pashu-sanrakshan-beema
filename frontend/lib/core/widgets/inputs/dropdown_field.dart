import 'package:flutter/material.dart';

/// Thin wrapper so every dropdown in the app shares the input decoration.
class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.itemLabel,
    this.prefixIcon,
    this.hint,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabel;
  final IconData? prefixIcon;
  final String? hint;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel?.call(item) ?? item.toString(), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }
}

/// Read-only field that opens a date picker; keeps date entry consistent.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '' : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (field) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled
            ? () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? now,
                  firstDate: firstDate ?? DateTime(now.year - 10),
                  lastDate: lastDate ?? DateTime(now.year + 10),
                );
                if (picked != null) {
                  field.didChange(picked);
                  onChanged(picked);
                }
              }
            : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            enabled: enabled,
          ),
          isEmpty: value == null,
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
