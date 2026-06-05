import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/event-search'),
          icon: Icon(
            PhosphorIconsBold.magnifyingGlass,
            size: 20,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          tooltip: 'Search events',
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/my-events?type=upcoming'),
          icon: Icon(
            PhosphorIconsBold.ticket,
            size: 20,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          tooltip: 'My events',
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/event-dashboard'),
          icon: Icon(
            PhosphorIconsBold.squaresFour,
            size: 20,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          tooltip: 'Browse event sections',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
