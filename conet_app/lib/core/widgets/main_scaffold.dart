import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const tabs = ['/home', '/event', '/chat', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = tabs.indexWhere((t) => location.startsWith(t));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.black);
            }
            return const IconThemeData(color: Colors.grey);
          }),

          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(tabs[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.house),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.calendar),
              label: 'Event',
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.comment),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
