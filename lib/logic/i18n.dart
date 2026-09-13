import 'package:flutter/widgets.dart';

import '../data/db.dart';

/// 应用语言：中文（默认）→ English → Español
enum AppLang { en, es, zh }

extension AppLangX on AppLang {
  String get code => switch (this) {
        AppLang.en => 'en',
        AppLang.es => 'es',
        AppLang.zh => 'zh',
      };

  /// 右上角切换按钮显示的短标签
  String get short => switch (this) {
        AppLang.en => 'EN',
        AppLang.es => 'ES',
        AppLang.zh => '中',
      };

  AppLang get next => switch (this) {
        AppLang.zh => AppLang.en,
        AppLang.en => AppLang.es,
        AppLang.es => AppLang.zh,
      };
}

AppLang? appLangByCode(String? code) => switch (code) {
        'en' => AppLang.en,
        'es' => AppLang.es,
        'zh' => AppLang.zh,
        _ => null,
      };

/// 把整棵组件树包起来，让任意位置的 tr(context, ...) 都能拿到当前语言
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});

  final AppLang lang;

  static AppLang of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ?? AppLang.zh;

  @override
  bool updateShouldNotify(LangScope old) => old.lang != lang;
}

/// 文案表：(English, Español, 中文)
const Map<String, (String, String, String)> kStrings = {
  // ---- 导航 ----
  'tabToday': ('Today', 'Hoy', '今日'),
  'tabStats': ('Stats', 'Estadísticas', '统计'),
  'tabFoods': ('Foods', 'Alimentos', '食物库'),
  'tabSettings': ('Settings', 'Ajustes', '设置'),
  'langTip': ('Switch language', 'Cambiar idioma', '切换语言'),
  // ---- 餐次 ----
  'mealBreakfast': ('Breakfast', 'Desayuno', '早餐'),
  'mealLunch': ('Lunch', 'Almuerzo', '午餐'),
  'mealDinner': ('Dinner', 'Cena', '晚餐'),
  'mealSnack': ('Snack', 'Snack', '加餐'),
  // ---- 今日页 ----
  'today': ('Today', 'Hoy', '今天'),
  'consumed': ('Consumed', 'Consumido', '已摄入'),
  'remaining': ('Remaining', 'Restante', '还可摄入'),
  'over': ('Over by', 'Excedido', '已超出'),
  'goalNotSet': ('Goal not set', 'Objetivo no configurado', '目标未设置'),
  'setGoalCta': ('Set daily calorie goal', 'Configurar objetivo diario', '去设置每日热量目标'),
  'water': ('Water', 'Agua', '饮水'),
  'empty': ('No records yet', 'Sin registros aún', '还没有记录'),
  'items': ('{n} items', '{n} elem.', '{n} 项'),
  'itemsOne': ('{n} item', '{n} elem.', '{n} 项'),
  'add': ('Add', 'Añadir', '添加'),
  'deleted': ('Deleted "{name}"', '«{name}» eliminado', '已删除「{name}」'),
  'undo': ('Undo', 'Deshacer', '撤销'),
  'proteinShort': ('Protein', 'Proteína', '蛋白'),
  'fatShort': ('Fat', 'Grasa', '脂'),
  'carbShort': ('Carbs', 'Carbos', '碳水'),
  // ---- 图表 ----
  'less': ('Less', 'Menos', '少'),
  'more': ('More · red = over goal', 'Más · rojo = sobre el objetivo', '多 · 红色为超过目标'),
  // ---- 记录弹层 ----
  'entry': ('Entry', 'Registro', '记录'),
  'kcalField': ('Calories', 'Calorías', '热量'),
  'quickAddNote': ('Quick add: log calories only, no food attached', 'Añadir rápido: solo calorías, sin alimento', '快速添加：只记录热量，不关联具体食物'),
  'servingField': ('Serving', 'Porción', '份量'),
  'gramUnit': ('g', 'g', '克'),
  'previewHint': ('Enter grams to auto-calculate', 'Introduce los gramos para calcular', '输入份量后自动计算热量'),
  'previewMacro': ('Protein {p} · Fat {f} · Carbs {c} g', 'Proteína {p} · Grasa {f} · Carbohidratos {c} g', '蛋白质 {p} · 脂肪 {f} · 碳水 {c} g'),
  'saveEdit': ('Save changes', 'Guardar cambios', '保存修改'),
  'needKcal': ('Please enter calories', 'Introduce las calorías', '请输入热量'),
  'needGrams': ('Please enter serving (grams)', 'Introduce la porción (gramos)', '请输入份量（克）'),
  'cantCompute': ('Cannot calculate nutrition', 'No se puede calcular la nutrición', '无法计算营养值'),
  // ---- 添加流 / 食物选择 ----
  'addTo': ('Add to {meal}', 'Añadir a {meal}', '添加到{meal}'),
  'searchFoods': ('Search foods', 'Buscar alimentos', '搜索食物'),
  'searchOnlineSuffix': (' (also searching Open Food Facts)', ' (también en Open Food Facts)', '（同时搜索 Open Food Facts）'),
  'all': ('All', 'Todos', '全部'),
  'recent': ('Recent', 'Recientes', '最近'),
  'fav': ('Favorites', 'Favoritos', '收藏'),
  'offOnline': ('OFF online', 'OFF en línea', 'OFF 在线'),
  'quickAdd': ('Quick add', 'Añadir rápido', '快速添加'),
  'barcode': ('Barcode', 'Código', '条码'),
  'customFood': ('Custom food', 'Alimento propio', '自定义食物'),
  'noFavs': ('No favorite foods yet', 'Aún no hay favoritos', '还没有收藏的食物'),
  'noMatch': ('No matching foods — try "Custom food"', 'Sin resultados; prueba "Alimento propio"', '没有匹配的食物，试试「自定义食物」'),
  'noRecent': ('No records yet — add a meal first', 'Aún sin registros; añade una comida', '还没有记录，先去添加一餐吧'),
  'offSection': ('Open Food Facts (online results)', 'Open Food Facts (resultados en línea)', 'Open Food Facts（在线结果）'),
  'onlineFail': ('Online search failed (offline use unaffected)', 'Error de búsqueda en línea (el uso sin conexión no se afecta)', '在线搜索失败（不影响离线使用）'),
  'noOnlineResults': ('No online results', 'Sin resultados en línea', '没有在线结果'),
  'per100g': ('per 100g', 'por 100g', '每100g'),
  'barcodeTitle': ('Barcode lookup', 'Consultar código', '条码查询'),
  'barcodeHint': ('Enter product barcode', 'Introduce el código de barras', '输入商品条码'),
  'search': ('Search', 'Buscar', '查询'),
  'searching': ('Searching…', 'Buscando…', '正在查询…'),
  'notFound': ('No product found for this barcode', 'Sin resultados para este código', '未找到该条码的商品'),
  'templateAdded': ('Added {n} items from "{t}" to {meal}', 'Añadidos {n} elem. de «{t}» a {meal}', '已从「{t}」添加 {n} 项到{meal}'),
  'saveFail': ('Save failed', 'Error al guardar', '保存失败'),
  'logged': ('Logged {n} kcal', 'Registradas {n} kcal', '已记录 {n} kcal'),
  'sourceBuiltin': ('Built-in', 'Integrado', '内置'),
  'sourceCustom': ('Custom', 'Propio', '自定义'),
  // ---- 食物库页 ----
  'foods': ('Foods', 'Alimentos', '食物'),
  'templates': ('Templates', 'Combinaciones', '组合餐'),
  'searchName': ('Search food names', 'Buscar por nombre', '搜索食物名称'),
  'noFoods': ('No foods yet — tap + to create', 'Sin alimentos; toca + para crear', '没有食物，点右上角 + 新建'),
  'favAdd': ('Add to favorites', 'Añadir a favoritos', '收藏'),
  'favRemove': ('Remove from favorites', 'Quitar de favoritos', '取消收藏'),
  'edit': ('Edit', 'Editar', '编辑'),
  'delete': ('Delete', 'Eliminar', '删除'),
  'delFoodTitle': ('Delete "{name}"?', '¿Eliminar «{name}»?', '删除「{name}」？'),
  'delFoodBody': ('Existing entries keep their nutrition snapshot, but template items referencing this food are removed.', 'Los registros existentes conservan sus datos; se quita el alimento de las comidas guardadas.', '已有饮食记录会保留（营养快照不受影响），但组合餐中引用该食物的条目会被移除。'),
  'templateHint': ('Save a meal you often eat as a template and log it all at once', 'Guarda una comida habitual como plantilla y regístrala de una vez', '把常吃的一餐（如早餐套餐）存成组合，添加时一次记录全部'),
  'newTemplate': ('New meal template', 'Nueva combinación', '新建组合餐'),
  'noTemplates': ('No templates yet — tap "New meal template"', 'Sin combinaciones; toca "Nueva combinación"', '还没有组合餐，点「新建组合餐」创建'),
  'tapToEdit': ('Tap to view & edit', 'Toca para ver y editar', '点击查看与编辑'),
  'delTplTitle': ('Delete template "{name}"?', '¿Eliminar la combinación «{name}»?', '删除组合餐「{name}」？'),
  'delTplBody': ('Only the template is deleted; logged entries are kept.', 'Solo se borra la definición; los registros se conservan.', '只删除组合定义，不会删除已记录的饮食条目。'),
  'editTplTitle': ('Edit meal template', 'Editar combinación', '编辑组合餐'),
  'nameField': ('Name *', 'Nombre *', '名称 *'),
  'nameHint': ('e.g. Breakfast set', 'p. ej. Desayuno completo', '如：早餐套餐'),
  'tplSummary': ('{n} items · ~{k} kcal', '{n} elem. · ~{k} kcal', '共 {n} 项 · 约 {k} kcal'),
  'tplEmpty': ('No foods yet — tap "Add food" below', 'Sin alimentos; toca "Añadir alimento" abajo', '还没有食物，点下方「添加食物」'),
  'addFood': ('Add food', 'Añadir alimento', '添加食物'),
  'needNameItems': ('Enter a name and at least one food', 'Nombre y al menos un alimento', '请填写名称并至少添加一项食物'),
  'invalidGrams': ('Invalid grams for "{name}"', 'Gramos no válidos para «{name}»', '「{name}」的克数无效'),
  'save': ('Save', 'Guardar', '保存'),
  // ---- 食物表单 ----
  'editFood': ('Edit food', 'Editar alimento', '编辑食物'),
  'brand': ('Brand', 'Marca', '品牌'),
  'barcodeField': ('Barcode', 'Código de barras', '条码'),
  'kcal100Field': ('Calories (per 100g) *', 'Calorías (por 100g) *', '热量 (每100g) *'),
  'proteinG': ('Protein g', 'Proteína g', '蛋白质 g'),
  'fatG': ('Fat g', 'Grasa g', '脂肪 g'),
  'carbG': ('Carbs g', 'Carbohidratos g', '碳水 g'),
  'per100Note': ('All values are per 100 g', 'Todos los valores son por 100 g', '以上营养值均按每 100 g 填写'),
  'servingDesc': ('Serving description', 'Descripción de porción', '常用份量描述'),
  'servingDescHint': ('e.g. 1 bowl', 'p. ej. 1 tazón', '如 1碗'),
  'servingGrams': ('Serving grams', 'Porción en gramos', '份量克数'),
  'egGrams': ('e.g. 250', 'p. ej. 250', '如 250'),
  'needNameKcal': ('Enter a name and calories per 100g', 'Nombre y calorías por 100g', '请填写食物名称和每100g热量'),
  'pickFood': ('Pick a food', 'Elegir alimento', '选择食物'),
  'searchLibrary': ('Search food library', 'Buscar en la biblioteca', '搜索食物库'),
  'noMatchShort': ('No matching foods', 'Sin coincidencias', '没有匹配的食物'),
  // ---- 通用对话框 ----
  'cancel': ('Cancel', 'Cancelar', '取消'),
  'ok': ('OK', 'Aceptar', '确定'),
  // ---- 设置页 ----
  'secGoals': ('Daily goals', 'Objetivos diarios', '每日目标'),
  'secAppearance': ('Appearance & units', 'Apariencia y unidades', '外观与单位'),
  'secData': ('Data', 'Datos', '数据'),
  'secAbout': ('About', 'Acerca de', '关于'),
  'kcalGoalRow': ('Daily calorie goal', 'Objetivo de calorías', '每日热量目标'),
  'goalUnset': ('Not set · today page shows intake only', 'Sin configurar; solo se muestra la ingesta', '未设置 · 记录页将只显示摄入值'),
  'proteinGoal': ('Protein goal', 'Objetivo de proteína', '蛋白质目标'),
  'fatGoal': ('Fat goal', 'Objetivo de grasa', '脂肪目标'),
  'carbGoal': ('Carbs goal', 'Objetivo de carbohidratos', '碳水目标'),
  'unsetDefault': ('Not set (default {p}% of calories)', 'Sin configurar ({p}% de las calorías por defecto)', '未设置（默认按热量 {p}% 估算）'),
  'estimateByProfile': ('Estimate from profile', 'Estimar con el perfil', '按个人资料估算'),
  'profileSub': ('Height, weight, age → BMR (Mifflin-St Jeor)', 'Estatura, peso, edad → TMB (Mifflin-St Jeor)', '身高体重年龄 → 基础代谢（Mifflin-St Jeor）'),
  'useKj': ('Use kJ for energy', 'Usar kJ', '使用 kJ 显示能量'),
  'useKjSub': ('Off shows kcal', 'Desactivado muestra kcal', '关闭时显示 kcal（千卡）'),
  'appearance': ('Appearance', 'Apariencia', '外观'),
  'system': ('System', 'Sistema', '系统'),
  'light': ('Light', 'Claro', '浅色'),
  'dark': ('Dark', 'Oscuro', '深色'),
  'waterGoal': ('Water goal', 'Objetivo de agua', '饮水目标'),
  'perDay': ('{n} ml / day', '{n} ml / día', '{n} ml / 天'),
  'exportTitle': ('Export backup (JSON)', 'Exportar copia (JSON)', '导出备份（JSON）'),
  'exportSub': ('Foods, entries, goals, weight, water, templates', 'Alimentos, registros, objetivos, peso, agua, combinaciones', '含食物库、记录、目标、体重、饮水、组合餐'),
  'importTitle': ('Import backup (JSON)', 'Importar copia (JSON)', '导入备份（JSON）'),
  'importSub': ('Export → copy to new device → import', 'Exportar → copiar al nuevo equipo → importar', '跨设备迁移：导出文件 → 拷到新设备 → 导入'),
  'storageLoc': ('Data location', 'Ubicación de los datos', '数据存储位置'),
  'appDataDir': ('Local app data directory', 'Directorio local de datos', '本机应用数据目录'),
  'appName': ('Calorie Diary', 'Diario de Calorías', '卡路里日记'),
  'aboutBody': ('All data stays on this device (local SQLite). No account, no cloud, no analytics.\n"OFF online" search uses the Open Food Facts open database (read-only, stores no personal data).\nBuilt-in food values are common estimates and can be edited anytime.', 'Todos los datos se guardan en este equipo (SQLite local). Sin cuenta, sin nube, sin analítica.\nLa búsqueda "OFF en línea" usa la base abierta Open Food Facts (solo lectura, sin datos personales).\nLos alimentos integrados son valores estimados y pueden editarse.', '所有数据仅保存在本设备（本地 SQLite），无账号、无云端、无统计。\n「OFF 在线」搜索使用 Open Food Facts 开放数据库（只读，不存储任何个人数据）。\n内置食物数据为常见估算值，可随时编辑。'),
  'importConfirmTitle': ('Import backup?', '¿Importar la copia?', '导入备份？'),
  'importConfirmBody': ('This overwrites all data on this device (foods, entries, goals, weight, water, templates).', 'Sobrescribe todos los datos de este equipo (alimentos, registros, objetivos, peso, agua, combinaciones).', '将覆盖当前设备上的全部数据（食物库、记录、目标、体重、饮水、组合餐）。'),
  'overwriteImport': ('Overwrite & import', 'Sobrescribir', '覆盖导入'),
  'exportFail': ('Export failed', 'Error al exportar', '导出失败'),
  'importFail': ('Import failed', 'Error al importar', '导入失败'),
  'exportedTo': ('Exported to {p}', 'Exportado a {p}', '已导出到 {p}'),
  'pathCopied': ('(full path copied to clipboard)', '(ruta completa copiada al portapapeles)', '（完整路径已复制到剪贴板）'),
  'importDone': ('Import complete', 'Importación completa', '导入完成'),
  'notBackup': ('Not a backup file of this app', 'No es una copia de esta app', '不是本应用的备份文件'),
  'readFail': ('Failed to read file', 'Error al leer el archivo', '读取文件失败'),
  'profileTitle': ('Profile', 'Perfil', '个人资料'),
  'male': ('Male', 'Hombre', '男'),
  'female': ('Female', 'Mujer', '女'),
  'birthYear': ('Birth year', 'Año de nacimiento', '出生年份'),
  'eg1990': ('e.g. 1990', 'p. ej. 1990', '如 1990'),
  'heightCm': ('Height cm', 'Estatura cm', '身高 cm'),
  'weightKg': ('Weight kg', 'Peso kg', '体重 kg'),
  'activityLevel': ('Activity level', 'Nivel de actividad', '活动水平'),
  'actSedentary': ('Sedentary (little exercise)', 'Sedentario (poco ejercicio)', '久坐（几乎不运动）'),
  'actLight': ('Light (1-3 times/week)', 'Ligero (1-3 veces/semana)', '轻度（每周 1-3 次）'),
  'actModerate': ('Moderate (3-5 times/week)', 'Moderado (3-5 veces/semana)', '中度（每周 3-5 次）'),
  'actHigh': ('High (6+ times/week)', 'Intenso (6+ veces/semana)', '高强度（每周 6+ 次）'),
  'tdeeIs': ('Estimated daily burn: {n} kcal', 'Gasto diario estimado: {n} kcal', '估算每日消耗：{n} kcal'),
  'tdeeHint': ('Enter birth year, height and weight to estimate', 'Introduce los datos para estimar', '填写出生年份、身高、体重后自动估算每日消耗'),
  'applyEstimate': ('Also set as daily goal', 'Usar también como objetivo', '同时将估算值设为每日目标'),
  // ---- 统计页 ----
  'trendTitle': ('Calorie trend', 'Tendencia de calorías', '热量趋势'),
  'statsSub': ('{d} days logged · avg {a} {u} · {s}-day streak', '{d} días registrados · media {a} {u} · racha de {s} días', '记录 {d} 天 · 日均 {a} {u} · 连续记录 {s} 天'),
  'heatTitle': ('Logging heatmap (last 10 weeks)', 'Mapa de registro (últimas 10 semanas)', '记录热力图（最近 10 周）'),
  'heatHint': ('Set a daily goal to see compliance', 'Configura un objetivo diario para ver el cumplimiento', '设置每日目标后可查看达标情况'),
  'macroTitle': ('Macros · 7-day daily average', 'Macronutrientes · media diaria (7 días)', '宏量营养 · 近7天日均'),
  'goal': ('Goal', 'Objetivo', '目标'),
  'weightTitle': ('Weight', 'Peso', '体重'),
  'noWeight': ('No weight records yet', 'Aún sin registros de peso', '还没有体重记录'),
  'vsFirst': ('{d} kg (vs earliest record)', '{d} kg (frente al primer registro)', '{d} kg（对比最早记录）'),
  // ---- 补充 ----
  'clearHint': ('Leave empty to clear', 'Dejar vacío para borrar', '留空清除目标'),
  'quickAddTitle': ('Quick add calories', 'Añadir calorías', '快速添加热量'),
  'quickAddHint': ('Log total calories only, no food attached', 'Solo calorías totales, sin alimento', '只记录总热量，不关联具体食物'),
  'quickAddName': ('Quick add', 'Añadido rápido', '快速添加'),
  'd7': ('7 days', '7 días', '7天'),
  'd30': ('30 days', '30 días', '30天'),
  'weightLogTitle': ('Log weight', 'Registrar peso', '记录体重'),
  'newCustomFood': ('New custom food', 'Nuevo alimento propio', '新建自定义食物'),
  // ---- 今日页交互组件 ----
  'calcRulesTitle': ('How the numbers are calculated', 'Cómo se calculan', '数字是怎么算的'),
  'calcRules': ('Remaining = daily goal − consumed. The goal can be changed in Settings › Goals; consumed is the sum of the four meals, and exercise is not counted. Each food is labeled per 100 g: actual intake = value per 100 g × serving (g) ÷ 100.', 'Restante = objetivo diario − consumido. El objetivo se cambia en Ajustes › Objetivos; lo consumido es la suma de las cuatro comidas; el ejercicio no cuenta. Cada alimento se indica por 100 g: ingesta = valor por 100 g × ración (g) ÷ 100.', '剩余 = 每日目标 − 已摄入，目标可在「设置 › 每日目标」修改，已摄入为四餐之和，运动不计入。每种食物的营养均按每 100 g 标注：实际摄入 = 每 100 g 数值 × 份量（g）÷ 100。'),
  'flipHint': ('Tap to flip', 'Toca para girar', '点按翻转'),
  'mealNow': ('Now', 'Ahora', '当前餐'),
  'emptyMealTip': ('Swipe an entry left to delete it', 'Desliza un registro para borrarlo', '左滑条目可删除'),
  'slideImportLabel': ('Slide to overwrite & import', 'Desliza para sobrescribir', '滑动确认覆盖导入'),
};

/// 取当前语言的文案；支持 {占位符} 替换
String tr(BuildContext context, String key, [Map<String, String>? args]) {
  final lang = LangScope.of(context);
  final rec = kStrings[key];
  var s = rec == null
      ? key
      : switch (lang) {
          AppLang.en => rec.$1,
          AppLang.es => rec.$2,
          AppLang.zh => rec.$3,
        };
  if (args != null) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
  }
  return s;
}

/// 无 context 时（如 async 间隙后）按语言直取，支持 {占位符} 替换
String t(AppLang lang, String key, [Map<String, String>? args]) {
  final rec = kStrings[key];
  var s = rec == null
      ? key
      : switch (lang) {
          AppLang.en => rec.$1,
          AppLang.es => rec.$2,
          AppLang.zh => rec.$3,
        };
  if (args != null) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
  }
  return s;
}

String mealLabel(BuildContext context, MealType m) => switch (m) {
      MealType.breakfast => tr(context, 'mealBreakfast'),
      MealType.lunch => tr(context, 'mealLunch'),
      MealType.dinner => tr(context, 'mealDinner'),
      MealType.snack => tr(context, 'mealSnack'),
    };

const _zhWeekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _esWeekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _esMonths = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// 今日页顶部日期：zh「9月12日 周六」/ en「Sat, Sep 12」/ es「12 sep, sáb」
String formatDateShort(DateTime d, AppLang lang) => switch (lang) {
      AppLang.zh => '${d.month}月${d.day}日 ${_zhWeekdays[d.weekday - 1]}',
      AppLang.en => '${_enWeekdays[d.weekday - 1]}, ${_enMonths[d.month - 1]} ${d.day}',
      AppLang.es => '${d.day} ${_esMonths[d.month - 1]}, ${_esWeekdays[d.weekday - 1]}',
    };
