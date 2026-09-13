import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/off.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
import '../food_form.dart';
import '../theme.dart';
import '../widgets/filter_pills.dart';
import 'entry_sheet.dart';

/// 添加记录入口：食物库搜索 / 最近 / 收藏 / 组合餐 / OFF 在线 / 条码 / 快速添加
Future<void> openAddEntryFlow(
  BuildContext context, {
  String? date,
  MealType? meal,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FoodPickerSheet(
      date: date ?? dateKey(DateTime.now()),
      meal: meal ?? currentMealType(),
    ),
  );
}

enum _Mode { all, recent, fav }

class FoodPickerSheet extends ConsumerStatefulWidget {
  const FoodPickerSheet({super.key, required this.date, required this.meal});

  final String date;
  final MealType meal;

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  _Mode _mode = _Mode.all;
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  bool _online = false;
  Future<List<OffFood>>? _onlineFuture;
  List<Food>? _recentFoods;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final db = ref.read(dbProvider);
    final rows = await db.recentEntries();
    final ids = <int>[];
    for (final r in rows) {
      final id = r.foodId;
      if (id != null && !ids.contains(id)) ids.add(id);
      if (ids.length >= 20) break;
    }
    final foods = await db.foodsByIds(ids);
    final byId = {for (final f in foods) f.id: f};
    if (mounted) {
      setState(() => _recentFoods = [
            for (final id in ids)
              if (byId[id] != null) byId[id]!,
          ]);
    }
  }

  void _onQuery(String v) {
    setState(() {});
    if (!_online) return;
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _onlineFuture = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 550),
        () => setState(() => _onlineFuture = searchOpenFoodFacts(v.trim())));
  }

  Future<void> _addFromTemplate(MealTemplate t) async {
    final n = await ref
        .read(dbProvider)
        .addEntriesFromTemplate(t.id, widget.date, widget.meal);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr(context, 'templateAdded', {
      't': t.name,
      'n': '$n',
      'meal': mealLabel(context, widget.meal),
    }))));
  }

  Future<void> _addOffFood(OffFood f) async {
    try {
      final food = await ref.read(dbProvider).upsertFood(FoodsCompanion.insert(
            name: f.name,
            kcal100: f.kcal100,
            source: const Value('off'),
            brand: Value(f.brand),
            barcode: Value(f.barcode),
            protein100: Value(f.protein100),
            fat100: Value(f.fat100),
            carb100: Value(f.carb100),
          ));
      if (!mounted) return;
      await showEntrySheet(context,
          date: widget.date, meal: widget.meal, food: food);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${tr(context, 'saveFail')}: $e')));
      }
    }
  }

  Future<void> _barcodeFlow() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text(tr(context, 'barcodeTitle')),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                hintText: tr(context, 'barcodeHint'),
                suffixText: 'Open Food Facts'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr(context, 'cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                child: Text(tr(context, 'search'))),
          ],
        );
      },
    );
    if (code == null || code.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr(context, 'searching')),
        duration: const Duration(seconds: 1)));
    final off = await lookupByBarcode(code);
    if (!mounted) return;
    if (off == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context, 'notFound'))));
      return;
    }
    await _addOffFood(off);
  }

  Future<void> _quickAdd() async {
    final settings = ref.read(settingsProvider);
    final v = await showNumberDialog(
      context,
      title: tr(context, 'quickAddTitle'),
      suffix: energyUnit(settings.useKj),
      hint: tr(context, 'quickAddHint'),
    );
    if (v == null || v <= 0 || !mounted) return;
    final kcal = settings.useKj ? kjToKcal(v) : v;
    await ref.read(dbProvider).addEntry(EntriesCompanion.insert(
          date: widget.date,
          meal: widget.meal,
          name: tr(context, 'quickAddName'),
          kcal: kcal,
        ));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            tr(context, 'logged', {'n': '${round1(kcal)}'}))));
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final templates = ref.watch(templatesProvider).valueOrNull ?? const [];
    final localStream = _mode == _Mode.all
        ? db.watchFoods(_queryCtrl.text)
        : db.watchFoods(_queryCtrl.text, favoritesOnly: true);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Text(
                  tr(context, 'addTo',
                      {'meal': mealLabel(context, widget.meal)}),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(widget.date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText:
                  '${tr(context, 'searchFoods')}${_online ? tr(context, 'searchOnlineSuffix') : ''}',
            ),
            onChanged: _onQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterPills(
                items: [
                  for (final m in _Mode.values)
                    (
                      m,
                      switch (m) {
                        _Mode.all => tr(context, 'all'),
                        _Mode.recent => tr(context, 'recent'),
                        _Mode.fav => tr(context, 'fav'),
                      }
                    ),
                ],
                selected: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(tr(context, 'offOnline')),
                    selected: _online,
                    showCheckmark: false,
                    onSelected: (v) => setState(() {
                      _online = v;
                      _onlineFuture = null;
                    }),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.flash_on, size: 16),
                    label: Text(tr(context, 'quickAdd')),
                    onPressed: _quickAdd,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.qr_code, size: 16),
                    label: Text(tr(context, 'barcode')),
                    onPressed: _barcodeFlow,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(tr(context, 'customFood')),
                    onPressed: () => showFoodForm(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (templates.isNotEmpty)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final t in templates)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.layers, size: 16),
                      label: Text(t.name),
                      onPressed: () => _addFromTemplate(t),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _mode == _Mode.recent
              ? _recentList()
              : StreamBuilder<List<Food>>(
                  stream: localStream,
                  builder: (context, snap) {
                    final list = snap.data ?? const <Food>[];
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (snap.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                _mode == _Mode.fav
                                    ? tr(context, 'noFavs')
                                    : tr(context, 'noMatch'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          )
                        else
                          for (final f in list)
                            _FoodTile(
                              food: f,
                              onTap: () => showEntrySheet(context,
                                  date: widget.date, meal: widget.meal, food: f),
                            ),
                        if (_online) _onlineSection(),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _recentList() {
    final recent = _recentFoods;
    if (recent == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recent.isEmpty) {
      return Center(child: Text(tr(context, 'noRecent')));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final f in recent)
          _FoodTile(
            food: f,
            onTap: () => showEntrySheet(context,
                date: widget.date, meal: widget.meal, food: f),
          ),
      ],
    );
  }

  Widget _onlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(tr(context, 'offSection'), style: captionStyle(context)),
        ),
        FutureBuilder<List<OffFood>>(
          future: _onlineFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr(context, 'onlineFail'),
                    style: Theme.of(context).textTheme.bodySmall),
              );
            }
            final list = snap.data ?? const <OffFood>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr(context, 'noOnlineResults'),
                    style: Theme.of(context).textTheme.bodySmall),
              );
            }
            return Column(
              children: [
                for (final f in list)
                  ListTile(
                    dense: true,
                    title: Text(f.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${f.brand == null ? '' : '${f.brand} · '}'
                        '${tr(context, 'per100g')} ${round1(f.kcal100)} kcal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: Icon(Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary),
                    onTap: () => _addOffFood(f),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FoodTile extends ConsumerWidget {
  const _FoodTile({required this.food, this.onTap});

  final Food food;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = switch (food.source) {
      'off' => 'OFF',
      'builtin' => tr(context, 'sourceBuiltin'),
      _ => tr(context, 'sourceCustom'),
    };
    return ListTile(
      title: Text(food.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${food.brand == null ? '' : '${food.brand} · '}'
        '${tr(context, 'per100g')} ${round1(food.kcal100)} kcal · '
        '${tr(context, 'proteinShort')} ${round1(food.protein100)} '
        '${tr(context, 'fatShort')} ${round1(food.fat100)} '
        '${tr(context, 'carbShort')} ${round1(food.carb100)} · $source',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          food.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: food.favorite ? Colors.amber : null,
        ),
        onPressed: () => ref.read(dbProvider).toggleFavorite(food),
      ),
      onTap: onTap,
    );
  }
}
