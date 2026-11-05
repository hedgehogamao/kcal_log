import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/auto_backup.dart';
import '../../logic/auto_backup_controller.dart';
import '../../logic/i18n.dart';

class AutoBackupHost extends ConsumerStatefulWidget {
  const AutoBackupHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AutoBackupHost> createState() => _AutoBackupHostState();
}

class _AutoBackupHostState extends ConsumerState<AutoBackupHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(autoBackupProvider.notifier)
        .setActive(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoBackupProvider);
    return widget.child;
  }
}

class AutoBackupPanel extends ConsumerWidget {
  const AutoBackupPanel({super.key});
  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    BackupInfo info,
  ) async {
    final controller = ref.read(autoBackupProvider.notifier);
    try {
      final preview = await controller.preview(info);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => BackupRestoreDialog(preview: preview),
      );
      if (confirmed != true || !context.mounted) return;
      await controller.restore(preview);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'autoBackupRestored'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'autoBackupFailed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(autoBackupProvider),
        controller = ref.read(autoBackupProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('auto-backup-toggle'),
          title: Text(tr(context, 'autoBackupTitle')),
          subtitle: Text(tr(context, 'autoBackupSchedule')),
          value: state.enabled,
          onChanged: state.busy ? null : controller.setEnabled,
        ),
        ExpansionTile(
          key: const ValueKey('auto-backup-manage'),
          title: Text(tr(context, 'autoBackupManage')),
          onExpansionChanged: (open) {
            if (open) controller.refresh();
          },
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(context, 'autoBackupLimits')),
            if (state.busy)
              const LinearProgressIndicator(key: ValueKey('auto-backup-busy')),
            if (state.error != null)
              Text(
                tr(context, state.error!),
                key: const ValueKey('auto-backup-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (state.path != null)
              SelectableText(
                state.path!,
                key: const ValueKey('auto-backup-path'),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('auto-backup-now'),
                  onPressed: state.busy
                      ? null
                      : () => controller.check(manual: true),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(tr(context, 'autoBackupNow')),
                ),
                TextButton(
                  onPressed: state.busy ? null : controller.refresh,
                  child: Text(tr(context, 'autoBackupRefresh')),
                ),
                if (state.path != null)
                  TextButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: state.path!)),
                    child: Text(tr(context, 'copyPath')),
                  ),
              ],
            ),
            if (state.items.isEmpty) Text(tr(context, 'autoBackupEmpty')),
            for (final info in state.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  info.createdAt.toLocal().toString().split('.').first,
                ),
                subtitle: Text(
                  info.valid
                      ? '${(info.bytes / 1024).toStringAsFixed(1)} KiB'
                      : tr(context, 'autoBackupCorrupt'),
                ),
                trailing: TextButton(
                  key: ValueKey(
                    'auto-backup-restore-${info.file.uri.pathSegments.last}',
                  ),
                  onPressed: !info.valid || state.busy
                      ? null
                      : () => _restore(context, ref, info),
                  child: Text(tr(context, 'autoBackupPreview')),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key, required this.preview});
  final BackupPreview preview;
  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  bool acknowledge = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr(context, 'autoBackupPreview')),
    scrollable: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.preview.info.createdAt.toLocal().toString()),
        const SizedBox(height: 12),
        Text(tr(context, 'autoBackupRestoreWarning')),
        const SizedBox(height: 12),
        Text(tr(context, 'autoBackupDiffLegend')),
        for (final e in widget.preview.changes.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '${tr(context, 'autoTable_${e.key}')}: +${e.value.$1} / ~${e.value.$2} / −${e.value.$3}',
            ),
          ),
        CheckboxListTile(
          key: const ValueKey('auto-backup-restore-ack'),
          contentPadding: EdgeInsets.zero,
          title: Text(tr(context, 'acknowledgeImport')),
          value: acknowledge,
          onChanged: (v) => setState(() => acknowledge = v ?? false),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(tr(context, 'cancel')),
      ),
      FilledButton(
        key: const ValueKey('auto-backup-confirm-restore'),
        onPressed: acknowledge ? () => Navigator.pop(context, true) : null,
        child: Text(tr(context, 'overwriteImport')),
      ),
    ],
  );
}
