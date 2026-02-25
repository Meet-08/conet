import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageFilters extends StatelessWidget {
  const MessageFilters({super.key});

  static const _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Groups', 'value': 'group'},
    {'label': 'Direct', 'value': 'direct'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: BlocSelector<MessageBloc, MessageState, String>(
        selector: (state) => state.conversationFilter,
        builder: (context, activeFilter) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                return _FilterChip(
                  label: f['label']!,
                  isActive: activeFilter == f['value'],
                  onTap: () {
                    context.read<MessageBloc>().add(
                      MessageFilterChanged(f['value']!),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _FilterChip({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.black : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
