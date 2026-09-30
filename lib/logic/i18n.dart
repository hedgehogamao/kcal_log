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
  'validNumberRange': (
    'Enter a finite number above 0 and at most {max} {unit}.',
    'Introduce un número finito mayor que 0 y hasta {max} {unit}.',
    '请输入大于 0 且不超过 {max} {unit} 的有限数值。',
  ),
  'clearGoal': ('Clear goal', 'Borrar objetivo', '清除目标'),
  'validNumberBounds': (
    'Enter a finite number from {min} to {max} {unit}.',
    'Introduce un número finito de {min} a {max} {unit}.',
    '请输入 {min} 到 {max} {unit} 之间的有限数值。',
  ),
  'acknowledgeImport': ('Confirm overwrite', 'Confirmar', '确认覆盖'),
  'applyEstimateShort': ('Apply', 'Aplicar', '应用'),
  'goalSaved': ('Goal saved', 'Objetivo guardado', '目标已保存'),
  'goalsHelp': (
    'Set your daily targets. Leaving a goal empty clears it.',
    'Configura tus objetivos diarios. Dejar uno vacío lo borra.',
    '设定每天的目标；留空保存或点“清除目标”即可取消该目标。',
  ),
  'backupHelp': (
    'Export before switching devices. Import replaces this device’s data.',
    'Exporta antes de cambiar de equipo. Importar reemplaza los datos locales.',
    '换设备前先导出备份；导入会覆盖本机数据。',
  ),
  'backupCounts': (
    '{foods} foods · {entries} entries',
    '{foods} alimentos · {entries} registros',
    '{foods} 条食物 · {entries} 条记录',
  ),
  'importAcknowledge': (
    'I understand this replaces all current data.',
    'Entiendo que reemplazará todos los datos actuales.',
    '我理解这会覆盖当前全部数据。',
  ),
  'working': ('Working…', 'Procesando…', '正在处理…'),
  'copyPath': ('Copy path', 'Copiar ruta', '复制路径'),
  'invalidWater': (
    'Enter a water goal of at least 1 ml.',
    'Introduce al menos 1 ml.',
    '饮水目标至少为 1 ml。',
  ),
  'sexLabel': ('Sex used for estimate', 'Sexo para la estimación', '估算所用性别'),
  'chooseSex': ('Choose', 'Seleccionar', '请选择'),
  'invalidYear': (
    'Use a birth year corresponding to age 10–100.',
    'Usa un año de nacimiento para una edad de 10–100.',
    '出生年份需对应 10–100 岁。',
  ),
  'profileEditHelp': (
    'Fields are optional. Saving a weight also updates today’s weight record.',
    'Los campos son opcionales. Guardar el peso actualiza el registro de hoy.',
    '资料可选填；保存体重时会同步今天的体重记录。',
  ),
  'estimateValue': (
    'Estimated daily burn: {value}',
    'Gasto diario estimado: {value}',
    '估算每日消耗：{value}',
  ),
  'estimateHint': (
    'Your goals stay unchanged until you apply this estimate.',
    'Tus objetivos no cambian hasta aplicar esta estimación.',
    '不应用估算，就会保留现有目标。',
  ),
  'applyEstimateGoals': (
    'Replace calorie and macro goals with this estimate',
    'Reemplazar objetivos de calorías y macros con esta estimación',
    '用估算值覆盖热量与三大营养目标',
  ),
  'actSedentaryShort': ('Sedentary', 'Sedentario', '久坐'),
  'actLightShort': ('Light', 'Ligera', '轻度'),
  'actModerateShort': ('Moderate', 'Moderada', '中度'),
  'actHighShort': ('High', 'Intensa', '高强度'),
  // ---- 导航 ----
  'previousDay': ('Previous day', 'Día anterior', '前一天'),
  'nextDay': ('Next day', 'Día siguiente', '后一天'),
  'backToToday': ('Back to today', 'Volver a hoy', '回到今天'),
  'logFood': ('Log food', 'Registrar alimento', '记录食物'),
  'dailyEnergyGoal': (
    'Daily goal: {value}',
    'Objetivo diario: {value}',
    '每日目标：{value}',
  ),
  'calcHelp': ('Calculation details', 'Detalles del cálculo', '计算说明'),
  'close': ('Close', 'Cerrar', '关闭'),
  'emptyMealAction': (
    'Tap + to record this meal',
    'Toca + para registrar esta comida',
    '点 + 记录这一餐',
  ),
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
  'setGoalCta': (
    'Set daily calorie goal',
    'Configurar objetivo diario',
    '去设置每日热量目标',
  ),
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
  'more': (
    'More · red = over goal',
    'Más · rojo = sobre el objetivo',
    '多 · 红色为超过目标',
  ),
  // ---- 记录弹层 ----
  'entryDate': (
    'Record date: {date}',
    'Fecha del registro: {date}',
    '记录日期：{date}',
  ),
  'mealField': ('Meal', 'Comida', '餐次'),
  'entryPreview': ('This entry', 'Este registro', '本次记录'),
  'addEntry': ('Add entry', 'Añadir registro', '确认记录'),
  'saving': ('Saving…', 'Guardando…', '正在保存…'),
  'afterConsumed': (
    'Consumed after entry',
    'Consumido tras registrar',
    '记录后已摄入',
  ),
  'afterRemaining': (
    'Remaining after entry',
    'Restante tras registrar',
    '记录后还可摄入',
  ),
  'afterOver': ('Over goal after entry', 'Exceso tras registrar', '记录后超出目标'),
  'needPositiveEnergy': (
    'Enter a positive energy amount',
    'Introduce una energía positiva',
    '请输入大于 0 的热量',
  ),
  'needPositiveGrams': (
    'Enter a positive serving in grams',
    'Introduce una porción positiva en gramos',
    '请输入大于 0 的份量（克）',
  ),
  'entry': ('Entry', 'Registro', '记录'),
  'kcalField': ('Calories', 'Calorías', '热量'),
  'quickAddNote': (
    'Quick add: log calories only, no food attached',
    'Añadir rápido: solo calorías, sin alimento',
    '快速添加：只记录热量，不关联具体食物',
  ),
  'servingField': ('Serving', 'Porción', '份量'),
  'gramUnit': ('g', 'g', '克'),
  'previewHint': (
    'Enter grams to auto-calculate',
    'Introduce los gramos para calcular',
    '输入份量后自动计算热量',
  ),
  'previewMacro': (
    'Protein {p} · Fat {f} · Carbs {c} g',
    'Proteína {p} · Grasa {f} · Carbohidratos {c} g',
    '蛋白质 {p} · 脂肪 {f} · 碳水 {c} g',
  ),
  'saveEdit': ('Save changes', 'Guardar cambios', '保存修改'),
  'needKcal': ('Please enter calories', 'Introduce las calorías', '请输入热量'),
  'needGrams': (
    'Please enter serving (grams)',
    'Introduce la porción (gramos)',
    '请输入份量（克）',
  ),
  'cantCompute': (
    'Cannot calculate nutrition',
    'No se puede calcular la nutrición',
    '无法计算营养值',
  ),
  // ---- 添加流 / 食物选择 ----
  'addTo': ('Add to {meal}', 'Añadir a {meal}', '添加到{meal}'),
  'searchFoods': ('Search foods', 'Buscar alimentos', '搜索食物'),
  'clearSearch': ('Clear search', 'Borrar búsqueda', '清除搜索'),
  'foodResults': ('{n} foods', '{n} alimentos', '{n} 种食物'),
  'myFoods': ('My foods', 'Mis alimentos', '我的食物'),
  'caloriesOnly': ('Calories only', 'Solo calorías', '仅热量'),
  'moreActions': ('More actions', 'Más acciones', '更多操作'),
  'onlineMinQuery': (
    'Enter at least 2 characters for online search',
    'Escribe al menos 2 caracteres para buscar en línea',
    '输入至少 2 个字符后搜索在线食物',
  ),
  'barcodeInUse': (
    'This barcode is already used by another food',
    'Este código de barras ya pertenece a otro alimento',
    '这个条码已被其他食物使用',
  ),
  'invalidNutrition': (
    'Nutrition values must be non-negative numbers',
    'Los nutrientes deben ser números no negativos',
    '营养值必须是非负数字',
  ),
  'invalidServing': (
    'Serving grams must be a positive number',
    'Los gramos por porción deben ser un número positivo',
    '每份克数必须是正数',
  ),
  'searchOnlineSuffix': (
    ' (also searching Open Food Facts)',
    ' (también en Open Food Facts)',
    '（同时搜索 Open Food Facts）',
  ),
  'all': ('All', 'Todos', '全部'),
  'recent': ('Recent', 'Recientes', '最近'),
  'fav': ('Favorites', 'Favoritos', '收藏'),
  'offOnline': ('OFF online', 'OFF en línea', 'OFF 在线'),
  'onlineUncategorized': (
    'Online results have no food category',
    'Los resultados en línea no tienen categoría',
    '在线结果未分类',
  ),
  'quickAdd': ('Quick add', 'Añadir rápido', '快速添加'),
  'barcode': ('Barcode', 'Código', '条码'),
  'customFood': ('Custom food', 'Alimento propio', '自定义食物'),
  'noFavs': ('No favorite foods yet', 'Aún no hay favoritos', '还没有收藏的食物'),
  'noMatch': (
    'No matching foods — try "Custom food"',
    'Sin resultados; prueba "Alimento propio"',
    '没有匹配的食物，试试「自定义食物」',
  ),
  'noRecent': (
    'No records yet — add a meal first',
    'Aún sin registros; añade una comida',
    '还没有记录，先去添加一餐吧',
  ),
  'offSection': (
    'Open Food Facts (online results)',
    'Open Food Facts (resultados en línea)',
    'Open Food Facts（在线结果）',
  ),
  'onlineFail': (
    'Online search failed (offline use unaffected)',
    'Error de búsqueda en línea (el uso sin conexión no se afecta)',
    '在线搜索失败（不影响离线使用）',
  ),
  'noOnlineResults': ('No online results', 'Sin resultados en línea', '没有在线结果'),
  'per100g': ('per 100g', 'por 100g', '每100g'),
  'barcodeTitle': ('Barcode lookup', 'Consultar código', '条码查询'),
  'barcodeHint': (
    'Enter product barcode',
    'Introduce el código de barras',
    '输入商品条码',
  ),
  'search': ('Search', 'Buscar', '查询'),
  'searching': ('Searching…', 'Buscando…', '正在查询…'),
  'notFound': (
    'No product found for this barcode',
    'Sin resultados para este código',
    '未找到该条码的商品',
  ),
  'templateAdded': (
    'Added {n} items from "{t}" to {meal}',
    'Añadidos {n} elem. de «{t}» a {meal}',
    '已从「{t}」添加 {n} 项到{meal}',
  ),
  'saveFail': ('Save failed', 'Error al guardar', '保存失败'),
  'logged': ('Logged {n} kcal', 'Registradas {n} kcal', '已记录 {n} kcal'),
  'sourceBuiltin': ('Built-in', 'Integrado', '内置'),
  'sourceCustom': ('Custom', 'Propio', '自定义'),
  'foodCategory': ('Category', 'Categoría', '食物分类'),
  'clearCategory': ('Clear category', 'Borrar categoría', '清除分类'),
  'allCategories': ('All categories', 'Todas las categorías', '全部分类'),
  'clearFilters': (
    'Clear search & filters',
    'Borrar búsqueda y filtros',
    '清除搜索与筛选',
  ),
  'categoryStaple': ('Grains & starches', 'Cereales y féculas', '主食'),
  'categoryProtein': ('Protein', 'Proteínas', '蛋白类'),
  'categoryVegetable': ('Vegetables', 'Verduras', '蔬菜'),
  'categoryFruit': ('Fruit', 'Frutas', '水果'),
  'categoryDairy': ('Dairy', 'Lácteos', '乳制品'),
  'categorySnack': ('Snacks & nuts', 'Aperitivos y frutos secos', '零食坚果'),
  'categoryDrink': ('Drinks', 'Bebidas', '饮品'),
  'categoryDish': ('Prepared dishes', 'Platos preparados', '菜肴外食'),
  'categoryOther': ('Other', 'Otros', '其他'),
  // ---- 食物库页 ----
  'foods': ('Foods', 'Alimentos', '食物'),
  'templates': ('Templates', 'Combinaciones', '组合餐'),
  'searchName': (
    'Search food, brand, barcode or category',
    'Buscar alimento, marca, código o categoría',
    '搜索食物、品牌、条码或分类',
  ),
  'noFoods': (
    'No foods yet — tap + to create',
    'Sin alimentos; toca + para crear',
    '没有食物，点右上角 + 新建',
  ),
  'favAdd': ('Add to favorites', 'Añadir a favoritos', '收藏'),
  'favRemove': ('Remove from favorites', 'Quitar de favoritos', '取消收藏'),
  'edit': ('Edit', 'Editar', '编辑'),
  'delete': ('Delete', 'Eliminar', '删除'),
  'delFoodTitle': ('Delete "{name}"?', '¿Eliminar «{name}»?', '删除「{name}」？'),
  'delFoodBody': (
    'Existing entries keep their nutrition snapshot, but template items referencing this food are removed.',
    'Los registros existentes conservan sus datos; se quita el alimento de las comidas guardadas.',
    '已有饮食记录会保留（营养快照不受影响），但组合餐中引用该食物的条目会被移除。',
  ),
  'templateHint': (
    'Save a meal you often eat as a template and log it all at once',
    'Guarda una comida habitual como plantilla y regístrala de una vez',
    '把常吃的一餐（如早餐套餐）存成组合，添加时一次记录全部',
  ),
  'newTemplate': ('New meal template', 'Nueva combinación', '新建组合餐'),
  'noTemplates': (
    'No templates yet — tap "New meal template"',
    'Sin combinaciones; toca "Nueva combinación"',
    '还没有组合餐，点「新建组合餐」创建',
  ),
  'tapToEdit': ('Tap to view & edit', 'Toca para ver y editar', '点击查看与编辑'),
  'delTplTitle': (
    'Delete template "{name}"?',
    '¿Eliminar la combinación «{name}»?',
    '删除组合餐「{name}」？',
  ),
  'delTplBody': (
    'Only the template is deleted; logged entries are kept.',
    'Solo se borra la definición; los registros se conservan.',
    '只删除组合定义，不会删除已记录的饮食条目。',
  ),
  'editTplTitle': ('Edit meal template', 'Editar combinación', '编辑组合餐'),
  'nameField': ('Name *', 'Nombre *', '名称 *'),
  'nameHint': ('e.g. Breakfast set', 'p. ej. Desayuno completo', '如：早餐套餐'),
  'tplSummary': (
    '{n} items · ~{k} kcal',
    '{n} elem. · ~{k} kcal',
    '共 {n} 项 · 约 {k} kcal',
  ),
  'tplEmpty': (
    'No foods yet — tap "Add food" below',
    'Sin alimentos; toca "Añadir alimento" abajo',
    '还没有食物，点下方「添加食物」',
  ),
  'addFood': ('Add food', 'Añadir alimento', '添加食物'),
  'templateSummaryUnit': (
    '{n} foods · {energy}',
    '{n} alimentos · {energy}',
    '{n} 项食物 · {energy}',
  ),
  'templateSaveNote': (
    'Save for later. No entries are logged yet.',
    'Guardar para después. Aún no se registra la comida.',
    '保存为常用组合餐，不会立即记入饮食记录。',
  ),
  'templateGrams': ('Amount (g)', 'Cantidad (g)', '份量（克）'),
  'templateLess': ('50 g less', 'Reducir 50 g', '减少 50 克'),
  'templateMore': ('50 g more', 'Añadir 50 g', '增加 50 克'),
  'templateRemove': ('Remove {name}', 'Quitar {name}', '移除{name}'),
  'templateGramsRange': (
    'Enter more than 0, up to 100000 g',
    'Introduce más de 0 y hasta 100000 g',
    '请输入大于 0、至多 100000 克',
  ),
  'templateLoadFail': (
    'Could not load this meal. Try again.',
    'No se pudo cargar. Vuelve a intentarlo.',
    '组合餐加载失败，请重试。',
  ),
  'retry': ('Retry', 'Reintentar', '重试'),
  'foodResultCount': ('{n} foods', '{n} alimentos', '{n} 项食物'),
  'templateReview': ('Review meal', 'Revisar comida', '确认组合餐'),
  'templateLog': ('Log meal', 'Registrar comida', '记录组合餐'),
  'needNameItems': (
    'Enter a name and at least one food',
    'Nombre y al menos un alimento',
    '请填写名称并至少添加一项食物',
  ),
  'invalidGrams': (
    'Invalid grams for "{name}"',
    'Gramos no válidos para «{name}»',
    '「{name}」的克数无效',
  ),
  'save': ('Save', 'Guardar', '保存'),
  // ---- 食物表单 ----
  'editFood': ('Edit food', 'Editar alimento', '编辑食物'),
  'brand': ('Brand', 'Marca', '品牌'),
  'barcodeField': ('Barcode', 'Código de barras', '条码'),
  'kcal100Field': (
    'Calories (per 100g) *',
    'Calorías (por 100g) *',
    '热量 (每100g) *',
  ),
  'proteinG': ('Protein g', 'Proteína g', '蛋白质 g'),
  'fatG': ('Fat g', 'Grasa g', '脂肪 g'),
  'carbG': ('Carbs g', 'Carbohidratos g', '碳水 g'),
  'per100Note': (
    'All values are per 100 g',
    'Todos los valores son por 100 g',
    '以上营养值均按每 100 g 填写',
  ),
  'servingDesc': ('Serving description', 'Descripción de porción', '常用份量描述'),
  'servingDescHint': ('e.g. 1 bowl', 'p. ej. 1 tazón', '如 1碗'),
  'servingGrams': ('Serving grams', 'Porción en gramos', '份量克数'),
  'egGrams': ('e.g. 250', 'p. ej. 250', '如 250'),
  'needNameKcal': (
    'Enter a name and calories per 100g',
    'Nombre y calorías por 100g',
    '请填写食物名称和每100g热量',
  ),
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
  'goalUnset': (
    'Not set · today page shows intake only',
    'Sin configurar; solo se muestra la ingesta',
    '未设置 · 记录页将只显示摄入值',
  ),
  'proteinGoal': ('Protein goal', 'Objetivo de proteína', '蛋白质目标'),
  'fatGoal': ('Fat goal', 'Objetivo de grasa', '脂肪目标'),
  'carbGoal': ('Carbs goal', 'Objetivo de carbohidratos', '碳水目标'),
  'unsetDefault': (
    'Not set (default {p}% of calories)',
    'Sin configurar ({p}% de las calorías por defecto)',
    '未设置（默认按热量 {p}% 估算）',
  ),
  'estimateByProfile': (
    'Estimate from profile',
    'Estimar con el perfil',
    '按个人资料估算',
  ),
  'profileSub': (
    'Height, weight, age → BMR (Mifflin-St Jeor)',
    'Estatura, peso, edad → TMB (Mifflin-St Jeor)',
    '身高体重年龄 → 基础代谢（Mifflin-St Jeor）',
  ),
  'useKj': ('Use kJ for energy', 'Usar kJ', '使用 kJ 显示能量'),
  'useKjSub': ('Off shows kcal', 'Desactivado muestra kcal', '关闭时显示 kcal（千卡）'),
  'appearance': ('Appearance', 'Apariencia', '外观'),
  'system': ('System', 'Sistema', '系统'),
  'light': ('Light', 'Claro', '浅色'),
  'dark': ('Dark', 'Oscuro', '深色'),
  'waterGoal': ('Water goal', 'Objetivo de agua', '饮水目标'),
  'perDay': ('{n} ml / day', '{n} ml / día', '{n} ml / 天'),
  'exportTitle': (
    'Export backup (JSON)',
    'Exportar copia (JSON)',
    '导出备份（JSON）',
  ),
  'exportSub': (
    'Foods, entries, goals, weight, water, templates',
    'Alimentos, registros, objetivos, peso, agua, combinaciones',
    '含食物库、记录、目标、体重、饮水、组合餐',
  ),
  'importTitle': (
    'Import backup (JSON)',
    'Importar copia (JSON)',
    '导入备份（JSON）',
  ),
  'importSub': (
    'Export → copy to new device → import',
    'Exportar → copiar al nuevo equipo → importar',
    '跨设备迁移：导出文件 → 拷到新设备 → 导入',
  ),
  'storageLoc': ('Data location', 'Ubicación de los datos', '数据存储位置'),
  'appDataDir': (
    'Local app data directory',
    'Directorio local de datos',
    '本机应用数据目录',
  ),
  'appName': ('Calorie Diary', 'Diario de Calorías', '卡路里日记'),
  'aboutBody': (
    'All data stays on this device (local SQLite). No account, no cloud, no analytics.\n"OFF online" search uses the Open Food Facts open database (read-only, stores no personal data).\nBuilt-in food values are common estimates and can be edited anytime.',
    'Todos los datos se guardan en este equipo (SQLite local). Sin cuenta, sin nube, sin analítica.\nLa búsqueda "OFF en línea" usa la base abierta Open Food Facts (solo lectura, sin datos personales).\nLos alimentos integrados son valores estimados y pueden editarse.',
    '所有数据仅保存在本设备（本地 SQLite），无账号、无云端、无统计。\n「OFF 在线」搜索使用 Open Food Facts 开放数据库（只读，不存储任何个人数据）。\n内置食物数据为常见估算值，可随时编辑。',
  ),
  'importConfirmTitle': ('Import backup?', '¿Importar la copia?', '导入备份？'),
  'importConfirmBody': (
    'This overwrites all data on this device (foods, entries, goals, weight, water, templates).',
    'Sobrescribe todos los datos de este equipo (alimentos, registros, objetivos, peso, agua, combinaciones).',
    '将覆盖当前设备上的全部数据（食物库、记录、目标、体重、饮水、组合餐）。',
  ),
  'overwriteImport': ('Overwrite & import', 'Sobrescribir', '覆盖导入'),
  'exportFail': ('Export failed', 'Error al exportar', '导出失败'),
  'importFail': ('Import failed', 'Error al importar', '导入失败'),
  'exportedTo': ('Exported to {p}', 'Exportado a {p}', '已导出到 {p}'),
  'pathCopied': (
    '(full path copied to clipboard)',
    '(ruta completa copiada al portapapeles)',
    '（完整路径已复制到剪贴板）',
  ),
  'importDone': ('Import complete', 'Importación completa', '导入完成'),
  'notBackup': (
    'Not a backup file of this app',
    'No es una copia de esta app',
    '不是本应用的备份文件',
  ),
  'readFail': ('Failed to read file', 'Error al leer el archivo', '读取文件失败'),
  'profileTitle': ('Profile', 'Perfil', '个人资料'),
  'male': ('Male', 'Hombre', '男'),
  'female': ('Female', 'Mujer', '女'),
  'birthYear': ('Birth year', 'Año de nacimiento', '出生年份'),
  'eg1990': ('e.g. 1990', 'p. ej. 1990', '如 1990'),
  'heightCm': ('Height cm', 'Estatura cm', '身高 cm'),
  'weightKg': ('Weight kg', 'Peso kg', '体重 kg'),
  'activityLevel': ('Activity level', 'Nivel de actividad', '活动水平'),
  'actSedentary': (
    'Sedentary (little exercise)',
    'Sedentario (poco ejercicio)',
    '久坐（几乎不运动）',
  ),
  'actLight': (
    'Light (1-3 times/week)',
    'Ligero (1-3 veces/semana)',
    '轻度（每周 1-3 次）',
  ),
  'actModerate': (
    'Moderate (3-5 times/week)',
    'Moderado (3-5 veces/semana)',
    '中度（每周 3-5 次）',
  ),
  'actHigh': (
    'High (6+ times/week)',
    'Intenso (6+ veces/semana)',
    '高强度（每周 6+ 次）',
  ),
  'tdeeIs': (
    'Estimated daily burn: {n} kcal',
    'Gasto diario estimado: {n} kcal',
    '估算每日消耗：{n} kcal',
  ),
  'tdeeHint': (
    'Choose sex and enter birth year, height and weight to estimate',
    'Selecciona sexo y completa año, estatura y peso para estimar',
    '选择性别并填写出生年份、身高和体重后，显示估算每日消耗',
  ),
  'applyEstimate': (
    'Also set as daily goal',
    'Usar también como objetivo',
    '同时将估算值设为每日目标',
  ),
  // ---- 统计页 ----
  'trendTitle': ('Calorie trend', 'Tendencia de calorías', '热量趋势'),
  'loggedDayAverage': (
    'Average on logged days',
    'Media de días registrados',
    '有记录日均热量',
  ),
  'recordedDays': ('Days logged', 'Días registrados', '记录天数'),
  'loggingStreak': ('Logging streak', 'Racha de registro', '连续记录'),
  'dayCount': ('{n} days', '{n} días', '{n} 天'),
  'missingDaysNote': (
    '{n} days not logged. Missing is not zero intake.',
    '{n} días sin registrar. Sin registro no significa consumo cero.',
    '{n} 天未记录；未记录不代表摄入 0 热量。',
  ),
  'noTrendYet': (
    'Log a meal to start your trend.',
    'Registra una comida para ver la tendencia.',
    '记录一餐后，这里会显示热量趋势。',
  ),
  'chartUnit': (
    'Chart unit: {unit}',
    'Unidad del gráfico: {unit}',
    '图表单位：{unit}',
  ),
  'dailyDetails': ('Daily details', 'Detalle diario', '查看每日明细'),
  'notLogged': ('Not logged', 'Sin registro', '未记录'),
  'macroAverageNote': (
    'Average across {n} logged days in the last 7 days.',
    'Media de {n} días registrados en los últimos 7 días.',
    '按近 7 天中有记录的 {n} 天计算日均。',
  ),
  'noMacroYet': (
    'No nutrition records in the last 7 days.',
    'Sin registros de nutrientes en los últimos 7 días.',
    '近 7 天还没有营养记录。',
  ),
  'weightAllRecords': (
    'Latest 90 weight records, independent of the calorie range.',
    'Los últimos 90 registros de peso, sin limitar al intervalo de calorías.',
    '最近 90 条体重记录，不受热量区间切换影响。',
  ),
  'weightComparison': (
    '{d} kg vs first record shown ({date})',
    '{d} kg frente al primer registro mostrado ({date})',
    '{d} kg（对比图中最早记录 {date}）',
  ),
  'invalidWeight': (
    'Enter a weight greater than 0 and no more than 500 kg.',
    'Introduce un peso mayor que 0 y de hasta 500 kg.',
    '请输入大于 0 且不超过 500 kg 的体重。',
  ),
  'goalPercent': (
    '{n}% of daily goal',
    '{n}% del objetivo diario',
    '每日目标的 {n}%',
  ),
  'statsSub': (
    '{d} days logged · avg {a} {u} · {s}-day streak',
    '{d} días registrados · media {a} {u} · racha de {s} días',
    '记录 {d} 天 · 日均 {a} {u} · 连续记录 {s} 天',
  ),
  'heatTitle': (
    'Logging heatmap (last 10 weeks)',
    'Mapa de registro (últimas 10 semanas)',
    '记录热力图（最近 10 周）',
  ),
  'heatHint': (
    'Set a daily goal to see compliance',
    'Configura un objetivo diario para ver el cumplimiento',
    '设置每日目标后可查看达标情况',
  ),
  'macroTitle': (
    'Macros · 7-day daily average',
    'Macronutrientes · media diaria (7 días)',
    '宏量营养 · 近7天日均',
  ),
  'goal': ('Goal', 'Objetivo', '目标'),
  'weightTitle': ('Weight', 'Peso', '体重'),
  'noWeight': ('No weight records yet', 'Aún sin registros de peso', '还没有体重记录'),
  'vsFirst': (
    '{d} kg (vs earliest record)',
    '{d} kg (frente al primer registro)',
    '{d} kg（对比最早记录）',
  ),
  // ---- 补充 ----
  'clearHint': ('Leave empty to clear', 'Dejar vacío para borrar', '留空清除目标'),
  'quickAddTitle': ('Quick add calories', 'Añadir calorías', '快速添加热量'),
  'quickAddHint': (
    'Log total calories only, no food attached',
    'Solo calorías totales, sin alimento',
    '只记录总热量，不关联具体食物',
  ),
  'quickAddName': ('Quick add', 'Añadido rápido', '快速添加'),
  'd7': ('7 days', '7 días', '7天'),
  'd30': ('30 days', '30 días', '30天'),
  'weightLogTitle': ('Log weight', 'Registrar peso', '记录体重'),
  'newCustomFood': ('New custom food', 'Nuevo alimento propio', '新建自定义食物'),
  // ---- 今日页交互组件 ----
  'calcRulesTitle': (
    'How the numbers are calculated',
    'Cómo se calculan',
    '数字是怎么算的',
  ),
  'calcRules': (
    'Remaining = daily goal − consumed. The goal can be changed in Settings › Goals; consumed is the sum of the four meals, and exercise is not counted. Each food is labeled per 100 g: actual intake = value per 100 g × serving (g) ÷ 100.',
    'Restante = objetivo diario − consumido. El objetivo se cambia en Ajustes › Objetivos; lo consumido es la suma de las cuatro comidas; el ejercicio no cuenta. Cada alimento se indica por 100 g: ingesta = valor por 100 g × ración (g) ÷ 100.',
    '剩余 = 每日目标 − 已摄入，目标可在「设置 › 每日目标」修改，已摄入为四餐之和，运动不计入。每种食物的营养均按每 100 g 标注：实际摄入 = 每 100 g 数值 × 份量（g）÷ 100。',
  ),
  'flipHint': ('Tap to flip', 'Toca para girar', '点按翻转'),
  'mealNow': ('Now', 'Ahora', '当前餐'),
  'emptyMealTip': (
    'Swipe an entry left to delete it',
    'Desliza un registro para borrarlo',
    '左滑条目可删除',
  ),
  'slideImportLabel': (
    'Slide to overwrite & import',
    'Desliza para sobrescribir',
    '滑动确认覆盖导入',
  ),
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
const _enMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _esMonths = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// 今日页顶部日期：zh「9月12日 周六」/ en「Sat, Sep 12」/ es「12 sep, sáb」
String formatDateShort(DateTime d, AppLang lang) => switch (lang) {
  AppLang.zh => '${d.month}月${d.day}日 ${_zhWeekdays[d.weekday - 1]}',
  AppLang.en =>
    '${_enWeekdays[d.weekday - 1]}, ${_enMonths[d.month - 1]} ${d.day}',
  AppLang.es =>
    '${d.day} ${_esMonths[d.month - 1]}, ${_esWeekdays[d.weekday - 1]}',
};
