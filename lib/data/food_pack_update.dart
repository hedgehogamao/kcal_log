import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'food_pack.dart';

final foodPackUpdateProvider = Provider<FoodPackUpdateService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return FoodPackUpdateService(client);
});

/// Only invoked explicitly by the user. Downloads data, never code or personal records.
class FoodPackUpdateService {
  FoodPackUpdateService(this.client);
  final http.Client client;
  static const repository = 'hedgehogamao/kcal_log';
  Future<Uint8List> _read(Uri url, int limit) async {
    final request = http.Request('GET', url)
      ..headers['User-Agent'] = 'KcalLog/FoodPackUpdater';
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const FoodPackException('packReadFail');
    }
    if (response.contentLength != null && response.contentLength! > limit) {
      throw const FoodPackException('packTooLarge');
    }
    final out = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      if (out.length + chunk.length > limit) {
        throw const FoodPackException('packTooLarge');
      }
      out.add(chunk);
    }
    return out.takeBytes();
  }

  Future<FoodPack> check() async {
    final metadata = jsonDecode(
      utf8.decode(
        await _read(
          Uri.https('api.github.com', '/repos/$repository/releases/latest'),
          1024 * 1024,
        ),
      ),
    );
    if (metadata is! Map ||
        metadata['draft'] != false ||
        metadata['assets'] is! List) {
      throw const FoodPackException('packReadFail');
    }
    final candidates = <Map>[];
    for (final asset in metadata['assets']) {
      if (asset is Map &&
          asset['name'] is String &&
          RegExp(r'^common-foods-\d+\.json$').hasMatch(asset['name'])) {
        candidates.add(asset);
      }
    }
    candidates.sort(
      (a, b) =>
          int.parse(
            (b['name'] as String).split('-').last.split('.').first,
          ).compareTo(
            int.parse((a['name'] as String).split('-').last.split('.').first),
          ),
    );
    if (candidates.isEmpty) throw const FoodPackException('packReadFail');
    final asset = candidates.first;
    final url = Uri.tryParse(asset['browser_download_url']?.toString() ?? '');
    final digest = asset['digest'];
    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment ||
        !url.path.startsWith('/$repository/releases/download/') ||
        url.pathSegments.last != asset['name'] ||
        digest is! String ||
        !RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(digest)) {
      throw const FoodPackException('packIntegrity');
    }
    final bytes = await _read(url, foodPackMaxBytes);
    if ('sha256:${sha256.convert(bytes)}' != digest) {
      throw const FoodPackException('packIntegrity');
    }
    final pack = FoodPack.decode(bytes);
    if (pack.id != 'kcal-log.common-foods') {
      throw const FoodPackException('packIntegrity');
    }
    return pack;
  }
}
