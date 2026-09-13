import 'package:flutter/material.dart';

import '../theme.dart';

/// 顶部标签页：下划线随 PageView 拖动百分比实时位移（跟手），
/// 选中标签自动滚动到可视区中央。
///
/// 标签位置用 TextPainter 预测量（无需 GlobalKey/RenderObject），
/// 切换语言重建标签后自动重算。
class TopTabs extends StatefulWidget {
  const TopTabs({
    super.key,
    required this.tabs,
    required this.pageBuilder,
    this.pageHeight,
  });

  final List<String> tabs;
  final Widget Function(BuildContext, int) pageBuilder;

  /// 页面固定高度；为 null 时 PageView 撑满剩余空间（需要外层是 Column）
  final double? pageHeight;

  @override
  State<TopTabs> createState() => _TopTabsState();
}

class _TopTabsState extends State<TopTabs> {
  final _page = PageController();
  final _labels = ScrollController();
  double _pos = 0; // 分数页位置（0..n-1）
  List<double> _centers = const [];

  @override
  void initState() {
    super.initState();
    _page.addListener(_onPage);
    _measure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {}); // 让下划线在控制器挂载后出现
    });
  }

  @override
  void didUpdateWidget(TopTabs old) {
    super.didUpdateWidget(old);
    if (old.tabs != widget.tabs) _measure();
  }

  @override
  void dispose() {
    _page.removeListener(_onPage);
    _page.dispose();
    _labels.dispose();
    super.dispose();
  }

  void _measure() {
    const bold = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    const reg = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
    final centers = <double>[];
    var x = 16.0; // 行首留白，与 SingleChildScrollView 的 padding 一致
    for (var i = 0; i < widget.tabs.length; i++) {
      final tw = _textWidth(widget.tabs[i], bold) > _textWidth(widget.tabs[i], reg)
          ? _textWidth(widget.tabs[i], bold)
          : _textWidth(widget.tabs[i], reg);
      final w = tw + 32; // 左右各 16 内边距
      centers.add(x + w / 2);
      x += w + 24; // 标签间距
    }
    _centers = centers;
  }

  double _textWidth(String s, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  void _onPage() {
    if (!_page.hasClients) return;
    final p = _page.page ?? _pos;
    if (p != _pos) setState(() => _pos = p);
    _centerLabels(p);
  }

  /// 下划线中心在内容坐标中的位置（随拖动百分比插值）
  double _contentCenter(double p) {
    final n = _centers.length;
    if (n == 1) return _centers[0];
    if (p <= 0) return _centers[0];
    if (p >= n - 1) return _centers[n - 1];
    final i = p.floor();
    final t = p - i;
    return _centers[i] + (_centers[i + 1] - _centers[i]) * t;
  }

  void _centerLabels(double p) {
    if (_centers.length != widget.tabs.length || !_labels.hasClients) return;
    final vw = _labels.position.viewportDimension;
    final target =
        (_contentCenter(p) - vw / 2).clamp(0.0, _labels.position.maxScrollExtent);
    _labels.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final n = widget.tabs.length;
    final sel = _pos.round().clamp(0, n - 1);

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _labels,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 24),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _page.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: i == sel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: i == sel
                                      ? LabelColors.inkOf(dark)
                                      : LabelColors.inkSoftOf(dark),
                                ),
                                child: Text(widget.tabs[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 下划线：屏幕坐标 = 内容坐标 − 横向滚动偏移
              if (_labels.hasClients && _centers.length == n)
                Positioned(
                  left: (_contentCenter(_pos) - _labels.offset - 12)
                      .clamp(0.0, double.infinity),
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: LabelColors.blueOf(dark),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        widget.pageHeight == null
            ? Expanded(
                child: PageView(
                  controller: _page,
                  allowImplicitScrolling: true, // 相邻页保活，切换不丢输入状态
                  children: [
                    for (var i = 0; i < n; i++) widget.pageBuilder(context, i),
                  ],
                ),
              )
            : SizedBox(
                height: widget.pageHeight,
                child: PageView(
                  controller: _page,
                  allowImplicitScrolling: true,
                  children: [
                    for (var i = 0; i < n; i++) widget.pageBuilder(context, i),
                  ],
                ),
              ),
      ],
    );
  }
}
