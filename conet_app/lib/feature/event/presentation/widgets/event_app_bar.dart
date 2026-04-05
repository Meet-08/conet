import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class EventAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EventAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Events'),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () => context.push('/event-search'),
          icon: FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: 17,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Search events',
        ),
        IconButton(
          onPressed: () => context.push('/my-events?type=upcoming'),
          icon: FaIcon(
            FontAwesomeIcons.ticket,
            size: 17,
            color: colorScheme.onSurface,
          ),
          tooltip: 'My events',
        ),
        IconButton(
          onPressed: () => context.push('/event-dashboard'),
          icon: FaIcon(
            FontAwesomeIcons.tableCellsLarge,
            size: 16,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Browse event sections',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
