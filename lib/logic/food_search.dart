import 'pinyin_data.dart';

final _normalizedCache = <String, String>{};
final _hanText = RegExp(r'[\u3400-\u9fff]');
final _latinOnly = RegExp(r'^[a-z]+$');
final _hanOnly = RegExp(r'^[\u3400-\u9fff]+$');
final _wordSplit = RegExp(r'[^a-z]+');

/// 本地食物搜索：空格分词、名称/品牌/条码匹配，以及少量常见同义词。
/// 只影响查找，不改用户保存的食物名称或营养数据。
String normalizeFoodSearchText(String text) {
  final cached = _normalizedCache[text];
  if (cached != null) return cached;
  var value = text.toLowerCase().replaceAll(RegExp(r'[\s（）()·・_\-&]'), '');
  for (final (variant, canonical) in _synonyms) {
    value = value.replaceAll(variant, canonical);
  }
  if (_normalizedCache.length >= 16384) {
    _normalizedCache.remove(_normalizedCache.keys.first);
  }
  _normalizedCache[text] = value;
  return value;
}

const _synonyms = <(String, String)>[
  ('西红柿', '番茄'),
  ('蕃茄', '番茄'),
  ('马铃薯', '土豆'),
  ('洋芋', '土豆'),
  ('地瓜', '红薯'),
  ('番薯', '红薯'),
  ('鸡脯', '鸡胸'),
  ('牛乳', '牛奶'),
  ('优格', '酸奶'),
  ('酸乳', '酸奶'),
  ('凤梨', '菠萝'),
  ('奇异果', '猕猴桃'),
  ('士多啤梨', '草莓'),
  ('椰菜花', '花椰菜'),
  ('菜花', '花椰菜'),
  ('荷兰薯', '土豆'),
  ('青瓜', '黄瓜'),
  ('通心菜', '空心菜'),
  ('包心菜', '卷心菜'),
  ('圆白菜', '卷心菜'),
  ('包菜', '卷心菜'),
  ('洋白菜', '卷心菜'),
  ('甘蓝菜', '卷心菜'),
  ('玉蜀黍', '玉米'),
  ('苞米', '玉米'),
  ('薯仔', '土豆'),
  ('花生米', '花生'),
  ('番瓜', '南瓜'),
  ('白薯', '红薯'),
];

/// 分数越低越靠前；null 表示至少一个搜索词未命中。
int? _strictFoodMatchRank({
  required String name,
  required String query,
  String? brand,
  String? barcode,
  String? category,
}) {
  final terms = query.trim().split(RegExp(r'\s+'));
  if (terms.length == 1 && terms.first.isEmpty) return 0;
  if (terms.every((term) => normalizeFoodSearchText(term).isEmpty)) {
    return null;
  }
  final normalizedName = normalizeFoodSearchText(name);
  final normalizedBrand = normalizeFoodSearchText(brand ?? '');
  final normalizedBarcode = normalizeFoodSearchText(barcode ?? '');
  final categoryTerms = _categorySearchTerms[category] ?? const <String>[];
  final normalizedQuery = normalizeFoodSearchText(query);
  if (normalizedName == normalizedQuery ||
      normalizedBarcode == normalizedQuery) {
    return 0;
  }
  if (categoryTerms.any(
    (value) => normalizeFoodSearchText(value) == normalizedQuery,
  )) {
    return 5;
  }
  var score = 0;
  for (final rawTerm in terms) {
    final term = normalizeFoodSearchText(rawTerm);
    if (term.isEmpty) continue;
    if (normalizedName == term || normalizedBarcode == term) {
      continue;
    } else if (normalizedName.startsWith(term)) {
      score += 1;
    } else if (normalizedName.contains(term)) {
      score += 2;
    } else if (normalizedBrand.startsWith(term)) {
      score += 3;
    } else if (normalizedBrand.contains(term) ||
        normalizedBarcode.contains(term)) {
      score += 4;
    } else if (categoryTerms.any(
      (value) => normalizeFoodSearchText(value) == term,
    )) {
      score += 5;
    } else {
      return null;
    }
  }
  return score;
}

/// Literal/synonym results always outrank pinyin and explicit approximate suggestions.
/// Never changes the stored name, preparation, serving size or nutrient values.
int? foodMatchRank({
  required String name,
  required String query,
  String? brand,
  String? barcode,
  String? category,
}) => foodSearchMatch(
  name: name,
  query: query,
  brand: brand,
  barcode: barcode,
  category: category,
)?.rank;

class FoodSearchMatch {
  const FoodSearchMatch(this.rank, {this.approximate = false});
  final int rank;
  final bool approximate;
}

FoodSearchMatch? foodSearchMatch({
  required String name,
  required String query,
  String? brand,
  String? barcode,
  String? category,
}) {
  final strict = _strictFoodMatchRank(
    name: name,
    query: query,
    brand: brand,
    barcode: barcode,
    category: category,
  );
  if (strict != null) return FoodSearchMatch(strict);
  if (normalizeFoodSearchText(query).isEmpty) return null;
  final terms = query.trim().split(RegExp(r'\s+'));
  var score = 0;
  var approximate = false;
  for (final raw in terms) {
    final term = normalizeFoodSearchText(raw);
    if (term.isEmpty) continue;
    final literal = terms.length == 1
        ? null
        : _strictFoodMatchRank(
            name: name,
            query: raw,
            brand: brand,
            barcode: barcode,
            category: category,
          );
    if (literal != null) {
      score += literal;
      continue;
    }
    final keys = _keys(name);
    if (_latinOnly.hasMatch(term) && term.length >= 2) {
      if (keys.any((k) => k.$1.contains(term))) {
        score += 12;
        continue;
      }
      if (keys.any((k) => k.$2.contains(term))) {
        score += 16;
        continue;
      }
    }
    // Barcode digits, short words, and explicit preparation words are never corrected.
    final latin = _latinOnly.hasMatch(term) && term.length >= 4;
    final han = _hanOnly.hasMatch(term) && term.runes.length >= 3;
    final protectedWords = [
      '面',
      '饭',
      '奶',
      '蛋',
      '豆',
      '茶',
      '酒',
      '饼',
      '糕',
      '粥',
      '汁',
      '皮',
      '骨',
      '瘦',
      '肥',
      '牛',
      '猪',
      '鸡',
      '羊',
      '鸭',
      '鱼',
      '虾',
      '蟹',
      '生',
      '熟',
      '干',
      '湿',
      '粉',
      '油',
      '糖',
      '无糖',
      '含糖',
      '脱脂',
      '全脂',
      'raw',
      'cooked',
      'dried',
      'powder',
      'unsweetened',
      'skim',
    ];
    if ((!latin && !han) ||
        term.length > 40 ||
        protectedWords.any(
          (w) => term.contains(w) && !normalizeFoodSearchText(name).contains(w),
        )) {
      return null;
    }
    final words = han
        ? [normalizeFoodSearchText(name)]
        : normalizeFoodSearchText(name).split(_wordSplit);
    // Preserve word boundaries for English rather than fuzzy matching a concatenated food name.
    final english = name.toLowerCase().split(_wordSplit);
    final candidates = latin ? [...english, ...keys.map((k) => k.$1)] : words;
    if (!candidates.any((w) => _oneEdit(term, w))) return null;
    score += 40;
    approximate = true;
  }
  return FoodSearchMatch(20 + score, approximate: approximate);
}

final _pinyinCache = <String, List<(String, String)>>{};
List<(String, String)> _keys(String name) {
  final cached = _pinyinCache[name];
  if (cached != null) return cached;
  if (_pinyinCache.length >= 8192) _pinyinCache.remove(_pinyinCache.keys.first);
  if (!_hanText.hasMatch(name)) {
    _pinyinCache[name] = const [];
    return const [];
  }
  final variants = {
    name,
    ...foodSearchAliases(name),
    normalizeFoodSearchText(name),
  };
  final result = [
    for (final v in variants)
      if (_hanText.hasMatch(v)) _transliterate(v),
  ];
  _pinyinCache[name] = result;
  return result;
}

(String, String) _transliterate(String text) {
  final full = StringBuffer(), initials = StringBuffer();
  // Phrase-level food readings override ambiguous single-character Mandarin defaults.
  const phrases = {
    '重庆': ('chongqing', 'cq'),
    '茄子': ('qiezi', 'qz'),
    '番茄': ('fanqie', 'fq'),
    '长豆角': ('changdoujiao', 'cdj'),
    '朝鲜': ('chaoxian', 'cx'),
    '荸荠': ('biqi', 'bq'),
  };
  var offset = 0;
  while (offset < text.length) {
    var matched = false;
    for (final e in phrases.entries) {
      if (text.startsWith(e.key, offset)) {
        full.write(e.value.$1);
        initials.write(e.value.$2);
        offset += e.key.length;
        matched = true;
        break;
      }
    }
    if (matched) continue;
    final rune = text.substring(offset).runes.first;
    final character = String.fromCharCode(rune);
    offset += character.length;
    final syllable = pinyinData[rune];
    if (syllable != null) {
      full.write(syllable);
      initials.write(syllable[0]);
    } else if (RegExp(r'[a-z0-9]').hasMatch(character.toLowerCase())) {
      full.write(character.toLowerCase());
      initials.write(character.toLowerCase());
    } else if (_hanText.hasMatch(character)) {
      full.write(character);
      initials.write(character);
    }
  }
  return (full.toString(), initials.toString());
}

bool _oneEdit(String a, String b) {
  if (a == b) return true;
  if ((a.length - b.length).abs() > 1) return false;
  if (a.length == b.length) {
    final wrong = [
      for (var i = 0; i < a.length; i++)
        if (a[i] != b[i]) i,
    ];
    return wrong.length == 1 ||
        (wrong.length == 2 &&
            wrong[1] == wrong[0] + 1 &&
            a[wrong[0]] == b[wrong[1]] &&
            a[wrong[1]] == b[wrong[0]]);
  }
  final short = a.length < b.length ? a : b, long = a.length < b.length ? b : a;
  var i = 0, j = 0, skipped = false;
  while (i < short.length && j < long.length) {
    if (short[i] == long[j]) {
      i++;
      j++;
    } else {
      if (skipped) return false;
      skipped = true;
      j++;
    }
  }
  return true;
}

/// Localized category terms are searchable without changing saved food names.
const _categorySearchTerms = <String, List<String>>{
  'staple': ['主食', '谷物', 'grains', 'starches', 'Grains & starches', 'cereales'],
  'protein': ['蛋白类', '蛋白质', 'protein', 'proteínas'],
  'vegetable': ['蔬菜', 'vegetables', 'verduras'],
  'fruit': ['水果', 'fruit', 'frutas'],
  'dairy': ['乳制品', 'dairy', 'lácteos'],
  'snack': [
    '零食坚果',
    '零食',
    'snacks',
    'nuts',
    'Snacks & nuts',
    'aperitivos',
    'Aperitivos y frutos secos',
  ],
  'drink': ['饮品', '饮料', 'drinks', 'bebidas'],
  'dish': [
    '菜肴外食',
    '菜肴',
    'prepared',
    'dishes',
    'Prepared dishes',
    'platos',
    'preparados',
    'Platos preparados',
  ],
  'other': ['其他', 'other', 'otros'],
};

/// Search synonyms only: no renaming, nutrient equivalence or cooking inference.
List<String> foodSearchAliases(String name) => [
  for (final (variant, canonical) in _synonyms)
    if (normalizeFoodSearchText(name)
            .contains(normalizeFoodSearchText(canonical)) &&
        !name.contains(variant))
      variant,
];
