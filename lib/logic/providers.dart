import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import '../data/seed_data.dart';
import 'i18n.dart';

/// 在 main 中用 overrideWithValue 注入
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('必须在 main 中 override'),
);

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  seedIfEmpty(db); // 首次启动写入种子食物（异步，不阻塞）
  return db;
});

class AppSettings {
  const AppSettings({
    this.useKj = false,
    this.themeMode = ThemeMode.system,
    this.waterGoalMl = 2000,
    this.lang = AppLang.zh,
  });
  final bool useKj;
  final ThemeMode themeMode;
  final int waterGoalMl;
  final AppLang lang;

  AppSettings copyWith({
    bool? useKj,
    ThemeMode? themeMode,
    int? waterGoalMl,
    AppLang? lang,
  }) =>
      AppSettings(
        useKj: useKj ?? this.useKj,
        themeMode: themeMode ?? this.themeMode,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        lang: lang ?? this.lang,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    return AppSettings(
      useKj: p.getBool('useKj') ?? false,
      themeMode: ThemeMode.values[p.getInt('themeMode') ?? 0],
      waterGoalMl: p.getInt('waterGoalMl') ?? 2000,
      lang: appLangByCode(p.getString('lang')) ?? AppLang.zh,
    );
  }

  SharedPreferences get _prefs => ref.read(prefsProvider);

  void setUseKj(bool v) {
    _prefs.setBool('useKj', v);
    state = state.copyWith(useKj: v);
  }

  void setThemeMode(ThemeMode v) {
    _prefs.setInt('themeMode', v.index);
    state = state.copyWith(themeMode: v);
  }

  void setWaterGoal(int ml) {
    _prefs.setInt('waterGoalMl', ml);
    state = state.copyWith(waterGoalMl: ml);
  }

  void setLang(AppLang v) {
    _prefs.setString('lang', v.code);
    state = state.copyWith(lang: v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final profileProvider = StreamProvider<Profile?>(
  (ref) => ref.watch(dbProvider).watchProfile(),
);

/// 某一天的饮食记录
final entriesProvider = StreamProvider.family<List<FoodEntry>, String>(
  (ref, date) => ref.watch(dbProvider).watchEntries(date),
);

/// [from, to] 闭区间内的记录（用于统计）
final entriesRangeProvider =
    StreamProvider.family<List<FoodEntry>, (String, String)>(
  (ref, range) => ref.watch(dbProvider).watchEntriesBetween(range.$1, range.$2),
);

final waterProvider = StreamProvider.family<WaterRec?, String>(
  (ref, date) => ref.watch(dbProvider).watchWater(date),
);

final weightsProvider = StreamProvider<List<WeightRec>>(
  (ref) => ref.watch(dbProvider).watchWeights(),
);

final templatesProvider = StreamProvider<List<MealTemplate>>(
  (ref) => ref.watch(dbProvider).watchTemplates(),
);
