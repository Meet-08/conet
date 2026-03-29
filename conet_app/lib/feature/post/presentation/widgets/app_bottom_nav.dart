import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocSelector<AppUserCubit, AppUserState, int>(
      selector: (state) {
        if (state is AppUserAuthenticated) {
          return state.user.unseenNotificationCount;
        }
        return 0;
      },
      builder: (context, unseenCount) {
        return BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.calendar),
              label: 'Events',
            ),
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.comment),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.user),
              label: 'Profile',
            ),
          ],
          onTap: onTap,
        );
      },
    );
  }
}
