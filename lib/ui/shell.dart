import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/i18n.dart';
import 'pages/foods_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'pages/today_page.dart';
import 'sheets/food_picker_sheet.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (CupertinoIcons.today, CupertinoIcons.today_fill, 'tabToday'),
    (CupertinoIcons.chart_bar, CupertinoIcons.chart_bar_fill, 'tabStats'),
    (CupertinoIcons.book, CupertinoIcons.book_fill, 'tabFoods'),
    (CupertinoIcons.gear_alt, CupertinoIcons.gear_alt_fill, 'tabSettings'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(onGoSettings: _goSettings),
      const StatsPage(),
      const FoodsPage(),
      const SettingsPage(),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 880;
      final Widget page;
      if (wide) {
        page = Scaffold(
          body: Row(
            children: [
              // 窗口过矮时 Rail 可滚动
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      labelType: constraints.maxWidth >= 1200
                          ? NavigationRailLabelType.all
                          : NavigationRailLabelType.selected,
                      groupAlignment: -0.85,
                      destinations: [
                        for (final (base, selected, label) in _destinations)
                          NavigationRailDestination(
                            icon: Icon(base),
                            selectedIcon: Icon(selected),
                            label: Text(tr(context, label)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: pages[_index]),
            ],
          ),
        );
      } else {
        final separator = Divider.createBorderSide(context, width: 0.5);
        page = Scaffold(
          body: pages[_index],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: separator.color, width: separator.width)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final (base, selected, label) in _destinations)
                  NavigationDestination(
                    icon: Icon(base),
                    selectedIcon: Icon(selected),
                    label: tr(context, label),
                  ),
              ],
            ),
          ),
        );
      }

      // 桌面端快捷键：N 快速记录，1-4 切换页签
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN): _quickAdd,
          const SingleActivator(LogicalKeyboardKey.digit1): () => _go(0),
          const SingleActivator(LogicalKeyboardKey.digit2): () => _go(1),
          const SingleActivator(LogicalKeyboardKey.digit3): () => _go(2),
          const SingleActivator(LogicalKeyboardKey.digit4): () => _go(3),
        },
        child: Focus(autofocus: true, child: page),
      );
    });
  }

  void _go(int i) => setState(() => _index = i);

  void _goSettings() => _go(3);

  void _quickAdd() {
    if (_index != 0) _go(0);
    openAddEntryFlow(context);
  }
}
