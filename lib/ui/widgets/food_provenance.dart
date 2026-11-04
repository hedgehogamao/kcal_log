import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../logic/i18n.dart';
import '../../logic/food_search.dart';
import '../../logic/providers.dart';

/// Read only real ownership links. A catalog's revision is not a claim that a
/// locally edited food still equals that catalog's original nutrient snapshot.
List<String> linkedFoodRevisions(Food food, Iterable<FoodCatalog> catalogs) {
  final out = <String>[];
  for (final catalog in catalogs) {
    try {
      final state = jsonDecode(catalog.stateJson);
      if (state is! Map || state['items'] is! Map) continue;
      for (final entry in (state['items'] as Map).entries) {
        final item = entry.value;
        if (item is Map && item['foodId'] == food.id) {
          out.add(
            '${catalog.title} · ${catalog.packId} · r${catalog.revision} · ${entry.key}',
          );
        }
      }
    } catch (_) {
      // Corrupt or unrelated catalog metadata must not become invented provenance.
    }
  }
  return out;
}

class FoodProvenance extends ConsumerStatefulWidget {
  const FoodProvenance({super.key, required this.food});
  final Food food;
  @override
  ConsumerState<FoodProvenance> createState() => _FoodProvenanceState();
}

class _FoodProvenanceState extends ConsumerState<FoodProvenance> {
  late final _catalogs = ref
      .read(dbProvider)
      .select(ref.read(dbProvider).foodCatalogs)
      .watch();
  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final aliases = foodSearchAliases(food.name);
    final source = switch (food.source) {
      'builtin' => 'sourceBuiltin',
      'pack' => 'sourceFoodPack',
      'off' => 'offSourceLabel',
      _ => 'sourceCustom',
    };
    return ExpansionTile(
      key: const ValueKey('food-provenance'),
      tilePadding: EdgeInsets.zero,
      title: Text(tr(context, 'foodProvenance')),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(context, 'foodOriginalName')),
              SelectableText(food.name),
              if (aliases.isNotEmpty)
                Text(
                  "${tr(context, 'foodSearchAliases')}: ${aliases.join(', ')}",
                ),
              Text(tr(context, source)),
              Text(tr(context, 'foodPreparationHint')),
              StreamBuilder<List<FoodCatalog>>(
                stream: _catalogs,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const LinearProgressIndicator();
                  }
                  final links = linkedFoodRevisions(food, snapshot.data ?? []);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          context,
                          links.isEmpty
                              ? 'foodRevisionUnknown'
                              : 'foodRevisionHint',
                        ),
                      ),
                      for (final link in links) SelectableText(link),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
