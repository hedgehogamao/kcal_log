import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
import '../theme.dart';
import '../widgets/lang_button.dart';
import '../widgets/slide_to_confirm.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _saveGoal(String column, double? v) async {
    await ref.read(dbProvider).saveProfile(
          switch (column) {
            'kcal' => ProfilesCompanion(id: const Value(1), kcalGoal: Value(v)),
            'protein' =>
              ProfilesCompanion(id: const Value(1), proteinGoal: Value(v)),
            'fat' => ProfilesCompanion(id: const Value(1), fatGoal: Value(v)),
            _ => ProfilesCompanion(id: const Value(1), carbGoal: Value(v)),
          },
        );
  }

  Future<void> _editGoal(
      String title, String column, double? current, String suffix) async {
    final v = await showNumberDialog(
      context,
      title: title,
      initial: current == null ? null : round1(current).toString(),
      suffix: suffix,
      hint: tr(context, 'clearHint'),
    );
    if (v == null) return;
    await _saveGoal(column, v <= 0 ? null : v);
  }

  Future<void> _export() async {
    // await 之后不允许再用 context 取文案，提前快照语言
    final lang = LangScope.of(context);
    try {
      final db = ref.read(dbProvider);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(await db.exportJson());
      final name = 'kcallog-backup-${dateKey(DateTime.now())}.json';
      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          fileName: name,
          bytes: Uint8List.fromList(utf8.encode(jsonStr)),
        );
      } catch (_) {
        savedPath = null; // iOS 等平台不支持另存为
      }
      if (savedPath != null) {
        _toast(t(lang, 'exportedTo', {'p': savedPath}));
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(jsonStr);
      await Clipboard.setData(ClipboardData(text: file.path));
      _toast(
          '${t(lang, 'exportedTo', {'p': file.path})}\n${t(lang, 'pathCopied')}');
    } catch (e) {
      _toast('${t(lang, 'exportFail')}: $e');
    }
  }

  Future<void> _import() async {
    final lang = LangScope.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        _toast(t(lang, 'readFail'));
        return;
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic> || json['app'] != 'kcal_log') {
        _toast(t(lang, 'notBackup'));
        return;
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t(lang, 'importConfirmTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t(lang, 'importConfirmBody')),
              const SizedBox(height: 16),
              // 覆盖导入不可逆：滑动 80% 确认，不足回弹
              SlideToConfirm(
                label: t(lang, 'slideImportLabel'),
                successLabel: t(lang, 'overwriteImport'),
                onConfirm: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(t(lang, 'cancel'))),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(dbProvider).importJson(json);
      ref.invalidate(entriesProvider);
      ref.invalidate(entriesRangeProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(weightsProvider);
      ref.invalidate(waterProvider);
      ref.invalidate(templatesProvider);
      _toast(t(lang, 'importDone'));
    } catch (e) {
      _toast('${t(lang, 'importFail')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabSettings')),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionTitle(tr(context, 'secGoals')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: Text(tr(context, 'kcalGoalRow')),
                  subtitle: Text(
                    profile?.kcalGoal == null
                        ? tr(context, 'goalUnset')
                        : '${round1(profile!.kcalGoal!)} kcal',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGoal(tr(context, 'kcalGoalRow'), 'kcal',
                      profile?.kcalGoal, 'kcal'),
                ),
                ListTile(
                  leading: const Icon(Icons.egg_outlined),
                  title: Text(tr(context, 'proteinGoal')),
                  subtitle: Text(profile?.proteinGoal == null
                      ? tr(context, 'unsetDefault', {'p': '20'})
                      : '${round1(profile!.proteinGoal!)} g'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGoal(tr(context, 'proteinGoal'),
                      'protein', profile?.proteinGoal, 'g'),
                ),
                ListTile(
                  leading: const Icon(Icons.opacity_outlined),
                  title: Text(tr(context, 'fatGoal')),
                  subtitle: Text(profile?.fatGoal == null
                      ? tr(context, 'unsetDefault', {'p': '25'})
                      : '${round1(profile!.fatGoal!)} g'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGoal(
                      tr(context, 'fatGoal'), 'fat', profile?.fatGoal, 'g'),
                ),
                ListTile(
                  leading: const Icon(Icons.grain),
                  title: Text(tr(context, 'carbGoal')),
                  subtitle: Text(profile?.carbGoal == null
                      ? tr(context, 'unsetDefault', {'p': '55'})
                      : '${round1(profile!.carbGoal!)} g'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGoal(
                      tr(context, 'carbGoal'), 'carb', profile?.carbGoal, 'g'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(tr(context, 'estimateByProfile')),
                  subtitle: Text(tr(context, 'profileSub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                      context: context,
                      builder: (_) => _ProfileDialog(profile: profile)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(tr(context, 'secAppearance')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bolt_outlined),
                  title: Text(tr(context, 'useKj')),
                  subtitle: Text(tr(context, 'useKjSub')),
                  trailing: CupertinoSwitch(
                    value: settings.useKj,
                    onChanged: ref.read(settingsProvider.notifier).setUseKj,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(tr(context, 'appearance')),
                  trailing: CupertinoSlidingSegmentedControl<ThemeMode>(
                    groupValue: settings.themeMode,
                    onValueChanged: (m) => ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(m ?? ThemeMode.system),
                    thumbColor: const CupertinoDynamicColor.withBrightness(
                      color: Color(0xFFFFFFFF),
                      darkColor: Color(0xFF636366),
                    ),
                    children: {
                      ThemeMode.system: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Text(tr(context, 'system'),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      ThemeMode.light: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Text(tr(context, 'light'),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      ThemeMode.dark: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Text(tr(context, 'dark'),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.local_drink_outlined),
                  title: Text(tr(context, 'waterGoal')),
                  subtitle: Text(
                      tr(context, 'perDay', {'n': '${settings.waterGoalMl}'})),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final v = await showNumberDialog(
                      context,
                      title: tr(context, 'waterGoal'),
                      initial: settings.waterGoalMl.toString(),
                      suffix: 'ml',
                    );
                    if (v != null && v > 0) {
                      ref
                          .read(settingsProvider.notifier)
                          .setWaterGoal(v.round());
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(tr(context, 'secData')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(tr(context, 'exportTitle')),
                  subtitle: Text(tr(context, 'exportSub')),
                  onTap: _export,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(tr(context, 'importTitle')),
                  subtitle: Text(tr(context, 'importSub')),
                  onTap: _import,
                ),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(tr(context, 'storageLoc')),
                  subtitle: FutureBuilder<Directory>(
                    future: getApplicationSupportDirectory(),
                    builder: (context, snap) => Text(
                      snap.data == null
                          ? tr(context, 'appDataDir')
                          : snap.data!.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(tr(context, 'secAbout')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr(context, 'appName')} v0.1.0',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    tr(context, 'aboutBody'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: captionStyle(context)),
      );
}

/// 个人资料与 TDEE 估算
class _ProfileDialog extends ConsumerStatefulWidget {
  const _ProfileDialog({this.profile});

  final Profile? profile;

  @override
  ConsumerState<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<_ProfileDialog> {
  Sex? _sex;
  ActivityLevel _activity = ActivityLevel.moderate;
  late final TextEditingController _birthYear;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  bool _applyEstimate = true;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _sex = p?.sex;
    _activity = p?.activity ?? ActivityLevel.moderate;
    _birthYear = TextEditingController(text: p?.birthYear?.toString());
    _height = TextEditingController(text: p?.heightCm == null ? '' : round1(p!.heightCm!).toString());
    _weight = TextEditingController(text: p?.weightKg == null ? '' : round1(p!.weightKg!).toString());
    for (final c in [_birthYear, _height, _weight]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _birthYear.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? get _tdee {
    final year = int.tryParse(_birthYear.text.trim());
    final h = double.tryParse(_height.text.trim());
    final w = double.tryParse(_weight.text.trim());
    return estimateTdee(
      sex: _sex,
      birthYear: year,
      heightCm: h,
      weightKg: w,
      activity: _activity,
    );
  }

  Future<void> _save() async {
    final year = int.tryParse(_birthYear.text.trim());
    final h = double.tryParse(_height.text.trim());
    final w = double.tryParse(_weight.text.trim());
    final db = ref.read(dbProvider);
    await db.saveProfile(ProfilesCompanion(
      id: const Value(1),
      sex: Value(_sex),
      birthYear: Value(year),
      heightCm: Value(h),
      weightKg: Value(w),
      activity: Value(_activity),
    ));
    if (_applyEstimate && _tdee != null) {
      final (p, f, c) = defaultMacroGoals(_tdee!);
      await db.saveProfile(ProfilesCompanion(
        id: const Value(1),
        kcalGoal: Value(_tdee),
        proteinGoal: Value(p),
        fatGoal: Value(f),
        carbGoal: Value(c),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tdee = _tdee;
    return AlertDialog(
      title: Text(tr(context, 'profileTitle')),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoSlidingSegmentedControl<Sex>(
                groupValue: _sex ?? Sex.male,
                onValueChanged: (s) => setState(() => _sex = s),
                thumbColor: const CupertinoDynamicColor.withBrightness(
                  color: Color(0xFFFFFFFF),
                  darkColor: Color(0xFF636366),
                ),
                children: {
                  Sex.male: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                    child: Text(tr(context, 'male'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Sex.female: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                    child: Text(tr(context, 'female'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _birthYear,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: tr(context, 'birthYear'),
                        hintText: tr(context, 'eg1990')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: tr(context, 'heightCm')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: tr(context, 'weightKg')),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: _activity,
                decoration:
                    InputDecoration(labelText: tr(context, 'activityLevel')),
                items: [
                  DropdownMenuItem(
                      value: ActivityLevel.sedentary,
                      child: Text(tr(context, 'actSedentary'))),
                  DropdownMenuItem(
                      value: ActivityLevel.light,
                      child: Text(tr(context, 'actLight'))),
                  DropdownMenuItem(
                      value: ActivityLevel.moderate,
                      child: Text(tr(context, 'actModerate'))),
                  DropdownMenuItem(
                      value: ActivityLevel.high,
                      child: Text(tr(context, 'actHigh'))),
                ],
                onChanged: (v) => setState(() => _activity = v ?? _activity),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tdee == null
                      ? tr(context, 'tdeeHint')
                      : tr(context, 'tdeeIs', {'n': '${round1(tdee)}'}),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              if (tdee != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(context, 'applyEstimate')),
                  value: _applyEstimate,
                  onChanged: (v) => setState(() => _applyEstimate = v ?? true),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel'))),
        FilledButton(onPressed: _save, child: Text(tr(context, 'save'))),
      ],
    );
  }
}
