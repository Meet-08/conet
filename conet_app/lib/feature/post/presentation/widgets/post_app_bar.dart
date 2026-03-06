import 'package:conet_app/core/widgets/notification_badge.dart';
import 'package:conet_app/feature/notification/presentation/bloc/notification_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class PostAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PostAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/app_icon.png',
              height: 32,
              width: 32,
              fit: BoxFit.cover,
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
        BlocSelector<NotificationBloc, NotificationState, int>(
          selector: (state) => state.unseenCount,
          builder: (context, count) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.bell,
                    color: Colors.black,
                  ),
                  onPressed: () => context.push('/notifications'),
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
