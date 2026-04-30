import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';
import 'package:conet_app/feature/report/presentation/bloc/report_bloc.dart';
import 'package:conet_app/feature/report/presentation/bloc/report_event.dart';
import 'package:conet_app/feature/report/presentation/bloc/report_state.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Future<void> showReportBottomSheet({
  required BuildContext context,
  required String targetId,
  required ReportTargetType targetType,
  required String targetLabel,
  String? targetSubtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => serviceLocator<ReportBloc>(),
      child: _ReportBottomSheet(
        parentContext: context,
        targetId: targetId,
        targetType: targetType,
        targetLabel: targetLabel,
        targetSubtitle: targetSubtitle,
      ),
    ),
  );
}

class _ReportBottomSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String targetId;
  final ReportTargetType targetType;
  final String targetLabel;
  final String? targetSubtitle;

  const _ReportBottomSheet({
    required this.parentContext,
    required this.targetId,
    required this.targetType,
    required this.targetLabel,
    required this.targetSubtitle,
  });

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  static const _reasons = [
    'Spam or misleading',
    'Harassment or bullying',
    'Hate speech',
    'Nudity or sexual content',
    'Scam or fraud',
    'Violence or dangerous behavior',
    'Other',
  ];

  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    final selectedReason = _selectedReason;
    if (selectedReason == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<ReportBloc>().add(
      ReportCreateRequested(
        targetId: widget.targetId,
        targetType: widget.targetType,
        reason: selectedReason,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }

  void _closeWithSuccess() {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text('${widget.targetType.label} reported successfully'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return BlocConsumer<ReportBloc, ReportState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ReportSubmissionStatus.success) {
          _closeWithSuccess();
          return;
        }

        if (state.status == ReportSubmissionStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: semantic.surfaceBase,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: semantic.borderSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Report ${widget.targetLabel}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: semantic.textPrimary,
                    ),
                  ),
                  if (widget.targetSubtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.targetSubtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: semantic.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Help us understand what is wrong so we can review it.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reason',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: semantic.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _reasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedReason = reason;
                          });
                        },
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? semantic.textInverse
                              : semantic.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: primaryColor,
                        backgroundColor: semantic.backgroundSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(color: semantic.borderSubtle),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'Additional details',
                      hintText: 'Add context to help the review team...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: semantic.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: semantic.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: semantic.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: primaryColor,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isSubmitting || _selectedReason == null
                          ? null
                          : _submitReport,
                      icon: state.isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  semantic.textInverse,
                                ),
                              ),
                            )
                          : const FaIcon(FontAwesomeIcons.flag, size: 16),
                      label: Text(
                        state.isSubmitting ? 'Submitting...' : 'Submit report',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}