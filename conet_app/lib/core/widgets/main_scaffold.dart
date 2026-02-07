import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../feature/home/widgets/home_bottom_nav.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const tabs = ['/home', '/explore', '/event', '/messages', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = tabs.indexWhere((t) => location.startsWith(t));
    final selectedIndex = index == -1 ? 0 : index;

    return Scaffold(
      body: child,
      bottomNavigationBar: HomeBottomNav(
        currentIndex: selectedIndex,
        onTap: (i) => context.go(tabs[i]),
      ),
    );
  }
}
