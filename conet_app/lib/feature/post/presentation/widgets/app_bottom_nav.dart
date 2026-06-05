import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
          unselectedFontSize: 14,
          selectedFontSize: 14,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(
                PhosphorIconsBold.house,
                size: 24,
                fontWeight: FontWeight.w500,
              ),
              activeIcon: Icon(
                PhosphorIconsFill.house,
                size: 24,
                fontWeight: FontWeight.w500,
              ),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(
                PhosphorIconsBold.calendarBlank,
                size: 24,
                fontWeight: FontWeight.w500,
              ),
              activeIcon: Icon(
                PhosphorIconsFill.calendarBlank,
                size: 24,
                fontWeight: FontWeight.w500,
              ),
              label: 'Events',
            ),
            const BottomNavigationBarItem(
              icon: Icon(
                PhosphorIconsBold.chatCircle,
                size: 24,
                fontWeight: FontWeight.w500,
              ),
              activeIcon: Icon(
                PhosphorIconsFill.chatCircle,
                size: 24,
                fontWeight: FontWeight.w500,
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon:
                  user?.profilePicUrl != null && user!.profilePicUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(user.profilePicUrl!),
                    )
                  : const Icon(
                      PhosphorIconsRegular.user,
                      size: 24,
                      fontWeight: FontWeight.w500,
                    ),
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
                  : const Icon(
                      PhosphorIconsBold.user,
                      size: 24,
                      fontWeight: FontWeight.w500,
                    ),
              label: 'Profile',
            ),
          ],
          onTap: onTap,
        );
      },
    );
  }
}
