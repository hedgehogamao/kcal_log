import 'package:flutter/material.dart';

import '../logic/i18n.dart';

/// Cancel returns null; an explicit clear action returns zero.
Future<double?> showNumberDialog(
  BuildContext context, {
  required String title,
  String? initial,
  String? suffix,
  String? hint,
  bool allowClear = false,
  double minimum = 0,
  double maximum = 10000000,
}) => showDialog<double>(
  context: context,
  builder: (_) => _NumberDialog(
    title: title,
    initial: initial,
    suffix: suffix,
    hint: hint,
    allowClear: allowClear,
    maximum: maximum,
    minimum: minimum,
  ),
);

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    this.initial,
    this.suffix,
    this.hint,
    required this.allowClear,
    required this.maximum,
    required this.minimum,
  });
  final String title;
  final String? initial, suffix, hint;
  final bool allowClear;
  final double maximum;
  final double minimum;
  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (widget.allowClear && _controller.text.trim().isEmpty) {
      Navigator.pop(context, 0.0);
      return;
    }
    if (value == null ||
        !value.isFinite ||
        value <= 0 ||
        value < widget.minimum ||
        value > widget.maximum) {
      setState(
        () => _error = tr(
          context,
          widget.minimum > 0 ? 'validNumberBounds' : 'validNumberRange',
          {
            'min': '${widget.minimum}',
            'max': '${widget.maximum}',
            'unit': widget.suffix ?? '',
          },
        ),
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    scrollable: true,
    content: TextField(
      key: const ValueKey('number-input'),
      controller: _controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixText: widget.suffix,
        errorText: _error,
        errorMaxLines: 12,
      ),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      if (widget.allowClear)
        TextButton(
          onPressed: () => Navigator.pop(context, 0.0),
          child: Text(tr(context, 'clearGoal')),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr(context, 'cancel')),
      ),
      FilledButton(onPressed: _submit, child: Text(tr(context, 'ok'))),
    ],
  );
}

Future<void> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required Future<void> Function() onConfirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr(context, 'cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr(context, 'delete')),
        ),
      ],
    ),
  );
  if (ok == true) await onConfirm();
}
