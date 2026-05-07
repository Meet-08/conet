import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocBuilder<AppUserCubit, AppUserState>(
      builder: (context, state) {
        final semantic = context.semanticColors;
        final user = state is AppUserAuthenticated ? state.user : null;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: semantic.iconPrimary,
          unselectedItemColor: semantic.iconSecondary,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              activeIcon: Icon(
                CupertinoIcons.calendar_today,
              ), // no fill variant in Cupertino
              label: 'Events',
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.bubble_left),
              activeIcon: Icon(CupertinoIcons.bubble_left_fill),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon:
                  user?.profilePicUrl != null && user!.profilePicUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(user.profilePicUrl!),
                    )
                  : const Icon(CupertinoIcons.person),
              activeIcon:
                  user?.profilePicUrl != null && user!.profilePicUrl!.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: semantic.iconSelected,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(user.profilePicUrl!),
                      ),
                    )
                  : const Icon(CupertinoIcons.person_fill),
              label: 'Profile',
            ),
          ],
          onTap: onTap,
        );
      },
    );
  }
}
