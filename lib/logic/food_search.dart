/// 本地食物搜索：空格分词、名称/品牌/条码匹配，以及少量常见同义词。
/// 只影响查找，不改用户保存的食物名称或营养数据。
String normalizeFoodSearchText(String text) {
  var value = text.toLowerCase().replaceAll(RegExp(r'[\s（）()·・_\-&]'), '');
  for (final (variant, canonical) in _synonyms) {
    value = value.replaceAll(variant, canonical);
  }
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
];

/// 分数越低越靠前；null 表示至少一个搜索词未命中。
int? foodMatchRank({
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
