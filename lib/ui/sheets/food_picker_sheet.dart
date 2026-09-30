import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/off.dart';
import '../../logic/calc.dart';
import '../../logic/food_search.dart';
import '../../logic/food_category.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
import '../food_form.dart';
import '../theme.dart';
import '../widgets/filter_pills.dart';
import '../widgets/food_category_filter.dart';
import '../widgets/food_list_item.dart';
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
  FoodCategory? _category;
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  bool _online = false;
  Future<List<OffFood>>? _onlineFuture;
  List<Food>? _recentFoods;
  bool _templateBusy = false;

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
      setState(() {
        _recentFoods = [
          for (final id in ids)
            if (byId[id] != null) byId[id]!,
        ];
        if (_recentFoods!.isNotEmpty &&
            _mode == _Mode.all &&
            _queryCtrl.text.trim().isEmpty) {
          _mode = _Mode.recent;
        }
      });
    }
  }

  void _onQuery(String v) {
    setState(() {
      if (v.trim().isNotEmpty && _mode == _Mode.recent) _mode = _Mode.all;
    });
    if (!_online) return;
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _onlineFuture = null);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 550),
      () => setState(() => _onlineFuture = searchOpenFoodFacts(v.trim())),
    );
  }

  void _setOnline(bool enabled) {
    _debounce?.cancel();
    final query = _queryCtrl.text.trim();
    setState(() {
      _online = enabled;
      // OFF 食物没有可靠的本地类型；进入在线模式时避免误导性分类。
      if (enabled) _category = null;
      // 最近列表独立渲染；在线区只在“全部”结果列表中展示。
      if (enabled && _mode == _Mode.recent) _mode = _Mode.all;
      _onlineFuture = enabled && query.length >= 2
          ? searchOpenFoodFacts(query)
          : null;
    });
  }

  Future<void> _addFromTemplate(MealTemplate t) async {
    if (_templateBusy) return;
    setState(() => _templateBusy = true);
    try {
      final db = ref.read(dbProvider);
      final items = await db.itemsOf(t.id);
      final foods = await db.foodsByIds(
        items.map((item) => item.foodId).toList(),
      );
      final byId = {for (final food in foods) food.id: food};
      if (!mounted) return;
      final useKj = ref.read(settingsProvider).useKj;
      if (items.isEmpty ||
          items.any(
            (item) =>
                byId[item.foodId] == null ||
                !item.grams.isFinite ||
                item.grams <= 0 ||
                item.grams > 100000,
          )) {
        throw StateError('Template unavailable');
      }
      final total = items.fold(
        0.0,
        (double sum, item) =>
            sum + byId[item.foodId]!.kcal100 * item.grams / 100,
      );
      if (!total.isFinite) throw StateError('Template unavailable');
      var decided = false;
      void decide(BuildContext dialogContext, bool value) {
        if (decided) return;
        decided = true;
        Navigator.pop(dialogContext, value);
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          scrollable: true,
          title: Text(tr(context, 'templateReview')),
          content: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('${widget.date} · ${mealLabel(context, widget.meal)}'),
                const SizedBox(height: 16),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${byId[item.foodId]!.name} · ${round1(item.grams)} g',
                    ),
                  ),
                const Divider(),
                Text(
                  '${fmtEnergy(total, useKj)} ${energyUnit(useKj)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => decide(context, false),
              child: Text(tr(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => decide(context, true),
              child: Text(tr(context, 'templateLog')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final n = await db.addEntriesFromTemplate(t.id, widget.date, widget.meal);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final receipt = tr(context, 'templateAdded', {
        't': t.name,
        'n': '$n',
        'meal': mealLabel(context, widget.meal),
      });
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(receipt)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(context, 'saveFail'))));
      }
    } finally {
      if (mounted) setState(() => _templateBusy = false);
    }
  }

  Future<void> _addOffFood(OffFood f) async {
    try {
      final food = await ref
          .read(dbProvider)
          .upsertFood(
            FoodsCompanion.insert(
              name: f.name,
              kcal100: f.kcal100,
              source: const Value('off'),
              brand: Value(f.brand),
              barcode: Value(f.barcode),
              protein100: Value(f.protein100),
              fat100: Value(f.fat100),
              carb100: Value(f.carb100),
            ),
          );
      if (!mounted) return;
      await showEntrySheet(
        context,
        date: widget.date,
        meal: widget.meal,
        food: food,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'saveFail')}: $e')),
        );
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
              suffixText: 'Open Food Facts',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: Text(tr(context, 'search')),
            ),
          ],
        );
      },
    );
    if (code == null || code.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'searching')),
        duration: const Duration(seconds: 1),
      ),
    );
    final off = await lookupByBarcode(code);
    if (!mounted) return;
    if (off == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context, 'notFound'))));
      return;
    }
    await _addOffFood(off);
  }

  Future<void> _createFood() async {
    final food = await showFoodForm(context, initialCategory: _category);
    if (food == null || !mounted) return;
    _debounce?.cancel();
    _queryCtrl.text = food.name;
    setState(() {
      _mode = _Mode.all;
      _category = FoodCategory.fromCode(food.category);
      _online = false;
      _onlineFuture = null;
    });
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
    await ref
        .read(dbProvider)
        .addEntry(
          EntriesCompanion.insert(
            date: widget.date,
            meal: widget.meal,
            name: tr(context, 'quickAddName'),
            kcal: kcal,
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'logged', {'n': '${round1(kcal)}'}))),
    );
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
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 4,
              children: [
                Text(
                  tr(context, 'addTo', {
                    'meal': mealLabel(context, widget.meal),
                  }),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(widget.date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
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
              suffixIcon: _queryCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: tr(context, 'clearSearch'),
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _queryCtrl.clear();
                        _onQuery('');
                      },
                    ),
            ),
            onChanged: _onQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              return Row(
                children: [
                  Expanded(
                    child: FilterPills(
                      items: [
                        for (final m in _Mode.values)
                          (
                            m,
                            switch (m) {
                              _Mode.all => tr(context, 'all'),
                              _Mode.recent => tr(context, 'recent'),
                              _Mode.fav => tr(context, 'fav'),
                            },
                          ),
                      ],
                      selected: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                  ),
                  if (!compact)
                    IconButton(
                      tooltip: tr(context, 'offOnline'),
                      onPressed: () => _setOnline(!_online),
                      icon: Icon(
                        Icons.public,
                        color: _online
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  PopupMenuButton<String>(
                    tooltip: tr(context, 'moreActions'),
                    icon: Icon(
                      compact && _online ? Icons.public : Icons.more_horiz,
                      color: compact && _online
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case 'online':
                          _setOnline(!_online);
                        case 'quick':
                          _quickAdd();
                        case 'barcode':
                          _barcodeFlow();
                        case 'custom':
                          _createFood();
                      }
                    },
                    itemBuilder: (context) => [
                      if (compact)
                        PopupMenuItem(
                          value: 'online',
                          child: Text(
                            '${tr(context, 'offOnline')}${_online ? ' ✓' : ''}',
                          ),
                        ),
                      PopupMenuItem(
                        value: 'quick',
                        child: Text(tr(context, 'quickAdd')),
                      ),
                      PopupMenuItem(
                        value: 'barcode',
                        child: Text(tr(context, 'barcode')),
                      ),
                      PopupMenuItem(
                        value: 'custom',
                        child: Text(tr(context, 'customFood')),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        if (!_online)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FoodCategoryFilter(
              selected: _category,
              onChanged: (value) => setState(() => _category = value),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, 'onlineUncategorized'),
                style: captionStyle(context),
              ),
            ),
          ),
        if (templates.isNotEmpty)
          SizedBox(
            height: 44 * MediaQuery.textScalerOf(context).scale(1) + 16,
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
                      onPressed: _templateBusy
                          ? null
                          : () => _addFromTemplate(t),
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
                    final list = (snap.data ?? const <Food>[])
                        .where(
                          (food) =>
                              _category == null ||
                              food.category == _category!.code,
                        )
                        .toList();
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
                            child: Column(
                              children: [
                                Text(
                                  _mode == _Mode.fav
                                      ? tr(context, 'noFavs')
                                      : tr(context, 'noMatchShort'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                if (_queryCtrl.text.trim().isNotEmpty ||
                                    _category != null ||
                                    _mode != _Mode.all) ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      _queryCtrl.clear();
                                      _onQuery('');
                                      setState(() {
                                        _category = null;
                                        _mode = _Mode.all;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.filter_alt_off,
                                      size: 18,
                                    ),
                                    label: Text(tr(context, 'clearFilters')),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                OutlinedButton.icon(
                                  onPressed: _createFood,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(tr(context, 'newCustomFood')),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                            child: Text(
                              tr(context, 'foodResults', {
                                'n': '${list.length}',
                              }),
                              style: captionStyle(context),
                            ),
                          ),
                        if (list.isNotEmpty)
                          for (final f in list)
                            _FoodTile(
                              food: f,
                              onTap: () => showEntrySheet(
                                context,
                                date: widget.date,
                                meal: widget.meal,
                                food: f,
                              ),
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
    final query = _queryCtrl.text;
    final visible = recent
        .where(
          (food) =>
              (_category == null || food.category == _category!.code) &&
              foodMatchRank(
                    name: food.name,
                    brand: food.brand,
                    barcode: food.barcode,
                    category: food.category,
                    query: query,
                  ) !=
                  null,
        )
        .toList();
    if (visible.isEmpty) {
      return Center(child: Text(tr(context, 'noMatchShort')));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
          child: Text(
            tr(context, 'foodResults', {'n': '${visible.length}'}),
            style: captionStyle(context),
          ),
        ),
        for (final f in visible)
          _FoodTile(
            food: f,
            onTap: () => showEntrySheet(
              context,
              date: widget.date,
              meal: widget.meal,
              food: f,
            ),
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
        if (_queryCtrl.text.trim().length < 2)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tr(context, 'onlineMinQuery'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
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
                  child: Text(
                    tr(context, 'onlineFail'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              final list = snap.data ?? const <OffFood>[];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr(context, 'noOnlineResults'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return Column(
                children: [
                  for (final f in list)
                    ListTile(
                      dense: true,
                      title: Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${f.brand == null ? '' : '${f.brand} · '}'
                        '${tr(context, 'per100g')} ${round1(f.kcal100)} kcal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
    return FoodListItem(
      food: food,
      onFavorite: () => ref.read(dbProvider).toggleFavorite(food),
      onTap: onTap,
    );
  }
}
