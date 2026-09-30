import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// 日期+时间自动分隔：输入 202609131430 → 2026-09-13 14:30
class DateTimeInputFormatter extends TextInputFormatter {
  const DateTimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 12; i++) {
      buf.write(digits[i]);
      if (i == 3 || i == 5) {
        buf.write('-');
      } else if (i == 7) {
        buf.write(' ');
      } else if (i == 9) {
        buf.write(':');
      }
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }
}

/// 是否为完整输入（yyyy-MM-dd HH:mm）
bool isCompleteDateTime(String s) =>
    RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(s);

/// 校验各部分取值（月 1-12、日不超过当月天数、时 0-23、分 0-59）
bool dateTimePartsValid(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$').firstMatch(s);
  if (m == null) return false;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final h = int.parse(m.group(4)!);
  final mi = int.parse(m.group(5)!);
  if (mo < 1 || mo > 12 || d < 1 || h > 23 || mi > 59) return false;
  return d <= DateTime(y, mo + 1, 0).day;
}

/// 智能输入框：带格式化，右侧常驻单位与字数统计。
class SmartField extends StatefulWidget {
  const SmartField({
    super.key,
    required this.label,
    this.hint,
    this.unit,
    this.unitIcon,
    this.maxLength = 16,
    this.showCounter = true,
    this.errorText,
    this.enabled = true,
    this.formatters = const [],
    this.validator,
    this.onChanged,
    this.controller,
    this.autofocus = false,
    this.keyboardType,
  });

  final String label;
  final String? hint;
  final String? unit;
  final IconData? unitIcon;
  final int maxLength;
  final bool showCounter;
  final String? errorText;
  final bool enabled;
  final List<TextInputFormatter> formatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  /// 外部控制器（如需在别处读写输入值）；不传则内部自建
  final TextEditingController? controller;
  final bool autofocus;
  final TextInputType? keyboardType;

  @override
  State<SmartField> createState() => _SmartFieldState();
}

class _SmartFieldState extends State<SmartField> {
  TextEditingController? _ownCtrl;

  TextEditingController get _ctrl =>
      widget.controller ?? (_ownCtrl ??= TextEditingController());

  @override
  void dispose() {
    _ownCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final soft = LabelColors.inkSoftOf(dark);
    return TextFormField(
      controller: _ctrl,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType ?? TextInputType.number,
      inputFormatters: [
        ...widget.formatters,
        LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      validator: widget.validator,
      onChanged: (v) {
        setState(() {});
        widget.onChanged?.call(v);
      },
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: 3,
        hintText: widget.hint,
        // 右侧常驻：单位 + 字数
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.unitIcon != null)
                Icon(widget.unitIcon, size: 16, color: soft),
              if (widget.unitIcon != null && widget.unit != null)
                const SizedBox(width: 4),
              if (widget.unit != null)
                Text(widget.unit!, style: TextStyle(fontSize: 13, color: soft)),
              if (widget.showCounter) const SizedBox(width: 8),
              if (widget.showCounter)
                Text(
                  '${_ctrl.text.length}/${widget.maxLength}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: soft,
                  ),
                ),
            ],
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
