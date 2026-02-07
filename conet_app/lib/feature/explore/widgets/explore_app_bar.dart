import 'package:flutter/material.dart';

class ExploreAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ExploreAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: const [
          Text(
            'For You',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
