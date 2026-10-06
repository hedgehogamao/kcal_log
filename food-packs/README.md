# 食物数据包（数据插件，不是可执行插件）

App **首次需要安装含加载器的新版本**；已发布的 v0.1.1 尚不支持此格式。
接入后，食物库和 App 版本独立：以后只需要发布/下载新的 JSON 包，然后在
**食物库右上角「食物数据包」**，或 **设置 → 数据 → 食物数据包** 选择文件并确认。
不需要重新编译或安装 App；离线可用，不上传个人数据。

## 提供的包

- **`common-foods-1000.json`：正式 1000 条数据包，数据修订 2。**
  保留原有 237 条及 ID，新增 763 条 USDA FoodData Central SR Legacy 记录。
  同时已编译进 App 内置库：新安装直接有 1000 条；旧库升级只新增条目，
  不覆盖用户修改、不恢复已删除的旧条目。已有自建/删除条目的库总数可能不是恰好 1000。
  有加载器的 App 也可直接导入此 JSON，无需再次更新 App 版本。
- `common-foods-1000.sources.json`：新增条目的官方 FDC ID、完整原始英文描述、
  营养值与来源链接。**这是来源说明，不是可导入包。**
- `common-foods.json`：复制当前内置的 237 条食物，数据修订 1。
  营养值沿用现有库的每 100 g 估算值，不代表新的营养研究或权威检测结果。
- `demo-revision-1.json` / `demo-revision-2.json`：仅用于测试加载、再次更新。
  演示数值不是用于真实饮食记录的食物营养建议。

## 格式

```json
{
  "app": "kcal_log.food_pack",
  "schema": 1,
  "packId": "your-food-library",
  "revision": 1,
  "title": "我的食物库",
  "foods": [{
    "id": "stable-food-id",
    "name": "演示食物（仅测试）",
    "category": "other",
    "kcal100": 100,
    "protein100": 1,
    "fat100": 2,
    "carb100": 10,
    "servingDesc": "1 份",
    "servingGrams": 100
  }]
}
```

## 如何更新

1. 保留同一个 `packId` 和食物 `id`（改名称时也不能改 `id`）。
2. 更改或添加 `foods`，将 `revision` 增加，例如 1 → 2。
3. 分享新 JSON；用户导入并检查预览后确认加载。App 版本保持不变。
   只有数据格式发生不兼容变化、需要新的 `schema` 时，才需要更新加载器。

## 1000 条数据的来源与使用

新增部分来自 [USDA 官方 SR Legacy CSV 下载](https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip)，
这是最终 2018 年历史版本，不宣称是最新检测结果。采用官方 Energy（1008，KCAL）、
Protein（1003）、Total lipid（1004）、Carbohydrate by difference（1005）数值，均以每 100 g 计。
不把缺失营养值当作 0，也不通过公式编造热量。原 237 条仍是原库估算值。

新增名称是「中文食物关键词 · 完整英文描述」，可中文搜索，英文保留品种、部位、
生熟、加工与含糖状态，避免错误合并。不同生熟/品种记录不是多算一份食物；
记录饮食时只选最贴近实际食物的一项。新增默认份量为 100 克。
来源说明与可导入 JSON 分开，兼容现有严格 schema；导入修订 2 后不能用修订 1 降级。

如需复现：`python3 tool/build_1000_foods.py USDA_ZIP`，再运行 Flutter 导出测试。
生成器不改写原始 237 条包。

## 验证与保护规则

- JSON 上限 5 MiB；每包 1–10000 条；同包的 ID 和规范化名称不重复。
- `packId` 仅允许字母、数字、点、下划线、短横线，最长 80。
- 食物 ID、名称、标题最长 120；数值必须为有限非负数。
- 热量 0–900 kcal/100 g；三大营养素各 0–100 g/100 g。
- 分类固定为 `staple/protein/vegetable/fruit/dairy/snack/drink/dish/other`。
- `brand`、`servingDesc`、`servingGrams` 可选；份量描述与克数须同时提供或同时为空，克数须 >0 且 ≤100000。
- 不执行任何代码，不接受 App 备份当作食物包，不接受旧修订覆盖新修订。
  相同修订内容必须相同（食品顺序可不同）；内容更改必须提高 revision。
- 首次加载可认领未修改过的同名内置食物；自建食物、已修改的内置食物、其他数据包的同名食物都保留。
- 后续只更新此前由该包管理、且未被用户改动的食物。个人修改或删除后不自动恢复/覆盖。
- 收藏不变，历史饮食营养快照不变；包中缺少的食物不删除。
- 预览不写数据库；取消不写；确认时重新检查，所有变更与数据包修订在同一个 SQLite 事务中提交。
- App JSON 备份包含数据包管理记录；老备份不含记录时只保护现有食物，不猜测所属包。

## 开发验证

```sh
flutter test test/food_pack_test.dart test/food_pack_ui_test.dart
flutter test tool/export_food_pack_test.dart
flutter analyze
```

修改和分享 JSON 不需要运行这些 Flutter 命令；它们只用于加载器开发或重新导出原内置库。
