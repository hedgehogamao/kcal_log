import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/i18n.dart';
import '../../logic/providers.dart';

/// 右上角一键切换语言按钮：中 → EN → ES 循环，选择持久保存
class LangButton extends ConsumerWidget {
  const LangButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).lang;
    return Tooltip(
      message: tr(context, 'langTip'),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => ref.read(settingsProvider.notifier).setLang(lang.next),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            lang.short,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
