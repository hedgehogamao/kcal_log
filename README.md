# 卡路里日记 (KcalLog)

本地优先的每日食物热量记录应用，一套代码运行于 **iOS / Android / macOS / Windows**。

> 设计目标：OpenNutriTracker 的功能完整度 + FitBook 的纯本地架构。
> 数据 100% 保存在本设备，无账号、无自建后端、单用户自用。
> 设计系统见 [DESIGN.md](DESIGN.md)（Starbucks 风），调研与方案见 [../calorie-app-design.md](../calorie-app-design.md)。

## 功能

**记录（MVP）**
- 今日页：卡路里进度环 + 蛋白质/脂肪/碳水进度条 + 早/午/晚/加餐四餐列表
- 添加：本地食物库搜索、最近使用、收藏、按克数或常用份量记录
- 快速添加：只记总热量；编辑/滑动删除记录（可撤销）
- 自定义食物 CRUD（每 100g 营养值 + 常用份量）
- 组合餐：把常吃的一餐存成组合，添加时一键记录全部
- 内置 237 条常见食物（每 100g 估算值，可编辑；升级时仅补充缺失条目）

**进阶**
- 统计：7/30 天热量趋势图、GitHub 风格 10 周热力图、连续记录天数、近 7 天宏量均值
- 体重记录 + 趋势图（同步更新个人资料）
- 饮水追踪（每日目标 + 快捷加减）
- 目标设置：手填，或按个人资料估算（Mifflin-St Jeor 基础代谢 × 活动系数）
- 能量单位 kcal / kJ 切换、深浅色主题
- 数据导出/导入 JSON（跨设备迁移 = 导出文件 → 拷贝 → 导入，保持无后端）
- Open Food Facts 在线搜索 + 条码查询（可选联网，只读，不存储个人数据）

**桌面端**
- 宽屏自适应布局（NavigationRail）
- 快捷键：`N` 快速记录，`1-4` 切换页签

## 技术栈

Flutter + Drift(SQLite) + Riverpod + Material 3。图表与进度环为自绘（CustomPaint），无重型图表依赖。

## 运行与构建

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift 代码生成

flutter run -d macos       # macOS（本机已验证）
flutter build macos --release
flutter build apk --release          # Android
flutter build ios --release          # iOS（需 Xcode）
flutter build windows --release      # Windows（需 Windows + Visual Studio）
```

测试：`flutter test`（计算逻辑 + 数据库往返共 15 个用例）

## 数据与隐私

- 所有数据存储在本机应用支持目录下的 `kcallog.sqlite`，设置页可查看路径
- 无账号、无遥测；联网仅在你主动开启「OFF 在线」搜索或条码查询时发生
- 卸载即数据消失，请定期导出备份

## Roadmap

- 移动端摄像头扫码（mobile_scanner，桌面端目前为手输条码）
- 微量营养素面板（OpenNutriTracker 式 10 项维生素/矿物质）
- 可选 WebDAV/iCloud 文件同步（仍无自建服务器）
- 断食计时器、AI 拍照识别（需自备 API key）
