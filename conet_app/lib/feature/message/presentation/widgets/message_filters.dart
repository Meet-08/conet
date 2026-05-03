import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
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
    return SizedBox(
      width: double.infinity,
      child: BlocSelector<MessageBloc, MessageState, String>(
        selector: (state) => state.conversationFilter,
        builder: (context, activeFilter) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 8,
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
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.backgroundBrand : colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colors.borderBrand : colors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? colors.textOnBrand : colors.textPrimary,
            fontWeight: isActive
                ? AppTypographyTokens.weightSemibold
                : AppTypographyTokens.weightRegular,
          ),
        ),
      ),
    );
  }
}
