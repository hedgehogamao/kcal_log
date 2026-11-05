import 'package:flutter_test/flutter_test.dart';
import 'package:kcal_log/logic/food_search.dart';

void main() {
  test('long-running caches have both entry and text-size bounds; long inputs still normalize correctly', () {
    for (var i = 0; i < 2400; i++) {
      final name = '$i${'膳' * 380}';
      normalizeFoodSearchText(name);
      foodMatchRank(name: name, query: 'notpresent');
    }
    var stats = foodSearchCacheFootprint();
    expect(stats.normalizedEntries, lessThanOrEqualTo(16384));
    expect(stats.normalizedCharacters, inInclusiveRange(0, 2 * 1024 * 1024));
    expect(stats.pinyinEntries, lessThanOrEqualTo(8192));
    expect(stats.pinyinCharacters, inInclusiveRange(0, 2 * 1024 * 1024));
    final before = stats;
    final long = '西红柿${'a' * 1000}';
    expect(normalizeFoodSearchText(long), '番茄${'a' * 1000}');
    stats = foodSearchCacheFootprint();
    expect(stats.normalizedCharacters, before.normalizedCharacters);
  });
}
