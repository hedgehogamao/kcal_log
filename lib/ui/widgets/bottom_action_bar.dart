import 'package:flutter/material.dart';

/// 吸底操作栏：左侧关键信息、右侧主按钮，自动避开底部安全区。
/// 放在 Scaffold.bottomNavigationBar 或 Column 尾部使用。
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.info,
    required this.actionLabel,
    this.onAction,
    this.leading,
  });

  final Widget info;
  final String actionLabel;
  final VoidCallback? onAction;

  /// 主按钮左侧的附加操作（如删除）；可空
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardTheme.color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 0.5, color: theme.dividerColor),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
