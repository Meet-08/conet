import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/utils/app_toast.dart';
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

  List<Map<String, dynamic>> get _customFields =>
      List<Map<String, dynamic>>.from(
        widget.formData['custom_fields'] as List? ??
            const <Map<String, dynamic>>[],
      );

  Future<void> _selectRegistrationDeadline() async {
    final currentDeadline =
        widget.formData['registration_deadline'] as DateTime?;

    final eventDate = widget.formData['event_date'] as DateTime?;
    final eventStartTime = widget.formData['start_time'] as TimeOfDay?;
    final eventStartDateTime = eventDate != null && eventStartTime != null
        ? DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            eventStartTime.hour,
            eventStartTime.minute,
          )
        : null;

    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final maxDate = eventStartDateTime != null
        ? DateTime(
            eventStartDateTime.year,
            eventStartDateTime.month,
            eventStartDateTime.day,
          )
        : DateTime.now().add(const Duration(days: 365));

    final initialDateCandidate = currentDeadline ?? firstDate;
    final initialDate = initialDateCandidate.isBefore(firstDate)
        ? firstDate
        : (initialDateCandidate.isAfter(maxDate)
              ? maxDate
              : initialDateCandidate);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: maxDate,
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

    if (eventStartDateTime != null && !deadline.isBefore(eventStartDateTime)) {
      AppToast.showWarning(
        context,
        'Registration deadline must be before event start time',
      );
      return;
    }

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

  void _addCustomField() {
    final list = _customFields
      ..add({
        'label': '',
        'helper_text': '',
        'type': 'text',
        'required': false,
        'options': <String>[],
      });
    _update({'custom_fields': list});
  }

  void _removeCustomField(int index) {
    final list = _customFields..removeAt(index);
    _update({'custom_fields': list});
  }

  void _updateCustomField(int index, Map<String, dynamic> patch) {
    final list = _customFields;
    list[index] = {...list[index], ...patch};
    _update({'custom_fields': list});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaid =
        (widget.formData['ticket_price_type'] as String? ?? 'FREE') == 'PAID';
    final participationType =
        (widget.formData['participation_type'] as String? ?? 'individual')
            .toLowerCase();
    final isTeam = participationType == 'team';
    final customFields = _customFields;

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
          const _FieldLabel('Participation Type'),
          const SizedBox(height: 10),
          _ToggleRow(
            options: const ['Individual', 'Team'],
            selected: isTeam ? 'Team' : 'Individual',
            onChanged: (v) {
              final nextType = v == 'Team' ? 'team' : 'individual';
              _update({
                'participation_type': nextType,
                if (nextType == 'individual') ...{
                  'min_team_size': null,
                  'max_team_size': null,
                },
              });
            },
          ),
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
          const _FieldLabel('Event Price'),
          const SizedBox(height: 10),
          _ToggleRow(
            options: const ['Free', 'Paid'],
            selected: isPaid ? 'Paid' : 'Free',
            onChanged: (value) {
              final isPaidValue = value == 'Paid';
              _update({
                'ticket_price_type': isPaidValue ? 'PAID' : 'FREE',
                if (!isPaidValue) ...{'price': null, 'upi_id': null},
              });
            },
          ),
          if (isPaid) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.formData['price']?.toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ],
              decoration: _inputDecoration(
                hint: 'Price per member in INR',
                prefixIcon: const FaIcon(
                  FontAwesomeIcons.indianRupeeSign,
                  size: 15,
                ),
              ),
              onChanged: (value) => _update({
                'price': value.trim().isEmpty ? null : double.tryParse(value),
              }),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.formData['upi_id'] as String? ?? '',
              decoration: _inputDecoration(
                hint: 'UPI ID (e.g. name@bank)',
                prefixIcon: const FaIcon(FontAwesomeIcons.qrcode, size: 15),
              ),
              onChanged: (value) => _update({'upi_id': value.trim()}),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: _FieldLabel('Custom Registration Fields')),
              TextButton(
                onPressed: _addCustomField,
                child: const Text('+ Add'),
              ),
            ],
          ),
          if (customFields.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: AppRadius.mdAll,
              ),
              child: Text(
                'No custom fields yet. Add only what participants must fill.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...List.generate(customFields.length, (index) {
              final field = customFields[index];
              final rawFieldType = (field['type'] as String? ?? 'text')
                  .toLowerCase();
              final fieldType =
                  rawFieldType == 'single_select' ||
                      rawFieldType == 'single-select' ||
                      rawFieldType == 'singleselect' ||
                      rawFieldType == 'dropdown'
                  ? 'select'
                  : (rawFieldType == 'multiple_select' ||
                        rawFieldType == 'multiple-select' ||
                        rawFieldType == 'multiselect')
                  ? 'multi_select'
                  : rawFieldType;
              final options =
                  (field['options'] as List?)
                      ?.map((value) => value.toString().trim())
                      .where((value) => value.isNotEmpty)
                      .toList(growable: false) ??
                  const <String>[];

              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Field ${index + 1}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeCustomField(index),
                          icon: FaIcon(
                            FontAwesomeIcons.trashCan,
                            size: 14,
                            color: colorScheme.error,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: field['label'] as String? ?? '',
                      decoration: _inputDecoration(
                        hint: 'Field label (e.g. College ID)',
                        prefixIcon: const FaIcon(
                          FontAwesomeIcons.tag,
                          size: 15,
                        ),
                      ),
                      onChanged: (value) {
                        _updateCustomField(index, {'label': value});
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: field['helper_text'] as String? ?? '',
                      decoration: _inputDecoration(
                        hint: 'Helper text (optional)',
                        prefixIcon: const FaIcon(
                          FontAwesomeIcons.circleInfo,
                          size: 15,
                        ),
                      ),
                      onChanged: (value) =>
                          _updateCustomField(index, {'helper_text': value}),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: fieldType,
                      decoration: _inputDecoration(
                        hint: 'Field type',
                        prefixIcon: const FaIcon(
                          FontAwesomeIcons.listCheck,
                          size: 15,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text')),
                        DropdownMenuItem(
                          value: 'textarea',
                          child: Text('Long Text'),
                        ),
                        DropdownMenuItem(
                          value: 'number',
                          child: Text('Number'),
                        ),
                        DropdownMenuItem(
                          value: 'select',
                          child: Text('Single Select'),
                        ),
                        DropdownMenuItem(
                          value: 'multi_select',
                          child: Text('Multi Select'),
                        ),
                      ],
                      onChanged: (value) {
                        final nextType = value ?? 'text';
                        _updateCustomField(index, {
                          'type': nextType,
                          if (nextType != 'select' &&
                              nextType != 'multi_select')
                            'options': <String>[],
                        });
                      },
                    ),
                    if (fieldType == 'select' ||
                        fieldType == 'multi_select') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: options.join(', '),
                        decoration: _inputDecoration(
                          hint: fieldType == 'multi_select'
                              ? 'Multi-select options (comma separated)'
                              : 'Single-select options (comma separated)',
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.list,
                            size: 15,
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = value
                              .split(',')
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toList(growable: false);
                          _updateCustomField(index, {'options': parsed});
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Required field'),
                      value: field['required'] == true,
                      onChanged: (value) =>
                          _updateCustomField(index, {'required': value}),
                    ),
                  ],
                ),
              );
            }),
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
