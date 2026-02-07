import 'package:conet_app/feature/explore/widgets/trending_topic_chip.dart';
import 'package:flutter/material.dart';

class TrendingTopics extends StatelessWidget {
  const TrendingTopics({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 18),
              SizedBox(width: 6),
              Text(
                'Trending Topics',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TrendingTopicChip(
                  rank: 1,
                  title: 'Web Development',
                  count: '1.2k',
                ),
                TrendingTopicChip(
                  rank: 2,
                  title: 'Machine Learning',
                  count: '980',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
