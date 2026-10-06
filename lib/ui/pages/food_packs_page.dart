import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/food_pack.dart';
import '../../logic/i18n.dart';
import '../../logic/providers.dart';

class FoodPacksPage extends ConsumerStatefulWidget {
  const FoodPacksPage({super.key});
  @override
  ConsumerState<FoodPacksPage> createState() => _FoodPacksPageState();
}

class _FoodPacksPageState extends ConsumerState<FoodPacksPage> {
  bool _busy = false;
  bool _confirming = false;
  String? _result;
  String? _error;
  late final Stream<List<FoodCatalog>> _catalogs = ref
      .read(dbProvider)
      .select(ref.read(dbProvider).foodCatalogs)
      .watch();

  Future<Uint8List> _read(PlatformFile file) async {
    if (file.size > foodPackMaxBytes) {
      throw const FoodPackException('packTooLarge');
    }
    if (file.bytes != null) return file.bytes!;
    final stream =
        file.readStream ??
        (file.path == null ? null : File(file.path!).openRead());
    if (stream == null) throw const FoodPackException('packReadFail');
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > foodPackMaxBytes) {
        throw const FoodPackException('packTooLarge');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
        withReadStream: true,
      );
      if (picked == null || !mounted) return;
      final pack = FoodPack.decode(await _read(picked.files.single));
      final loader = FoodPackLoader(ref.read(dbProvider));
      final plan = await loader.preview(pack);
      if (!mounted) return;
      if (plan.current) {
        setState(() => _result = tr(context, 'packCurrent'));
        return;
      }
      setState(() => _confirming = true);
      final approved = await showDialog<bool>(
        context: context,
        builder: (_) => _PackPreview(plan: plan),
      );
      if (mounted) setState(() => _confirming = false);
      if (approved != true || !mounted) return;
      final actual = await loader.apply(pack);
      if (mounted) {
        setState(
          () => _result = actual.current
              ? tr(context, 'packCurrent')
              : tr(context, 'packResult', {
                  'a': '${actual.added}',
                  'u': '${actual.updated}',
                  'p': '${actual.protected}',
                }),
        );
      }
    } on FoodPackException catch (e) {
      if (mounted) setState(() => _error = tr(context, e.code));
    } catch (_) {
      if (mounted) setState(() => _error = tr(context, 'packReadFail'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'foodPacks'))),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(context, 'packHeadline'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(tr(context, 'packHelp')),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('food-pack-pick'),
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(tr(context, 'packPick')),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'packLimit'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (_busy && !_confirming) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(tr(context, 'working')),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  key: const ValueKey('food-pack-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_result!, key: const ValueKey('food-pack-result')),
              ),
            const SizedBox(height: 20),
            Text(
              tr(context, 'packInstalled'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<FoodCatalog>>(
              stream: _catalogs,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text(tr(context, 'packReadFail'));
                if (!snapshot.hasData) return const LinearProgressIndicator();
                if (snapshot.data!.isEmpty) {
                  return Text(tr(context, 'packNone'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final pack in snapshot.data!)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                pack.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr(context, 'packRevision', {
                                  'n': '${pack.revision}',
                                }),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                pack.packId,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _PackPreview extends StatelessWidget {
  const _PackPreview({required this.plan});
  final FoodPackPlan plan;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr(context, 'packPreview')),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.pack.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.pack.id} · ${tr(context, 'packRevision', {'n': '${plan.pack.revision}'})}',
            ),
            const Divider(height: 24),
            for (final (key, count) in [
              ('packAdded', plan.added),
              ('packUpdated', plan.updated),
              ('packProtected', plan.protected),
              ('packUnchanged', plan.unchanged),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tr(context, key, {'n': '$count'})),
              ),
            const Divider(height: 24),
            Text(tr(context, 'packProtectHelp')),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(tr(context, 'cancel')),
      ),
      FilledButton(
        key: const ValueKey('food-pack-apply'),
        onPressed: () => Navigator.pop(context, true),
        child: Text(tr(context, 'packApply')),
      ),
    ],
  );
}
