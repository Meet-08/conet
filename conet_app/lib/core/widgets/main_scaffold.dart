import 'package:conet_app/feature/post/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const tabs = ['/home', '/event', '/messages', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = tabs.indexWhere((t) => location.startsWith(t));
    final selectedIndex = index == -1 ? 0 : index;

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: selectedIndex,
        onTap: (i) => context.go(tabs[i]),
      ),
    );
  }
}
