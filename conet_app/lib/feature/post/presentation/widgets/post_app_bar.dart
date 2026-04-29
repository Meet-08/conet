import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/widgets/notification_badge.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/notification/presentation/bloc/notification_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class PostAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PostAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      elevation: 0,
      backgroundColor: semantic.surfaceBase,
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
          Text(
            'Conet',
            style: textTheme.titleMedium?.copyWith(color: semantic.textPrimary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            color: semantic.iconPrimary,
          ),
          onPressed: () {
            showUserSelectorBottomSheet(
              context: context,
              title: 'Search users',
              searchHint: 'Search by name, username, or email',
              actionLabel: 'View profile',
              allowMultipleSelection: false,
              onUserTap: (parentContext, user) =>
                  parentContext.push('/user-profile', extra: user.id),
            );
          },
        ),
        BlocSelector<NotificationBloc, NotificationState, int>(
          selector: (state) => state.unseenCount,
          builder: (context, count) {
            return Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.bell,
                        color: semantic.iconPrimary,
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
