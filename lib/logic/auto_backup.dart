import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

class BackupInfo {
  const BackupInfo(
    this.file,
    this.createdAt,
    this.bytes,
    this.payloadHash, {
    this.valid = true,
  });
  final File file;
  final DateTime createdAt;
  final int bytes;
  final String payloadHash;
  final bool valid;
}

class BackupPreview {
  const BackupPreview(this.info, this.payload, this.changes, this.currentHash);
  final String currentHash;
  final BackupInfo info;
  final Map<String, dynamic> payload;
  // Per-table (added, changed, removed), with primary-key comparison, not just counts.
  final Map<String, (int, int, int)> changes;
}

/// Local, opt-in snapshots. Never starts an OS background process or network request.
/// Retention applies only to this service's exact filenames, never arbitrary JSON.
class AutoBackupService {
  AutoBackupService({
    required this.directory,
    required this.export,
    DateTime Function()? now,
    this.maxFiles = 14,
    this.maxTotalBytes = 50 * 1024 * 1024,
    this.maxFileBytes = 8 * 1024 * 1024,
    this.minimumInterval = const Duration(minutes: 15),
    Future<void> Function(File, List<int>)? writer,
  }) : now = now ?? DateTime.now,
       writer = writer ?? _write;
  final Future<Directory> Function() directory;
  final Future<Map<String, dynamic>> Function() export;
  final DateTime Function() now;
  final int maxFiles, maxTotalBytes, maxFileBytes;
  final Duration minimumInterval;
  final Future<void> Function(File, List<int>) writer;
  bool enabled = false;
  Future<BackupInfo?>? _work;
  static final _name = RegExp(
    r'^kcallog-auto-\d{8}T\d{12}Z-[a-f0-9]{12}\.json$',
  );
  static const tables = [
    'foods',
    'entries',
    'weights',
    'waters',
    'templates',
    'templateItems',
    'foodCatalogs',
  ];
  static Future<void> _write(File f, List<int> bytes) async {
    await f.writeAsBytes(bytes, flush: true);
  }

  static Map<String, dynamic> _validate(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['app'] != 'kcal_log' ||
        value['schema'] != 1 ||
        !tables.take(6).every((k) => value[k] is List) ||
        (value['foodCatalogs'] != null && value['foodCatalogs'] is! List) ||
        (value['profile'] != null && value['profile'] is! Map)) {
      throw const FormatException('Invalid backup payload');
    }
    return value;
  }

  static String contentHash(Map<String, dynamic> p) => sha256
      .convert(utf8.encode(jsonEncode({...p}..remove('exportedAt'))))
      .toString();
  Future<Directory> _directory() async {
    final d = await directory();
    if (await FileSystemEntity.isLink(d.path)) {
      throw const FileSystemException('Linked backup directory refused');
    }
    return d;
  }

  Future<Map<String, dynamic>> read(BackupInfo info) async {
    final root = await _directory();
    if (info.file.parent.absolute.path != root.absolute.path ||
        !_name.hasMatch(info.file.uri.pathSegments.last) ||
        await FileSystemEntity.isLink(info.file.path)) {
      throw const FormatException('Not a managed backup');
    }
    if (await info.file.length() > maxFileBytes) {
      throw const FormatException('Backup too large');
    }
    final bytes = await info.file.readAsBytes();
    if (bytes.length > maxFileBytes) {
      throw const FormatException('Backup too large');
    }
    final x = jsonDecode(utf8.decode(bytes));
    if (x is! Map ||
        x['format'] != 'kcallog-auto-backup' ||
        x['version'] != 1 ||
        x['createdAt'] is! String) {
      throw const FormatException('Invalid backup envelope');
    }
    final p = _validate(x['payload']);
    if (contentHash(p) != x['payloadHash'] ||
        (info.payloadHash.isNotEmpty && x['payloadHash'] != info.payloadHash)) {
      throw const FormatException('Backup checksum changed');
    }
    return p;
  }

  Future<List<BackupInfo>> list() async {
    final root = await _directory();
    if (!await root.exists()) return [];
    final items = <BackupInfo>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! File || !_name.hasMatch(entity.uri.pathSegments.last)) {
        continue;
      }
      final stat = await entity.stat();
      final fallback = BackupInfo(
        entity,
        stat.modified.toUtc(),
        stat.size,
        '',
        valid: false,
      );
      try {
        final payload = await read(fallback);
        final data = jsonDecode(await entity.readAsString()) as Map;
        final created = DateTime.parse(data['createdAt'] as String);
        items.add(BackupInfo(entity, created, stat.size, contentHash(payload)));
      } catch (_) {
        items.add(fallback);
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<BackupInfo?> capture({
    bool force = false,
    bool userInitiated = false,
  }) {
    if (!enabled && !userInitiated) return Future.value();
    if (_work != null) return _work!;
    final work = _capture(force: force, userInitiated: userInitiated);
    _work = work;
    return work.whenComplete(() => _work = null);
  }

  Future<BackupInfo?> _capture({
    required bool force,
    required bool userInitiated,
  }) async {
    if (maxFiles < 1 || maxTotalBytes < 1) {
      throw ArgumentError('Retention must be positive');
    }
    final payload = _validate(await export());
    if (!enabled && !userInitiated) return null;
    final stamp = now().toUtc(),
        hash = contentHash(payload),
        old = await list();
    final valid = old.where((x) => x.valid).toList();
    if (!force && valid.isNotEmpty) {
      final latest = valid.first,
          day = stamp.toLocal(),
          last = latest.createdAt.toLocal();
      final sameDay =
          day.year == last.year &&
          day.month == last.month &&
          day.day == last.day;
      if ((sameDay && latest.payloadHash == hash) ||
          stamp.difference(latest.createdAt) < minimumInterval) {
        return null;
      }
    }
    final bytes = utf8.encode(
      jsonEncode({
        'format': 'kcallog-auto-backup',
        'version': 1,
        'createdAt': stamp.toIso8601String(),
        'payloadHash': hash,
        'payload': payload,
      }),
    );
    if (bytes.length > maxFileBytes || bytes.length > maxTotalBytes) {
      throw const FormatException(
        'Snapshot exceeds storage limit; previous snapshots preserved',
      );
    }
    final root = await _directory();
    if (!enabled && !userInitiated) return null;
    await root.create(recursive: true);
    String pad(int n, int width) => n.toString().padLeft(width, '0');
    final time =
        '${pad(stamp.year, 4)}${pad(stamp.month, 2)}${pad(stamp.day, 2)}T${pad(stamp.hour, 2)}${pad(stamp.minute, 2)}${pad(stamp.second, 2)}${pad(stamp.millisecond * 1000 + stamp.microsecond, 6)}Z';
    final id = List.generate(
      6,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final file = File('${root.path}/kcallog-auto-$time-$id.json');
    final temp = File('${file.path}.part');
    try {
      if (await file.exists() || await temp.exists()) {
        throw const FileSystemException('Snapshot path collision');
      }
      await writer(temp, bytes);
      if (!enabled && !userInitiated) return null;
      // Verify written bytes before the atomic rename or retention cleanup.
      if (sha256.convert(await temp.readAsBytes()).toString() !=
          sha256.convert(bytes).toString()) {
        throw const FormatException('Snapshot write verification failed');
      }
      await temp.rename(file.path);
      final info = BackupInfo(file, stamp, bytes.length, hash);
      await read(info);
      final all = [info, ...old];
      var count = 0, total = 0;
      for (final item in all) {
        count++;
        total += item.bytes;
        if (count > maxFiles || total > maxTotalBytes) {
          await item.file.delete();
        }
      }
      return info;
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<BackupPreview> preview(
    BackupInfo info,
    Map<String, dynamic> current,
  ) async {
    final p = await read(info);
    _validate(current);
    Map<String, dynamic> byKey(dynamic rows) => {
      for (final x in rows as List? ?? [])
        '${(x as Map)['id'] ?? x['date'] ?? x['packId']}': x,
    };
    final changes = <String, (int, int, int)>{};
    for (final table in [...tables, 'profile']) {
      final a = table == 'profile'
          ? {if (current[table] != null) '1': current[table]}
          : byKey(current[table]);
      final b = table == 'profile'
          ? {if (p[table] != null) '1': p[table]}
          : byKey(p[table]);
      changes[table] = (
        b.keys.where((k) => !a.containsKey(k)).length,
        b.keys
            .where(
              (k) => a.containsKey(k) && jsonEncode(a[k]) != jsonEncode(b[k]),
            )
            .length,
        a.keys.where((k) => !b.containsKey(k)).length,
      );
    }
    return BackupPreview(info, p, changes, contentHash(current));
  }
}
