import 'package:flutter/material.dart';

class InterestsSection extends StatefulWidget {
  final List<String> interests;

  const InterestsSection({super.key, required this.interests});

  @override
  State<InterestsSection> createState() => _InterestsSectionState();
}

class _InterestsSectionState extends State<InterestsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.interests.isEmpty) return const SizedBox.shrink();

    final showMore = widget.interests.length > 5;
    final displayedInterests = (_isExpanded || !showMore)
        ? widget.interests
        : widget.interests.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (showMore)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? 'Show less' : 'See all',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayedInterests
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
