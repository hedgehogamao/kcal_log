import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';
import '../dialogs.dart';
import '../food_form.dart';
import '../widgets/filter_pills.dart';
import '../widgets/top_tabs.dart';

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
      appBar: AppBar(title: Text(tr(context, 'tabFoods'))),
      body: TopTabs(
        tabs: [tr(context, 'foods'), tr(context, 'templates')],
        pageBuilder: (_, i) => i == 0
            ? _FoodsTab(onQuery: (v) => setState(() => _query = v), query: _query)
            : const _TemplatesTab(),
      ),
    );
  }
}

/// 食物来源筛选
enum FoodSourceFilter { all, fav, builtin, custom, off }

class _FoodsTab extends ConsumerStatefulWidget {
  const _FoodsTab({required this.onQuery, required this.query});

  final ValueChanged<String> onQuery;
  final String query;

  @override
  ConsumerState<_FoodsTab> createState() => _FoodsTabState();
}

class _FoodsTabState extends ConsumerState<_FoodsTab> {
  FoodSourceFilter _source = FoodSourceFilter.all;

  bool _match(Food f) => switch (_source) {
        FoodSourceFilter.all => true,
        FoodSourceFilter.fav => f.favorite,
        FoodSourceFilter.builtin => f.source == 'builtin',
        FoodSourceFilter.custom => f.source != 'builtin' && f.source != 'off',
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
                  onChanged: widget.onQuery,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr(context, 'searchName'),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: tr(context, 'newCustomFood'),
                onPressed: () => showFoodForm(context),
                icon: const Icon(Icons.add),
              ),
            ],
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
              final list =
                  (snap.data ?? const <Food>[]).where(_match).toList();
              if (list.isEmpty) {
                return Center(child: Text(tr(context, 'noFoods')));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: list.length,
                itemBuilder: (context, i) => _FoodRow(food: list[i]),
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
    final badge = switch (food.source) {
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
        '${tr(context, 'carbShort')} ${round1(food.carb100)} · $badge',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: food.favorite
                ? tr(context, 'favRemove')
                : tr(context, 'favAdd'),
            icon: Icon(
              food.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: food.favorite ? Colors.amber : null,
            ),
            onPressed: () => db.toggleFavorite(food),
          ),
          PopupMenuButton<String>(
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
          child: Row(
            children: [
              Expanded(
                child: Text(tr(context, 'templateHint'),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              FilledButton.tonalIcon(
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const _TemplateEditor()),
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr(context, 'newTemplate')),
              ),
            ],
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
                children: [
                  for (final t in list) _TemplateRow(template: t),
                ],
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
      subtitle: Text(tr(context, 'tapToEdit'),
          style: Theme.of(context).textTheme.bodySmall),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'delete') {
            await showConfirmDialog(
              context,
              title:
                  tr(context, 'delTplTitle', {'name': template.name}),
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
          builder: (_) => _TemplateEditor(existing: template)),
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
      : ctrl = TextEditingController(text: round1(grams).toString());
  final Food food;
  final TextEditingController ctrl;

  double? get grams => double.tryParse(ctrl.text.trim());

  void dispose() => ctrl.dispose();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  late final TextEditingController _nameCtrl;
  final List<_TemplateItemRow> _items = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name);
    _load();
  }

  Future<void> _load() async {
    final existing = widget.existing;
    if (existing == null) return;
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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _addFood() async {
    final food = await showFoodSearchDialog(context);
    if (food == null) return;
    setState(() => _items.add(_TemplateItemRow(food, food.servingGrams ?? 100)));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context, 'needNameItems'))));
      return;
    }
    final parsed = <(int, double)>[];
    for (final it in _items) {
      final g = it.grams;
      if (g == null || g <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                tr(context, 'invalidGrams', {'name': it.food.name}))));
        return;
      }
      parsed.add((it.food.id, g));
    }
    final db = ref.read(dbProvider);
    if (widget.existing == null) {
      await db.saveTemplate(name, parsed);
    } else {
      await db.updateTemplate(widget.existing!.id, name, parsed);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var totalKcal = 0.0;
    for (final it in _items) {
      final g = it.grams;
      if (g != null) totalKcal += it.food.kcal100 * g / 100;
    }
    return AlertDialog(
      title: Text(widget.existing == null
          ? tr(context, 'newTemplate')
          : tr(context, 'editTplTitle')),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: tr(context, 'nameField'),
                  hintText: tr(context, 'nameHint')),
            ),
            const SizedBox(height: 8),
            Text(
                tr(context, 'tplSummary', {
                  'n': '${_items.length}',
                  'k': '${round1(totalKcal)}',
                }),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(tr(context, 'tplEmpty'),
                          style: Theme.of(context).textTheme.bodySmall))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final it = _items[i];
                        return Row(
                          children: [
                            Expanded(
                              child: Text(it.food.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            // 克数步进：±50g 就地生效，顶部汇总实时回显
                            _StepButton(
                              icon: Icons.remove,
                              onTap: () => setState(() {
                                final g = (it.grams ?? 0) - 50;
                                it.ctrl.text = (g < 0 ? 0 : g).toStringAsFixed(0);
                              }),
                            ),
                            SizedBox(
                              width: 72,
                              child: TextField(
                                controller: it.ctrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]')),
                                ],
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                    suffixText: 'g', isDense: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            _StepButton(
                              icon: Icons.add,
                              onTap: () => setState(() {
                                final g = (it.grams ?? 0) + 50;
                                it.ctrl.text = g.toStringAsFixed(0);
                              }),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => _items.removeAt(i)),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            OutlinedButton.icon(
              onPressed: _addFood,
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr(context, 'addFood')),
            ),
          ],
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

/// 组合餐编辑器里的圆形小步进按钮
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 15, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
