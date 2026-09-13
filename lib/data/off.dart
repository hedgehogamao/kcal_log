import 'dart:convert';

import 'package:http/http.dart' as http;

/// Open Food Facts 只读查询（开放 API，不存储任何用户数据）
class OffFood {
  const OffFood({
    this.barcode,
    required this.name,
    this.brand,
    required this.kcal100,
    this.protein100 = 0,
    this.fat100 = 0,
    this.carb100 = 0,
  });
  final String? barcode;
  final String name;
  final String? brand;
  final double kcal100;
  final double protein100;
  final double fat100;
  final double carb100;
}

double? _num(dynamic v) => (v is num) ? v.toDouble() : null;

OffFood? _parseProduct(Map<String, dynamic> p) {
  final nutr = p['nutriments'];
  if (nutr is! Map<String, dynamic>) return null;
  final kcal = _num(nutr['energy-kcal_100g']) ??
      ((_num(nutr['energy_100g']) != null)
          ? _num(nutr['energy_100g'])! / 4.184
          : null);
  final name = (p['product_name'] as String?)?.trim() ?? '';
  if (kcal == null || kcal < 0 || name.isEmpty) return null;
  return OffFood(
    barcode: (p['code'] as String?)?.trim().isEmpty == true
        ? null
        : (p['code'] as String?)?.trim(),
    name: name,
    brand: (p['brands'] as String?)?.split(',').firstOrNull?.trim(),
    kcal100: kcal,
    protein100: _num(nutr['proteins_100g']) ?? 0,
    fat100: _num(nutr['fat_100g']) ?? 0,
    carb100: _num(nutr['carbohydrates_100g']) ?? 0,
  );
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Future<List<OffFood>> searchOpenFoodFacts(String query, {int limit = 20}) async {
  final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
    'search_terms': query,
    'search_simple': '1',
    'action': 'process',
    'json': '1',
    'page_size': '$limit',
    'fields': 'code,product_name,brands,nutriments',
  });
  final res = await http
      .get(uri, headers: {'User-Agent': 'KcalLog - Android/iOS/macOS/Windows'})
      .timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) {
    throw Exception('Open Food Facts HTTP ${res.statusCode}');
  }
  final body = jsonDecode(utf8.decode(res.bodyBytes));
  final products = body['products'];
  if (products is! List) return [];
  final out = <OffFood>[];
  for (final p in products) {
    if (p is Map<String, dynamic>) {
      final f = _parseProduct(p);
      if (f != null) out.add(f);
    }
  }
  return out;
}

Future<OffFood?> lookupByBarcode(String code) async {
  final clean = code.trim();
  if (clean.isEmpty) return null;
  final uri = Uri.https(
      'world.openfoodfacts.org', '/api/v2/product/$clean.json',
      {'fields': 'code,product_name,brands,nutriments'});
  final res = await http
      .get(uri, headers: {'User-Agent': 'KcalLog - Android/iOS/macOS/Windows'})
      .timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) return null;
  final body = jsonDecode(utf8.decode(res.bodyBytes));
  if (body is! Map<String, dynamic>) return null;
  if (body['status'] == 0) return null;
  final p = body['product'];
  if (p is! Map<String, dynamic>) return null;
  return _parseProduct(p);
}
