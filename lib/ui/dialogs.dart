import 'package:flutter/material.dart';

import '../logic/i18n.dart';

/// 通用数字输入对话框，返回解析后的数值（取消返回 null）
Future<double?> showNumberDialog(
  BuildContext context, {
  required String title,
  String? initial,
  String? suffix,
  String? hint,
}) {
  final ctrl = TextEditingController(text: initial ?? '');
  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
        ),
        onSubmitted: (v) => Navigator.pop(context, double.tryParse(v.trim())),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text.trim())),
          child: Text(tr(context, 'ok')),
        ),
      ],
    ),
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
            child: Text(tr(context, 'cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr(context, 'delete')),
        ),
      ],
    ),
  );
  if (ok == true) await onConfirm();
}
