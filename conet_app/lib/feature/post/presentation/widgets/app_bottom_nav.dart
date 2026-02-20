import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house), label: 'Home'),
        BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.magnifyingGlass), label: 'Explore'),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.calendar),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.comment),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.user),
          label: 'Profile',
        ),
      ],
      onTap: onTap,
    );
  }
}
