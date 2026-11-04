import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Restrained, gesture-linked page motion. Flutter owns the indicator geometry,
/// hit testing, RTL and tab semantics; page data is not rebuilt on every frame.
class TopTabs extends StatefulWidget {
  const TopTabs({
    super.key,
    required this.tabs,
    required this.pageBuilder,
    this.pageHeight,
  }) : assert(tabs.length > 0);
  final List<String> tabs;
  final Widget Function(BuildContext, int) pageBuilder;
  final double? pageHeight;
  @override
  State<TopTabs> createState() => _TopTabsState();
}

class _TopTabsState extends State<TopTabs> with TickerProviderStateMixin {
  late TabController _tabs;
  final _pages = PageController();
  bool _syncing = false;
  bool _animatingPage = false;
  bool _userDragging = false;
  int _pageRun = 0;
  int _pageTarget = 0;
  bool _reducedMotion = false;
  int _focusedTab = 0;
  @override
  void initState() {
    super.initState();
    _createController(0);
    _pages.addListener(_onPage);
  }

  void _createController(int index) {
    _tabs = TabController(
      length: widget.tabs.length,
      initialIndex: index,
      animationDuration: _reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      vsync: this,
    )..addListener(_onTab);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduce != _reducedMotion) {
      _reducedMotion = reduce;
      final index = _tabs.index;
      _tabs.dispose();
      _createController(index);
    }
  }

  @override
  void didUpdateWidget(TopTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      final index = _tabs.index.clamp(0, widget.tabs.length - 1);
      _tabs.dispose();
      _createController(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jump(index);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onTab() {
    if (_syncing || _userDragging || !_pages.hasClients) return;
    if (_animatingPage && _pageTarget == _tabs.index) return;
    if ((_pages.page! - _tabs.index).abs() < .0001) {
      ++_pageRun;
      _animatingPage = false;
      _pages.jumpToPage(_tabs.index);
      return;
    }
    if (_reducedMotion) {
      _pages.jumpToPage(_tabs.index);
    } else {
      _animatingPage = true;
      _pageTarget = _tabs.index;
      final run = ++_pageRun;
      _pages
          .animateToPage(
            _tabs.index,
            duration: const Duration(milliseconds: 240),
            curve: Curves.ease,
          )
          .whenComplete(() {
            if (mounted && run == _pageRun) {
              _animatingPage = false;
              _onPage();
            }
          });
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollEndNotification) {
      _userDragging = false;
      _onPage();
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userDragging = true;
      ++_pageRun;
      _animatingPage = false;
      final value = _pages.page!;
      _syncing = true;
      final target = value.round().clamp(0, widget.tabs.length - 1);
      if (_tabs.index == target && _tabs.indexIsChanging) {
        _tabs.index = _tabs.previousIndex;
      }
      _tabs.index = target;
      _syncing = false;
    }
    return false;
  }

  void _onPage() {
    if (_syncing ||
        _animatingPage ||
        _tabs.indexIsChanging ||
        !_pages.hasClients) {
      return;
    }
    final value = _pages.page!.clamp(0.0, (widget.tabs.length - 1).toDouble());
    _syncing = true;
    _tabs.index = value.round();
    _tabs.offset = (value - _tabs.index).clamp(-1.0, 1.0);
    _syncing = false;
  }

  void _jump(int index) {
    final target = index.clamp(0, widget.tabs.length - 1);
    _syncing = true;
    _userDragging = false;
    ++_pageRun;
    _animatingPage = false;
    _pageTarget = target;
    if (_tabs.index == target && _tabs.indexIsChanging) {
      _tabs.index = _tabs.previousIndex;
    }
    _tabs.index = target;
    if (_pages.hasClients) _pages.jumpToPage(target);
    _syncing = false;
  }

  double _trackWidth(BuildContext context, double available) {
    var width = 6.0;
    for (final label in widget.tabs) {
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      width += text.width + 36;
      text.dispose();
    }
    return math.min(available, width.ceilToDouble());
  }

  void _step(int direction) => _jump(
    _tabs.index +
        (Directionality.of(context) == TextDirection.rtl
            ? -direction
            : direction),
  );
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final labelHeight = math.max(
      46.0,
      MediaQuery.textScalerOf(context).scale(15) * 1.35 + 16,
    );
    final pages = PageView(
      key: const ValueKey('motion-tab-pages'),
      controller: _pages,
      allowImplicitScrolling: true,
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          _RetainedTabPage(
            key: ValueKey('retained-tab-$i'),
            child: AnimatedBuilder(
              animation: _pages,
              child: RepaintBoundary(child: widget.pageBuilder(context, i)),
              builder: (context, child) {
                final distance =
                    ((_pages.hasClients
                                ? _pages.page ?? _tabs.index.toDouble()
                                : _tabs.index.toDouble()) -
                            i)
                        .abs()
                        .clamp(0.0, 1.0);
                return Transform.scale(
                  key: ValueKey('tab-depth-$i'),
                  scale: reduce ? 1 : 1 - .012 * distance,
                  child: Opacity(
                    opacity: reduce ? 1 : 1 - .10 * distance,
                    child: child,
                  ),
                );
              },
            ),
          ),
      ],
    );
    final view = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: pages,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: _trackWidth(context, constraints.maxWidth),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(
                        LogicalKeyboardKey.arrowRight,
                      ): () =>
                          _step(1),
                      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                          _step(-1),
                      const SingleActivator(LogicalKeyboardKey.enter): () =>
                          _jump(_focusedTab),
                      const SingleActivator(
                        LogicalKeyboardKey.numpadEnter,
                      ): () =>
                          _jump(_focusedTab),
                      const SingleActivator(LogicalKeyboardKey.space): () =>
                          _jump(_focusedTab),
                      const SingleActivator(LogicalKeyboardKey.home): () =>
                          _jump(0),
                      const SingleActivator(LogicalKeyboardKey.end): () =>
                          _jump(widget.tabs.length - 1),
                    },
                    child: Focus(
                      skipTraversal: true,
                      child: TabBar(
                        key: const ValueKey('motion-tab-bar'),
                        controller: _tabs,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.all(3),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorAnimation: reduce
                            ? TabIndicatorAnimation.linear
                            : TabIndicatorAnimation.elastic,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: .35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: dark ? .12 : .05,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: LabelColors.blueOf(dark),
                        unselectedLabelColor: LabelColors.inkSoftOf(dark),
                        labelStyle: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                        unselectedLabelStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                        onFocusChange: (focused, index) {
                          if (focused) _focusedTab = index;
                        },
                        tabs: [
                          for (final label in widget.tabs)
                            Tab(height: labelHeight, text: label),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.pageHeight == null)
          Expanded(child: view)
        else
          SizedBox(height: widget.pageHeight, child: view),
      ],
    );
  }
}

class _RetainedTabPage extends StatefulWidget {
  const _RetainedTabPage({super.key, required this.child});
  final Widget child;
  @override
  State<_RetainedTabPage> createState() => _RetainedTabPageState();
}

class _RetainedTabPageState extends State<_RetainedTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
