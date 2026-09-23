import 'package:flutter/material.dart';

/// Single-field dialog. Used for "Edit phone", "Rejection reason" and
/// "Approved amount", so the validation rules travel with the caller.
class InputDialog extends StatefulWidget {
  const InputDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue,
    this.hint,
    this.helper,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.confirmLabel = 'Save',
    this.isDestructive = false,
  });

  final String title;
  final String label;
  final String? initialValue;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final String confirmLabel;
  final bool isDestructive;

  /// Resolves to the trimmed text, or null when dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String label,
    String? initialValue,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String confirmLabel = 'Save',
    bool isDestructive = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => InputDialog(
        title: title,
        label: label,
        initialValue: initialValue,
        hint: hint,
        helper: helper,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          validator: widget.validator,
          textInputAction: widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
          onFieldSubmitted: widget.maxLines > 1 ? null : (_) => _submit(),
          decoration: InputDecoration(labelText: widget.label, hintText: widget.hint, helperText: widget.helper),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
            backgroundColor: widget.isDestructive ? scheme.error : null,
          ),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
