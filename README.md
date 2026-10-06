# 卡路里日记 (KcalLog)

本地优先的每日食物热量记录应用，一套代码运行于 **iOS / Android / macOS / Windows**。

> 设计目标：OpenNutriTracker 的功能完整度 + FitBook 的纯本地架构。
> 数据 100% 保存在本设备，无账号、无自建后端、单用户自用。
> 设计系统见 [DESIGN.md](DESIGN.md)（Apple 系统风格），调研与方案见 [../calorie-app-design.md](../calorie-app-design.md)。

## 功能

**记录（MVP）**
- 今日页：卡路里进度环 + 蛋白质/脂肪/碳水进度条 + 早/午/晚/加餐四餐列表
- 添加：名称/品牌/条码/中文别名搜索、分类与来源叠加筛选、最近使用和收藏
- 记录确认：选择餐次与份量、实时营养预览和记录后剩余；取消不写入，重复确认不重复提交，kcal/kJ 输入一致
- 快速添加：只记总热量；编辑/滑动删除记录（可撤销）
- 自定义食物 CRUD（每 100g 营养值 + 常用份量）
- 组合餐：复用食物库的搜索、分类与收藏；逐项调整份量，保存不立即记录。添加时先确认日期、餐次与总热量，再一次记录全部
- 内置 **1000 条**食物（原 237 条估算值保持不变，新增 763 条 USDA SR Legacy 记录；每 100g，可编辑）
- 独立 JSON 食物数据包：食物库右上角或设置 → 数据 → 食物数据包，预览并确认加载；以后更新食物无需重装 App
- 最新独立食物包 **5000 条（修订 3）**：保留原 1000 条及 ID，新增 4000 条可核验 USDA 历史记录；v0.1.2 可直接导入 [common-foods-5000.json](food-packs/common-foods-5000.json)，App 内置仍为 1000 条，版本不变
- 升级只补充新条目，保护个人修改、收藏、历史记录及已删除条目；数据来源和修订规则见 [food-packs/README.md](food-packs/README.md)

**进阶**
- 统计：7/30 天热量趋势、每日明细、10 周日历热力图、连续记录与近7天宏量均值；日均明确按有记录的天数计算，缺失日不当作0，图表与目标同步换算 kcal/kJ
- 体重记录 + 最近90条趋势（说明对比日期，验证输入并事务同步个人资料）
- 饮水追踪（每日目标 + 快捷加减）
- 目标设置：手填，或按个人资料估算（Mifflin-St Jeor 基础代谢 × 活动系数）
- 目标编辑使用当前能量单位，支持留空/按钮清除；资料估算仅在明确选择时覆盖目标，保存体重与资料为同一事务
- 能量单位 kcal / kJ 切换、深浅色主题
- 数据导出/导入 JSON（跨设备迁移 = 导出文件 → 拷贝 → 导入，保持无后端）
- 桌面导出实际写入所选文件，取消不生成隐式备份；导入先展示文件与条目数，并明确确认覆盖
- Open Food Facts 在线搜索 + 条码查询（可选联网，只读，不存储个人数据）

**桌面端**
- 宽屏自适应布局（NavigationRail）
- 快捷键：`N` 快速记录，`1-4` 切换页签；输入框获得焦点时让位于文字与条码输入

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

测试：`flutter test`（计算、数据库迁移、搜索分类、记录确认、历史日期、饮水、编辑删除撤销与响应式布局）；静态检查：`flutter analyze`。

今日页分别展示已摄入、剩余/超标与每日目标；计算说明通过明确按钮打开。历史日可回到今天，选中餐次可直接记录，窄屏和大字号自动换行。

## 数据与隐私

- 所有数据存储在 Drift 原生默认的本机文档目录下的 `kcallog.sqlite`（沙盒平台为应用文档目录），设置页可查看并复制完整路径
- 无账号、无遥测；联网仅在你主动开启「OFF 在线」搜索或条码查询时发生
- 卸载即数据消失，请定期导出备份

## Roadmap

- 移动端摄像头扫码（mobile_scanner，桌面端目前为手输条码）
- 微量营养素面板（OpenNutriTracker 式 10 项维生素/矿物质）
- 可选 WebDAV/iCloud 文件同步（仍无自建服务器）
- 断食计时器、AI 拍照识别（需自备 API key）
