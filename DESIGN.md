# Design System — Apple / iOS 系统风格

> kcal_log「卡路里日记」专用设计系统。视觉词汇来自 iOS 系统设置与 Apple Health：
> 分组背景、纯白圆角卡片、系统分隔线、系统色（蓝=交互、粉红=能量）、
> 活动圆环、Cupertino 滑动分段控件与开关。
> Token 实现：`lib/ui/theme.dart`（LabelColors / numberStyle / captionStyle / buildLightTheme / buildDarkTheme）。

## 1. 视觉主题

一个「iOS 原生 App」：界面即系统，数据像系统健康 App 一样以语义色呈现。
所有交互（按钮、链接、选中态、饮水）一律 systemBlue；能量 kcal 独占 Apple Health
粉红；三大营养素用绿/橙/青。卡片无边框、无阴影，靠分组背景衬托层次。
控件尽量用 Cupertino 组件（滑动分段、开关、图标），让四端都长得像 macOS/iOS。

**Key Characteristics**
- 浅色 #F2F2F7 分组画布 + 纯白卡片（10px 圆角、无边框、无投影）；深色纯黑 + #1C1C1E 卡片
- 交互色 systemBlue #007AFF/#0A84FF：按钮、链接、箭头、选中态、饮水、进度
- 能量粉红 #FF2D55/#FF375F 只属于 kcal 数据与超标警示（error=systemRed）
- 签名元素：Apple Fitness 活动圆环（粗描边、12 点起顺时针、同色 15% 底轨）
- Cupertino 控件：CupertinoSlidingSegmentedControl（餐次/7-30天/外观/性别）、CupertinoSwitch
- 全部图标用 CupertinoIcons；导航底栏/侧栏无 pill 指示、顶部发丝线

## 2. 色彩（iOS System Colors）

| Token | 浅色 | 深色 | 语义 |
|---|---|---|---|
| paper | #F2F2F7 | #000000 | 页面画布 systemGroupedBackground |
| card | #FFFFFF | #1C1C1E | 卡片/弹层/底栏 |
| ink | #000000 | #FFFFFF | 主文字 label |
| inkSoft | #8E8E93 | #8D8D93 | 次要文字 secondaryLabel |
| rule | #C6C6C8 | #38383A | separator（描边、发丝线；卡片内分隔线用更浅的 #E2E2E7） |
| fill | #E9E9EB | #2C2C2E | systemFill（输入框/轨道/侧栏指示/灰按钮） |
| blue | #007AFF | #0A84FF | 交互、链接、饮水 |
| energy | #FF2D55 | #FF375F | 能量 kcal、趋势线、超标（error #FF3B30/#FF453A） |
| protein | #34C759 | #30D158 | 蛋白质 · systemGreen |
| fat | #FF9500 | #FF9F0A | 脂肪 · systemOrange |
| carb | #30B0C7 | #40C8E0 | 碳水 · systemTeal |
| weight | #AF52DE | #BF5AF2 | 体重线 · systemPurple |

**Rules**
- 蓝色只做「可交互」语义；kcal 读数一律粉红（numberStyle + energyOf）
- 三宏量颜色永不互换；图例必须带色点（无描边胶囊，纯「色点+文字」）
- 卡片一律无描边、无阴影、10px 圆角；发丝线只用于分隔内容

## 3. 字体

- 系统字族自动命中 SF Pro（Apple 平台）/ PingFang（中文），不引入字体文件
- **数据主角** `numberStyle(size, color)`：w700、letterSpacing -0.5、tabular figures、height 1.0
- **小节标题** `captionStyle(context)`：13px、w400、次要色——iOS 分组列表 header
- 卡片内标题：15px w600（行内样式）；导航标题：17px w600 居中；页面大字：17px w600
- 正文：系统默认（14-15px）；列表项名称常规字重（iOS 行高风格）

## 4. 组件签名

- **活动圆环**（lib/ui/widgets/charts.dart RingProgress）：描边 = 尺寸 8.5%，同色 15% 底轨，12 点方向顺时针；超标整环转 systemRed；中心 numberStyle(30) + caption
- **MacroBars**：8px 堆叠比例条（段间 1.5px 留白，按 kcal 占比 p×4/f×9/c×4）+ 无边框图例（色点 + `蛋白 12g / 60g`，数值加粗）
- **分组卡片**：白卡 10px 圆角；条目间 0.5px 分隔线（indent 16）；行 trailing kcal 粉红加粗
- **按钮**：Filled=蓝胶囊、Outlined=灰底胶囊（iOS 灰按钮）、Text=蓝字；FAB=蓝色胶囊「+ 记录」
- **Cupertino 控件**：CupertinoSlidingSegmentedControl（thumb 白/#636366）、CupertinoSwitch（默认绿）
- **输入框**：灰底无边框圆角 10（systemFill），聚焦时蓝描边 1.5
- **折线图**：无圆点、2.5px 圆头描边；目标虚线；热力图 绿色梯度 + 红色超标

### 可复用交互组件（lib/ui/widgets/，均已融入真实页面交互）

- **CollapsibleCard**：折叠卡片——高度、内容透明度、箭头角度共用同一个 AnimationController 的一条 easeInOutCubic 曲线（320ms）；自定义 header 行 + 自动追加动画箭头。**用于今日页四餐卡片**（点餐次头折叠/展开记录，头部右侧蓝色 + 直接添加）
- **AppSegmented<T>**：自制分段控件——灰底槽 + 白色选中块 AnimatedPositioned 位移（240ms easeOutCubic）；**用于统计页 7/30 天**（切换时图表带方向性横滑）
- **SlideToConfirm**：滑动确认——拖过 80% 触发（先滑到底再回调），不足由 easeOutCubic 回弹；进行中蓝、完成转绿。**用于导入备份确认弹窗**（覆盖导入不可逆，滑动代替按钮）
- **FlipCard**：翻转卡片——rotateY + 透视（setEntry(3,2,0.0016)），过 90° 中途换面，背面预镜像保证文字正向。**用于今日总览卡**（正面活动环数据，背面计算规则说明）
- **FilterPills<T>**：筛选胶囊——选中实底蓝、未选中灰底，横向滚动。**用于选食物弹层（全部/最近/收藏）与食物库页来源筛选（全部/收藏/内置/自定义/OFF）**
- **BottomActionBar**：吸底操作栏——卡片底色 + 0.5px 顶线，左信息右 FilledButton，SafeArea 避让。**用于记录弹层**（左侧实时「还可摄入/已摄入」，右侧添加/保存，编辑模式最左删除）
- **SmartField**：智能输入框——TextInputFormatter 过滤 + 右侧常驻单位图标/单位/字数 n/max，支持外部 controller。**用于记录弹层的热量与份量输入**
- **TopTabs**：顶部标签页——下划线随 PageView 分数页位置插值（跟手），TextPainter 预测量标签宽，自动滚动居中；allowImplicitScrolling 保活邻页。**用于食物库页 食物/组合餐**
- **MealProgressCard**：四餐进度——已记录=绿底白勾、当前选中=蓝底（下方 AnimatedSwitcher 展开该餐详情，含「当前餐」标签）、未记录=灰底灰点，点节点切换详情。**用于今日页（总览卡与饮水卡之间）**
- **操作卡片模式**（加减就地生效+回显）：**饮水卡**（±250ml 即时写库，进度条+百分比回显）；**组合餐编辑器条目**（±50g 步进，顶部汇总 kcal 实时重算）

## 5. 布局

- 移动端：底部导航（今日/统计/食物库/设置，CupertinoIcons），顶栏 0.5px 发丝线，页边距 16，卡片间距 8
- 桌面 ≥880px：NavigationRail（iPadOS 侧栏风：灰底选中指示，无蓝色 pill）+ 内容区
- 今日页 hero = 总览卡：左活动圆环（140px）+ 右总量与宏量图例

## 6. Do / Don't

- ✅ 新数据展示先问它的语义色（能量粉红/蛋白绿/脂肪橙/碳水青/交互蓝/中性）
- ✅ 控件优先 Cupertino（分段、开关、图标）；新增列表用白卡 + 0.5px 分隔线
- ✅ 数字优先 numberStyle；单位与说明用次要色小字
- ❌ 不加阴影、渐变、描边卡片；不用 pill 指示条
- ❌ 不把蓝色用于数据读数，不把粉红用于按钮/装饰
- ❌ 不再使用旧「营养标签」色板（番茄红/橄榄绿/墨色）与 Material 图标新增项
- ❌ 新组件文案必须进 `lib/logic/i18n.dart` 的 kStrings 表（三语），勿写死字面量
- ✅ 交互微动效统一 200-360ms、easeOutCubic/easeInOutCubic；新交互组件直接融入真实页面（验证方式见 test/golden_today_test.dart：内存库 + 真实字体离屏渲染 PNG）
