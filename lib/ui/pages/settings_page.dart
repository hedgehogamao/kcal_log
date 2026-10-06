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
import '../../data/seed_data.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
import '../theme.dart';
import '../widgets/app_segmented.dart';
import '../widgets/lang_button.dart';
import 'food_packs_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // drift_flutter's default native database location is the documents directory.
  late final Future<Directory> _dataDirectory =
      getApplicationDocumentsDirectory();
  bool _busyBackup = false;
  bool _confirmingImport = false;
  bool _savingGoal = false;
  String? _backupResult;
  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _saveGoal(String column, double? value) =>
      ref.read(dbProvider).saveProfile(switch (column) {
        'kcal' => ProfilesCompanion(id: const Value(1), kcalGoal: Value(value)),
        'protein' => ProfilesCompanion(
          id: const Value(1),
          proteinGoal: Value(value),
        ),
        'fat' => ProfilesCompanion(id: const Value(1), fatGoal: Value(value)),
        _ => ProfilesCompanion(id: const Value(1), carbGoal: Value(value)),
      });
  Future<void> _editGoal(String title, String column, double? current) async {
    if (_savingGoal) return;
    setState(() => _savingGoal = true);
    final kj = column == 'kcal' && ref.read(settingsProvider).useKj;
    final displayed = current == null
        ? null
        : kj
        ? kcalToKj(current)
        : current;
    final initial = displayed == null ? null : round1(displayed).toString();
    try {
      final value = await showNumberDialog(
        context,
        title: title,
        initial: initial,
        suffix: column == 'kcal' ? energyUnit(kj) : 'g',
        hint: tr(context, 'clearHint'),
        allowClear: true,
      );
      if (value == null || !mounted) return;
      // Preserve a stored value when its rounded display was left unchanged.
      final stored = value == 0
          ? null
          : current != null && value == double.tryParse(initial!)
          ? current
          : kj
          ? kjToKcal(value)
          : value;
      await _saveGoal(column, stored);
      if (mounted) _toast(tr(context, 'goalSaved'));
    } catch (_) {
      if (mounted) _toast(tr(context, 'saveFail'));
    } finally {
      if (mounted) setState(() => _savingGoal = false);
    }
  }

  Future<void> _export() async {
    if (_busyBackup) return;
    setState(() => _busyBackup = true);
    final lang = LangScope.of(context);
    try {
      final data = const JsonEncoder.withIndent('  ')
          .convert(await ref.read(dbProvider).exportJson());
      final name = 'kcallog-backup-${dateKey(DateTime.now())}.json';
      final mobile = Platform.isAndroid || Platform.isIOS;
      String? path;
      try {
        path = await FilePicker.platform.saveFile(
          fileName: name,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: mobile ? Uint8List.fromList(utf8.encode(data)) : null,
        );
        // A cancelled picker never creates an unexpected fallback backup.
        if (path == null) return;
        if (!mobile) await File(path).writeAsString(data, flush: true);
      } on UnsupportedError {
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/$name';
        await File(path).writeAsString(data, flush: true);
      }
      if (mounted) {
        setState(() => _backupResult = t(lang, 'exportedTo', {'p': path!}));
      }
    } catch (_) {
      _toast(t(lang, 'exportFail'));
    } finally {
      if (mounted) setState(() => _busyBackup = false);
    }
  }

  Future<void> _import() async {
    if (_busyBackup) return;
    setState(() => _busyBackup = true);
    final lang = LangScope.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        _toast(t(lang, 'readFail'));
        return;
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic> ||
          json['app'] != 'kcal_log' ||
          json['schema'] != 1 ||
          ![
            'foods',
            'entries',
            'weights',
            'waters',
            'templates',
            'templateItems',
          ].every((key) => json[key] is List) ||
          (json['profile'] != null &&
              json['profile'] is! Map<String, dynamic>)) {
        _toast(t(lang, 'notBackup'));
        return;
      }
      if (!mounted) return;
      setState(() => _confirmingImport = true);
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => _BackupConfirmDialog(
          name: file.name,
          foods: (json['foods'] as List).length,
          entries: (json['entries'] as List).length,
        ),
      );
      if (mounted) setState(() => _confirmingImport = false);
      if (ok != true || !mounted) return;
      final db = ref.read(dbProvider);
      await db.transaction(() async {
        await db.importJson(json);
        await backfillBuiltInFoodCategories(db);
      });
      ref.invalidate(entriesProvider);
      ref.invalidate(entriesRangeProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(weightsProvider);
      ref.invalidate(waterProvider);
      ref.invalidate(templatesProvider);
      if (mounted) setState(() => _backupResult = t(lang, 'importDone'));
    } catch (_) {
      _toast(t(lang, 'importFail'));
    } finally {
      if (mounted) {
        setState(() {
          _busyBackup = false;
          _confirmingImport = false;
        });
      }
    }
  }

  Future<void> _editWater(int current) async {
    final value = await showNumberDialog(
      context,
      title: tr(context, 'waterGoal'),
      initial: '$current',
      suffix: 'ml',
      minimum: 1,
      maximum: 20000,
    );
    if (value == null || !mounted) return;
    if (value.round() <= 0) {
      _toast(tr(context, 'invalidWater'));
      return;
    }
    ref.read(settingsProvider.notifier).setWaterGoal(value.round());
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget goal(
      String column,
      String label,
      double? value,
      IconData icon,
      Color color, {
      String? fallback,
    }) => _SettingsRow(
      key: ValueKey('goal-$column'),
      icon: icon,
      color: color,
      title: label,
      detail: value == null
          ? fallback ?? tr(context, 'goalUnset')
          : column == 'kcal'
          ? '${fmtEnergy(value, settings.useKj)} ${energyUnit(settings.useKj)}'
          : '${round1(value)} g',
      onTap: _savingGoal ? null : () => _editGoal(label, column, value),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabSettings')),
        actions: const [LangButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Section(
                title: tr(context, 'secGoals'),
                subtitle: tr(context, 'goalsHelp'),
                children: [
                  goal(
                    'kcal',
                    tr(context, 'kcalGoalRow'),
                    profile?.kcalGoal,
                    CupertinoIcons.flame,
                    LabelColors.energyOf(dark),
                  ),
                  goal(
                    'protein',
                    tr(context, 'proteinGoal'),
                    profile?.proteinGoal,
                    CupertinoIcons.leaf_arrow_circlepath,
                    LabelColors.proteinOf(dark),
                    fallback: tr(context, 'unsetDefault', {'p': '20'}),
                  ),
                  goal(
                    'fat',
                    tr(context, 'fatGoal'),
                    profile?.fatGoal,
                    CupertinoIcons.drop,
                    LabelColors.fatOf(dark),
                    fallback: tr(context, 'unsetDefault', {'p': '25'}),
                  ),
                  goal(
                    'carb',
                    tr(context, 'carbGoal'),
                    profile?.carbGoal,
                    CupertinoIcons.circle_grid_3x3,
                    LabelColors.carbOf(dark),
                    fallback: tr(context, 'unsetDefault', {'p': '55'}),
                  ),
                  _SettingsRow(
                    key: const ValueKey('profile-row'),
                    icon: CupertinoIcons.person,
                    title: tr(context, 'estimateByProfile'),
                    detail: tr(context, 'profileSub'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _ProfileDialog(profile: profile),
                    ),
                  ),
                ],
              ),
              _Section(
                title: tr(context, 'secAppearance'),
                children: [
                  _SettingsRow(
                    icon: CupertinoIcons.bolt,
                    title: tr(context, 'useKj'),
                    detail: tr(context, 'useKjSub'),
                    trailing: CupertinoSwitch(
                      value: settings.useKj,
                      onChanged: ref.read(settingsProvider.notifier).setUseKj,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr(context, 'appearance'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        AppSegmented<ThemeMode>(
                          segments: [
                            (ThemeMode.system, tr(context, 'system')),
                            (ThemeMode.light, tr(context, 'light')),
                            (ThemeMode.dark, tr(context, 'dark')),
                          ],
                          selected: settings.themeMode,
                          onChanged: ref
                              .read(settingsProvider.notifier)
                              .setThemeMode,
                        ),
                      ],
                    ),
                  ),
                  _SettingsRow(
                    key: const ValueKey('water-goal-row'),
                    icon: CupertinoIcons.drop,
                    title: tr(context, 'waterGoal'),
                    detail: tr(context, 'perDay', {
                      'n': '${settings.waterGoalMl}',
                    }),
                    onTap: () => _editWater(settings.waterGoalMl),
                  ),
                ],
              ),
              _Section(
                title: tr(context, 'secData'),
                subtitle: tr(context, 'backupHelp'),
                children: [
                  _SettingsRow(
                    key: const ValueKey('food-pack-settings'),
                    icon: Icons.inventory_2_outlined,
                    title: tr(context, 'foodPacks'),
                    detail: tr(context, 'packHeadline'),
                    onTap: _busyBackup
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FoodPacksPage(),
                            ),
                          ),
                  ),
                  _SettingsRow(
                    key: const ValueKey('export-row'),
                    icon: CupertinoIcons.square_arrow_up,
                    title: tr(context, 'exportTitle'),
                    detail: tr(context, 'exportSub'),
                    onTap: _busyBackup ? null : _export,
                  ),
                  _SettingsRow(
                    key: const ValueKey('import-row'),
                    icon: CupertinoIcons.square_arrow_down,
                    title: tr(context, 'importTitle'),
                    detail: tr(context, 'importSub'),
                    onTap: _busyBackup ? null : _import,
                  ),
                  if (_busyBackup && !_confirmingImport)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(tr(context, 'working'))),
                        ],
                      ),
                    ),
                  if (_backupResult != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _backupResult!,
                        key: const ValueKey('backup-result'),
                      ),
                    ),
                  FutureBuilder<Directory>(
                    future: _dataDirectory,
                    builder: (context, snap) {
                      final path = snap.data == null
                          ? null
                          : '${snap.data!.path}/kcallog.sqlite';
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              tr(context, 'storageLoc'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(path ?? tr(context, 'appDataDir')),
                            if (path != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: path),
                                    );
                                    if (mounted) {
                                      _toast(tr(this.context, 'pathCopied'));
                                    }
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.doc_on_doc,
                                    size: 18,
                                  ),
                                  label: Text(tr(context, 'copyPath')),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              _Section(
                title: tr(context, 'secAbout'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${tr(context, 'appName')} v0.1.0',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context, 'aboutBody'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.color,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title, detail;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right, size: 16),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BackupConfirmDialog extends StatefulWidget {
  const _BackupConfirmDialog({
    required this.name,
    required this.foods,
    required this.entries,
  });
  final String name;
  final int foods, entries;
  @override
  State<_BackupConfirmDialog> createState() => _BackupConfirmDialogState();
}

class _BackupConfirmDialogState extends State<_BackupConfirmDialog> {
  bool _ack = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr(context, 'importConfirmTitle')),
    scrollable: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.name),
        const SizedBox(height: 8),
        Text(
          tr(context, 'backupCounts', {
            'foods': '${widget.foods}',
            'entries': '${widget.entries}',
          }),
        ),
        const SizedBox(height: 12),
        Text(tr(context, 'importConfirmBody')),
        const SizedBox(height: 8),
        CheckboxListTile(
          key: const ValueKey('import-ack'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            tr(context, 'acknowledgeImport'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          value: _ack,
          onChanged: (v) => setState(() => _ack = v ?? false),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(tr(context, 'cancel')),
      ),
      FilledButton(
        key: const ValueKey('confirm-import'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: _ack ? () => Navigator.pop(context, true) : null,
        child: Text(tr(context, 'overwriteImport')),
      ),
    ],
  );
}

class _ProfileDialog extends ConsumerStatefulWidget {
  const _ProfileDialog({this.profile});
  final Profile? profile;
  @override
  ConsumerState<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<_ProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _birthYear = TextEditingController(
    text: widget.profile?.birthYear?.toString() ?? '',
  );
  late final _height = TextEditingController(
    text: widget.profile?.heightCm == null
        ? ''
        : '${round1(widget.profile!.heightCm!)}',
  );
  late final _weight = TextEditingController(
    text: widget.profile?.weightKg == null
        ? ''
        : '${round1(widget.profile!.weightKg!)}',
  );
  late Sex? _sex = widget.profile?.sex;
  late ActivityLevel _activity =
      widget.profile?.activity ?? ActivityLevel.moderate;
  bool _applyEstimate = false, _saving = false, _attempted = false;
  String? _error;
  @override
  void dispose() {
    _birthYear.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  int? get _year => int.tryParse(_birthYear.text.trim());
  double? get _h => double.tryParse(_height.text.trim());
  double? get _w => double.tryParse(_weight.text.trim());
  double? get _tdee => estimateTdee(
    sex: _sex,
    birthYear: _year,
    heightCm: _h,
    weightKg: _w,
    activity: _activity,
  );
  String? _validYear(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final v = int.tryParse(text.trim());
    final age = v == null ? null : DateTime.now().year - v;
    return age == null || age < 10 || age > 100
        ? tr(context, 'invalidYear')
        : null;
  }

  String? _validMeasure(String? text, double max) {
    if (text == null || text.trim().isEmpty) return null;
    final v = double.tryParse(text.trim());
    return v == null || !v.isFinite || v <= 0 || v > max
        ? tr(context, 'validNumberRange', {
            'max': '$max',
            'unit': max == 300 ? 'cm' : 'kg',
          })
        : null;
  }

  void _changed() {
    setState(() {
      _error = null;
      if (_tdee == null) _applyEstimate = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _attempted = true);
    if (!_form.currentState!.validate()) return;
    final estimate = _tdee;
    if (_applyEstimate && estimate == null) {
      setState(() => _error = tr(context, 'tdeeHint'));
      return;
    }
    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      final macros = estimate == null ? null : defaultMacroGoals(estimate);
      await db.transaction(() async {
        await db.saveProfile(
          ProfilesCompanion(
            id: const Value(1),
            sex: Value(_sex),
            birthYear: Value(_year),
            heightCm: Value(_h),
            weightKg: Value(_w),
            activity: Value(_activity),
            kcalGoal: _applyEstimate ? Value(estimate) : const Value.absent(),
            proteinGoal: _applyEstimate
                ? Value(macros!.$1)
                : const Value.absent(),
            fatGoal: _applyEstimate ? Value(macros!.$2) : const Value.absent(),
            carbGoal: _applyEstimate ? Value(macros!.$3) : const Value.absent(),
          ),
        );
        if (_w != null) await db.addWeight(dateKey(DateTime.now()), _w!);
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'saveFail'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _tdee;
    final settings = ref.watch(settingsProvider);
    final labels = ['actSedentary', 'actLight', 'actModerate', 'actHigh'];
    return AlertDialog(
      title: Text(tr(context, 'profileTitle')),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          autovalidateMode: _attempted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'profileEditHelp'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'sexLabel')),
              const SizedBox(height: 8),
              Semantics(
                label: tr(context, 'sexLabel'),
                child: DropdownButtonFormField<Sex>(
                  key: const ValueKey('profile-sex'),
                  initialValue: _sex,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  hint: Text(tr(context, 'chooseSex')),
                  items: [
                    for (final s in Sex.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(
                          tr(context, s == Sex.male ? 'male' : 'female'),
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (s) {
                          _sex = s;
                          _changed();
                        },
                ),
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'birthYear')),
              const SizedBox(height: 8),
              Semantics(
                label: tr(context, 'birthYear'),
                child: TextFormField(
                  key: const ValueKey('profile-year'),
                  controller: _birthYear,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: tr(context, 'eg1990'),
                    errorMaxLines: 12,
                  ),
                  validator: _validYear,
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'heightCm')),
              const SizedBox(height: 8),
              Semantics(
                label: tr(context, 'heightCm'),
                child: TextFormField(
                  key: const ValueKey('profile-height'),
                  controller: _height,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(errorMaxLines: 12),
                  validator: (v) => _validMeasure(v, 300),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'weightKg')),
              const SizedBox(height: 8),
              Semantics(
                label: tr(context, 'weightKg'),
                child: TextFormField(
                  key: const ValueKey('profile-weight'),
                  controller: _weight,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(errorMaxLines: 12),
                  validator: (v) => _validMeasure(v, 500),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'activityLevel')),
              const SizedBox(height: 8),
              Semantics(
                label: tr(context, 'activityLevel'),
                child: DropdownButtonFormField<ActivityLevel>(
                  key: const ValueKey('profile-activity'),
                  initialValue: _activity,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(),
                  selectedItemBuilder: (context) => [
                    for (final a in ActivityLevel.values)
                      Text(tr(context, '${labels[a.index]}Short')),
                  ],
                  items: [
                    for (final a in ActivityLevel.values)
                      DropdownMenuItem(
                        value: a,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(tr(context, labels[a.index])),
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (a) {
                          if (a != null) {
                            _activity = a;
                            _changed();
                          }
                        },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      estimate == null
                          ? tr(context, 'tdeeHint')
                          : tr(context, 'estimateValue', {
                              'value':
                                  '${fmtEnergy(estimate, settings.useKj)} ${energyUnit(settings.useKj)}',
                            }),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'estimateHint'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (estimate != null) ...[
                const SizedBox(height: 12),
                Text(tr(context, 'applyEstimateGoals')),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  key: const ValueKey('apply-estimate'),
                  title: Text(
                    tr(context, 'applyEstimateShort'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: _applyEstimate,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _applyEstimate = v ?? false),
                ),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(tr(context, 'cancel')),
        ),
        FilledButton(
          key: const ValueKey('save-profile'),
          onPressed: _saving ? null : _save,
          child: Text(tr(context, 'save')),
        ),
      ],
    );
  }
}
