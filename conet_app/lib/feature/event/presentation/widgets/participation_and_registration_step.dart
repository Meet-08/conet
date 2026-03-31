import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ParticipationAndRegistrationStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;

  const ParticipationAndRegistrationStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  State<ParticipationAndRegistrationStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<ParticipationAndRegistrationStep> {
  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  Future<void> _selectRegistrationDeadline() async {
    final currentDeadline =
        widget.formData['registration_deadline'] as DateTime?;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentDeadline != null
          ? TimeOfDay.fromDateTime(currentDeadline)
          : const TimeOfDay(hour: 23, minute: 59),
    );

    if (selectedTime == null) return;

    final deadline = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    _update({'registration_deadline': deadline});
  }

  String _formatRegistrationDeadline(DateTime? deadline) {
    if (deadline == null) return '';
    final date =
        '${deadline.month.toString().padLeft(2, '0')}/'
        '${deadline.day.toString().padLeft(2, '0')}/'
        '${deadline.year}';
    final time =
        '${deadline.hour.toString().padLeft(2, '0')}:'
        '${deadline.minute.toString().padLeft(2, '0')}';
    return '$date -- $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaid = widget.formData['ticket_price_type'] == 'PAID';
    final participationType =
        widget.formData['participation_type'] as String? ?? 'INDIVIDUAL';
    final isTeam = participationType == 'TEAM';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.stepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.stepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // ═══ Registration Deadline ═══
          const _FieldLabel('Registration Deadline'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selectRegistrationDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatRegistrationDeadline(
                        widget.formData['registration_deadline'] as DateTime?,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: widget.formData['registration_deadline'] != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ═══ Participation Type ═══
          const _FieldLabel('Participation Type'),
          const SizedBox(height: 10),
          _ToggleRow(
            options: const ['Individual', 'Team'],
            selected: isTeam ? 'Team' : 'Individual',
            onChanged: (v) {
              _update({
                'participation_type': v == 'Team' ? 'TEAM' : 'INDIVIDUAL',
              });
            },
          ),

          // ═══ Team Size Fields (if Team selected) ═══
          if (isTeam) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Min Team Size'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            widget.formData['min_team_size']?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          hint: 'e.g. 2',
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.userGroup,
                            size: 15,
                          ),
                        ),
                        onChanged: (v) => _update({
                          'min_team_size': v.isEmpty ? null : int.tryParse(v),
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Max Team Size'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            widget.formData['max_team_size']?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          hint: 'e.g. 5',
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.userGroup,
                            size: 15,
                          ),
                        ),
                        onChanged: (v) => _update({
                          'max_team_size': v.isEmpty ? null : int.tryParse(v),
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ═══ Max Participants ═══
          const _FieldLabel('Max Participants'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.formData['max_participant']?.toString() ?? '',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              hint: 'No limit (optional)',
              prefixIcon: const FaIcon(FontAwesomeIcons.userGroup, size: 15),
            ),
            onChanged: (v) => _update({
              'max_participant': v.isEmpty ? null : int.tryParse(v),
            }),
          ),

          const SizedBox(height: 24),

          // ═══ Event Price ═══
          const _FieldLabel('Event Price'),
          const SizedBox(height: 10),
          Row(
            children: ['Free', 'Paid'].map((opt) {
              final isSelected = (isPaid ? 'Paid' : 'Free') == opt;
              final isFirst = opt == 'Free';
              final isPaidOption = opt == 'Paid';
              return Expanded(
                child: GestureDetector(
                  onTap: isPaidOption
                      ? () {
                          AppToast.showInfo(
                            context,
                            'This feature is coming in future',
                          );
                        }
                      : () {
                          _update({'ticket_price_type': 'FREE', 'price': null});
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: isFirst ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isPaidOption
                          ? colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.5,
                            )
                          : (isSelected
                                ? colorScheme.onSurface
                                : colorScheme.surfaceContainerHigh),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isPaidOption
                              ? colorScheme.onSurfaceVariant
                              : (isSelected
                                    ? colorScheme.surface
                                    : colorScheme.onSurface),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        final isFirst = opt == options.first;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: isFirst ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.surfaceContainerHigh,
                borderRadius: AppRadius.mdAll,
              ),
              child: Center(
                child: Text(
                  opt,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.surface
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: prefixIcon,
          )
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    filled: true,
    border: const OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
