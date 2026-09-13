import 'package:flutter/material.dart';

/// Apple / iOS 系统风格设计 token —— 完整定义见项目根 DESIGN.md
///
/// 视觉词汇来自 iOS 系统设置与 Apple Health：
/// 分组背景（systemGroupedBackground）、纯白卡片（无边框、10px 圆角）、
/// 系统分隔线、系统色（蓝=交互、粉红=能量、绿/橙/青=三大营养素）、
/// 活动圆环、Cupertino 滑动分段控件与开关。
abstract final class LabelColors {
  // 浅色（iOS System Colors · Light）
  static const paper = Color(0xFFF2F2F7); // systemGroupedBackground
  static const card = Colors.white; // secondarySystemGroupedBackground
  static const ink = Color(0xFF000000); // label
  static const inkSoft = Color(0xFF8E8E93); // secondaryLabel / systemGray
  static const rule = Color(0xFFC6C6C8); // separator（描边、导航栏发丝线）
  static const fill = Color(0xFFE9E9EB); // systemFill（输入框/轨道/侧栏指示）
  // 深色（iOS System Colors · Dark）
  static const dPaper = Color(0xFF000000);
  static const dCard = Color(0xFF1C1C1E);
  static const dInk = Color(0xFFFFFFFF);
  static const dInkSoft = Color(0xFF8D8D93);
  static const dRule = Color(0xFF38383A);
  static const dFill = Color(0xFF2C2C2E);
  // 语义色（light / dark）
  static const blue = Color(0xFF007AFF); // 交互、链接、饮水
  static const blueDark = Color(0xFF0A84FF);
  static const energy = Color(0xFFFF2D55); // 能量 kcal · Apple Health 粉红
  static const energyDark = Color(0xFFFF375F);
  static const protein = Color(0xFF34C759); // 蛋白质 · systemGreen
  static const proteinDark = Color(0xFF30D158);
  static const fat = Color(0xFFFF9500); // 脂肪 · systemOrange
  static const fatDark = Color(0xFFFF9F0A);
  static const carb = Color(0xFF30B0C7); // 碳水 · systemTeal
  static const carbDark = Color(0xFF40C8E0);
  static const weight = Color(0xFFAF52DE); // 体重 · systemPurple
  static const weightDark = Color(0xFFBF5AF2);
  static const error = Color(0xFFFF3B30); // 破坏性操作 / 超标
  static const errorDark = Color(0xFFFF453A);

  static Color blueOf(bool dark) => dark ? blueDark : blue;
  static Color energyOf(bool dark) => dark ? energyDark : energy;
  static Color proteinOf(bool dark) => dark ? proteinDark : protein;
  static Color fatOf(bool dark) => dark ? fatDark : fat;
  static Color carbOf(bool dark) => dark ? carbDark : carb;
  static Color weightOf(bool dark) => dark ? weightDark : weight;
  static Color errorOf(bool dark) => dark ? errorDark : error;
  static Color inkOf(bool dark) => dark ? dInk : ink;
  static Color inkSoftOf(bool dark) => dark ? dInkSoft : inkSoft;
  static Color ruleOf(bool dark) => dark ? dRule : rule;
  static Color fillOf(bool dark) => dark ? dFill : fill;
}

/// 数据主角：大号数字（能量、克数、体重等一切读数）
TextStyle numberStyle(double size, Color color, {FontWeight? weight}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );

/// iOS 分组列表小节标题（13px 常规、次要色）
TextStyle captionStyle(BuildContext context) => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

ThemeData _theme({required bool dark}) {
  final paper = dark ? LabelColors.dPaper : LabelColors.paper;
  final card = dark ? LabelColors.dCard : LabelColors.card;
  final fill = dark ? LabelColors.dFill : LabelColors.fill;
  final ink = dark ? LabelColors.dInk : LabelColors.ink;
  final soft = dark ? LabelColors.dInkSoft : LabelColors.inkSoft;
  final blue = LabelColors.blueOf(dark);
  // 卡片内部的 iOS 细分隔线比全局 separator 更浅
  final cellSep = dark ? LabelColors.dRule : const Color(0xFFE2E2E7);
  final scheme = ColorScheme.fromSeed(
    seedColor: blue,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: blue,
    onPrimary: Colors.white,
    secondary: LabelColors.energyOf(dark),
    onSecondary: Colors.white,
    tertiary: LabelColors.carbOf(dark),
    surface: card,
    onSurface: ink,
    surfaceContainerLowest: card,
    surfaceContainerLow: card,
    surfaceContainer: card,
    surfaceContainerHigh: card,
    surfaceContainerHighest: fill,
    error: LabelColors.errorOf(dark),
    onError: Colors.white,
  );

  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(100));
  final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  final fieldRadius = BorderRadius.circular(10);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: paper,
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
      shadowColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: cellSep, thickness: 0.5, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: ink,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      shape: pill,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        shape: pill,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: blue,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    // iOS 的「灰色调按钮」：填充而非描边
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: ink,
        side: BorderSide.none,
        shape: pill,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fill,
      isDense: true,
      border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: blue, width: 1.5),
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: soft),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? blue : soft,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: states.contains(WidgetState.selected) ? blue : soft,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: paper,
      indicatorColor: fill,
      selectedIconTheme: IconThemeData(color: ink),
      unselectedIconTheme: IconThemeData(color: soft),
      selectedLabelTextStyle: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: soft, fontSize: 12),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: blue,
      unselectedLabelColor: soft,
      indicatorColor: blue,
      dividerColor: cellSep,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: fill,
      selectedColor: blue.withValues(alpha: dark ? 0.32 : 0.15),
      checkmarkColor: blue,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(fontSize: 13, color: ink),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? LabelColors.dFill : LabelColors.dCard,
      contentTextStyle: TextStyle(color: dark ? LabelColors.dInk : Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ink),
      contentTextStyle: TextStyle(fontSize: 14, color: ink),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(fontSize: 14, color: ink),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: blue,
      linearTrackColor: fill,
      borderRadius: BorderRadius.circular(100),
    ),
  );
}

ThemeData buildLightTheme() => _theme(dark: false);

ThemeData buildDarkTheme() => _theme(dark: true);
