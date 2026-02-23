import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PostAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Conet',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        BlocSelector<AppUserCubit, AppUserState, int>(
          selector: (state) {
            if (state is AppUserAuthenticated) {
              return state.user.unseenNotificationCount;
            }
            return 0;
          },
          builder: (context, count) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.bell,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    // TODO: navigate to notifications page
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: NotificationBadge(count: count),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
