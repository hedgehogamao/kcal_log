import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/food_category.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
import '../food_form.dart';
import '../sheets/entry_sheet.dart';
import '../theme.dart';
import '../widgets/food_list_item.dart';
import '../widgets/filter_pills.dart';
import '../widgets/food_category_filter.dart';
import '../widgets/top_tabs.dart';
import 'food_packs_page.dart';

class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tabFoods')),
        actions: [
          IconButton(
            key: const ValueKey('food-pack-open'),
            tooltip: tr(context, 'foodPacks'),
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FoodPacksPage()),
            ),
          ),
        ],
      ),
      body: TopTabs(
        tabs: [tr(context, 'foods'), tr(context, 'templates')],
        pageBuilder: (_, i) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: i == 0
                ? _FoodsTab(
                    onQuery: (v) => setState(() => _query = v),
                    query: _query,
                  )
                : const _TemplatesTab(),
          ),
        ),
      ),
    );
  }
}

/// 食物来源筛选
enum FoodSourceFilter { all, fav, builtin, custom, pack, off }

class _FoodsTab extends ConsumerStatefulWidget {
  const _FoodsTab({required this.onQuery, required this.query});

  final ValueChanged<String> onQuery;
  final String query;

  @override
  ConsumerState<_FoodsTab> createState() => _FoodsTabState();
}

class _FoodsTabState extends ConsumerState<_FoodsTab> {
  FoodSourceFilter _source = FoodSourceFilter.all;
  FoodCategory? _category;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _createFood() async {
    final food = await showFoodForm(context, initialCategory: _category);
    if (food == null || !mounted) return;
    _searchCtrl.text = food.name;
    widget.onQuery(food.name);
    setState(() {
      _source = FoodSourceFilter.custom;
      _category = FoodCategory.fromCode(food.category);
    });
  }

  bool _match(Food f) =>
      (_category == null || f.category == _category!.code) &&
      switch (_source) {
        FoodSourceFilter.all => true,
        FoodSourceFilter.fav => f.favorite,
        FoodSourceFilter.builtin => f.source == 'builtin',
        FoodSourceFilter.custom =>
          f.source != 'builtin' && f.source != 'off' && f.source != 'pack',
        FoodSourceFilter.pack => f.source == 'pack',
        FoodSourceFilter.off => f.source == 'off',
      };

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) {
                    widget.onQuery(value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr(context, 'searchName'),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: tr(context, 'clearSearch'),
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              widget.onQuery('');
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: tr(context, 'newCustomFood'),
                onPressed: _createFood,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: FoodCategoryFilter(
            selected: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
        ),
        // 来源筛选胶囊：选中实底，超出横向滚动
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: FilterPills<FoodSourceFilter>(
            items: [
              (FoodSourceFilter.all, tr(context, 'all')),
              (FoodSourceFilter.fav, tr(context, 'fav')),
              (FoodSourceFilter.builtin, tr(context, 'sourceBuiltin')),
              (FoodSourceFilter.custom, tr(context, 'sourceCustom')),
              (FoodSourceFilter.pack, tr(context, 'sourceFoodPack')),
              (FoodSourceFilter.off, 'OFF'),
            ],
            selected: _source,
            onChanged: (v) => setState(() => _source = v),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Food>>(
            stream: db.watchFoods(widget.query),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!.where(_match).toList();
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr(
                          context,
                          widget.query.trim().isEmpty &&
                                  _source == FoodSourceFilter.all &&
                                  _category == null
                              ? 'noFoods'
                              : 'noMatchShort',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.query.trim().isNotEmpty ||
                          _source != FoodSourceFilter.all ||
                          _category != null) ...[
                        TextButton.icon(
                          onPressed: () {
                            _searchCtrl.clear();
                            widget.onQuery('');
                            setState(() {
                              _source = FoodSourceFilter.all;
                              _category = null;
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off, size: 18),
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
                );
              }
              final rows = <Object>[];
              if (widget.query.trim().isEmpty &&
                  _source == FoodSourceFilter.all &&
                  _category == null) {
                void group(String label, bool Function(Food) include) {
                  final foods = list.where(include).toList();
                  if (foods.isEmpty) return;
                  rows.add('$label · ${foods.length}');
                  rows.addAll(foods);
                }

                group(tr(context, 'fav'), (food) => food.favorite);
                group(
                  tr(context, 'myFoods'),
                  (food) => !food.favorite && food.source == 'custom',
                );
                group(
                  tr(context, 'sourceBuiltin'),
                  (food) => !food.favorite && food.source == 'builtin',
                );
                group('OFF', (food) => !food.favorite && food.source == 'off');
                group(
                  tr(context, 'sourceFoodPack'),
                  (food) => !food.favorite && food.source == 'pack',
                );
              } else {
                rows.addAll(list);
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr(context, 'foodResults', {'n': '${list.length}'}),
                        style: captionStyle(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        if (row is String) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                            child: Text(row, style: captionStyle(context)),
                          );
                        }
                        return _FoodRow(food: row as Food);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodRow extends ConsumerWidget {
  const _FoodRow({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return FoodListItem(
      food: food,
      onTap: () => showEntrySheet(
        context,
        date: dateKey(DateTime.now()),
        meal: currentMealType(),
        food: food,
      ),
      onFavorite: () => db.toggleFavorite(food),
      menu: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            await showFoodForm(context, existing: food);
          } else if (v == 'delete') {
            await showConfirmDialog(
              context,
              title: tr(context, 'delFoodTitle', {'name': food.name}),
              content: tr(context, 'delFoodBody'),
              onConfirm: () => db.deleteFood(food.id),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: Text(tr(context, 'edit'))),
          PopupMenuItem(value: 'delete', child: Text(tr(context, 'delete'))),
        ],
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hint = Text(
                tr(context, 'templateHint'),
                style: Theme.of(context).textTheme.bodySmall,
              );
              final action = FilledButton.tonalIcon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _TemplateEditor(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  tr(context, 'newTemplate'),
                  textAlign: TextAlign.center,
                ),
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [hint, const SizedBox(height: 8), action],
                );
              }
              return Row(
                children: [
                  Expanded(child: hint),
                  const SizedBox(width: 16),
                  action,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MealTemplate>>(
            stream: db.watchTemplates(),
            builder: (context, snap) {
              final list = snap.data ?? const <MealTemplate>[];
              if (list.isEmpty) {
                return Center(child: Text(tr(context, 'noTemplates')));
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [for (final t in list) _TemplateRow(template: t)],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateRow extends ConsumerWidget {
  const _TemplateRow({required this.template});

  final MealTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return ListTile(
      leading: const Icon(Icons.layers_outlined),
      title: Text(template.name),
      subtitle: Text(
        tr(context, 'tapToEdit'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'delete') {
            await showConfirmDialog(
              context,
              title: tr(context, 'delTplTitle', {'name': template.name}),
              content: tr(context, 'delTplBody'),
              onConfirm: () => db.deleteTemplate(template.id),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'delete', child: Text(tr(context, 'delete'))),
        ],
      ),
      onTap: () => showDialog(
        context: context,
        builder: (_) => _TemplateEditor(existing: template),
      ),
    );
  }
}

class _TemplateEditor extends ConsumerStatefulWidget {
  const _TemplateEditor({this.existing});

  final MealTemplate? existing;

  @override
  ConsumerState<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateItemRow {
  _TemplateItemRow(this.food, double grams)
    : ctrl = TextEditingController(text: grams.toString());
  final Food food;
  final TextEditingController ctrl;
  double? get grams => double.tryParse(ctrl.text.trim());
  bool get valid =>
      grams != null && grams!.isFinite && grams! > 0 && grams! <= 100000;
  void dispose() => ctrl.dispose();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  late final TextEditingController _nameCtrl;
  final List<_TemplateItemRow> _items = [];
  bool _loading = false,
      _saving = false,
      _selecting = false,
      _submitted = false;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name);
    _load();
  }

  Future<void> _load() async {
    final existing = widget.existing;
    if (existing == null) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final db = ref.read(dbProvider);
      final items = await db.itemsOf(existing.id);
      final foods = await db.foodsByIds(items.map((i) => i.foodId).toList());
      final byId = {for (final f in foods) f.id: f};
      if (!mounted) return;
      setState(() {
        for (final it in items) {
          final f = byId[it.foodId];
          if (f != null) _items.add(_TemplateItemRow(f, it.grams));
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _error = tr(context, 'templateLoadFail');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _addFood() async {
    if (_selecting || _saving || _loading || _loadFailed) return;
    setState(() => _selecting = true);
    final food = await showFoodSearchDialog(context);
    if (!mounted) return;
    setState(() {
      _selecting = false;
      if (food != null) {
        final portion = food.servingGrams;
        _items.add(
          _TemplateItemRow(
            food,
            portion != null &&
                    portion.isFinite &&
                    portion > 0 &&
                    portion <= 100000
                ? portion
                : 100,
          ),
        );
        _error = null;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _loading || _loadFailed) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _items.isEmpty) {
      setState(() => _error = tr(context, 'needNameItems'));
      return;
    }
    if (_items.any((item) => !item.valid)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      final parsed = [for (final item in _items) (item.food.id, item.grams!)];
      if (widget.existing == null) {
        await db.saveTemplate(name, parsed);
      } else {
        await db.updateTemplate(widget.existing!.id, name, parsed);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'saveFail'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _step(_TemplateItemRow item, double delta) {
    final current = item.valid ? item.grams! : 100.0;
    // Keep decimal quantities; a decrement never leaves an unsavable zero.
    final next = (current + delta).clamp(1.0, 100000.0);
    setState(() {
      item.ctrl.text = next.toString();
      _error = null;
    });
  }

  Widget _item(_TemplateItemRow item) {
    return Card(
      key: ValueKey(item),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.food.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: tr(context, 'templateRemove', {
                    'name': item.food.name,
                  }),
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() => _items.remove(item));
                          // Dispose after the removed TextField has left the tree.
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => item.dispose(),
                          );
                        },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            Text(
              tr(context, 'templateGrams'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  tooltip: tr(context, 'templateLess'),
                  onTap: _saving ? null : () => _step(item, -50),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: ValueKey(
                      'template_grams_${item.food.id}_${_items.indexOf(item)}',
                    ),
                    controller: item.ctrl,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(width: 8),
                _StepButton(
                  icon: Icons.add,
                  tooltip: tr(context, 'templateMore'),
                  onTap: _saving ? null : () => _step(item, 50),
                ),
              ],
            ),
            if (_submitted && !item.valid) ...[
              const SizedBox(height: 6),
              Text(
                tr(context, 'templateGramsRange'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useKj = ref.watch(settingsProvider).useKj;
    final totalKcal = _items
        .where((item) => item.valid)
        .fold(
          0.0,
          (double sum, item) => sum + item.food.kcal100 * item.grams! / 100,
        );
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.all(16),
        scrollable: true,
        title: Text(
          widget.existing == null
              ? tr(context, 'newTemplate')
              : tr(context, 'editTplTitle'),
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'templateSaveNote'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'nameField')),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('template_name'),
                controller: _nameCtrl,
                enabled: !_loading && !_saving && !_loadFailed,
                decoration: InputDecoration(
                  hintText: tr(context, 'nameHint'),
                  isDense: true,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              Text(
                tr(context, 'templateSummaryUnit', {
                  'n': '${_items.length}',
                  'energy':
                      '${fmtEnergy(totalKcal, useKj)} ${energyUnit(useKj)}',
                }),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(tr(context, 'tplEmpty')),
                )
              else
                ..._items.map(_item),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (_error == tr(context, 'templateLoadFail'))
                  TextButton(
                    onPressed: _load,
                    child: Text(tr(context, 'retry')),
                  ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _loading || _saving || _selecting || _loadFailed
                    ? null
                    : _addFood,
                icon: const Icon(Icons.add),
                label: Text(tr(context, 'addFood')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: _loading || _saving || _selecting || _loadFailed
                ? null
                : _save,
            child: Text(tr(context, _saving ? 'saving' : 'save')),
          ),
        ],
      ),
    );
  }
}

/// Native focusable controls with a minimum 44-pixel hit target.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon, size: 20),
  );
}
