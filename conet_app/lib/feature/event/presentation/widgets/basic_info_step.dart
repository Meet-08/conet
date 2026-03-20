import 'dart:io';

import 'package:conet_app/feature/event/presentation/constants/event_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class BasicInfoStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;

  const BasicInfoStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  PlatformFile? _pickedImage;

  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final image = result?.files.first;
    if (image == null) return;
    setState(() => _pickedImage = image);
    _update({'event_image_file': image});
  }

  List<Map<String, dynamic>> get _activities => List<Map<String, dynamic>>.from(
    widget.formData['activities'] as List? ?? [],
  );

  Future<void> _openScheduleEditor({int? index}) async {
    final isEdit = index != null;
    final current = isEdit ? _activities[index] : <String, dynamic>{};

    TimeOfDay? selectedTime = current['activity_time'] as TimeOfDay?;
    final titleController = TextEditingController(
      text: (current['activity_title'] as String?) ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (context, setInnerState) => AlertDialog(
            title: Text(isEdit ? 'Edit Schedule' : 'Add Schedule'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setInnerState(() => selectedTime = picked);
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.clock, size: 14),
                        label: Text(selectedTime?.format(ctx) ?? 'Select time'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: titleController,
                          decoration: _inputDecoration(hint: 'Title'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time and title are required.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedTime == null ||
                      titleController.text.trim().isEmpty) {
                    return;
                  }
                  final list = _activities;
                  final item = <String, dynamic>{
                    'activity_time': selectedTime,
                    'activity_title': titleController.text.trim(),
                  };
                  if (isEdit) {
                    list[index] = item;
                  } else {
                    list.add(item);
                  }
                  _update({'activities': list});
                  context.pop(true);
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      setState(() {});
    }
  }

  void _deleteSchedule(int index) {
    final list = _activities..removeAt(index);
    _update({'activities': list});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCategory = widget.formData['category'] as String? ?? '';
    final selectedImage =
        _pickedImage ?? widget.formData['event_image_file'] as PlatformFile?;
    final isOnline = widget.formData['location_type'] == 'ONLINE';
    final activities = _activities;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: FontAwesomeIcons.calendarCheck,
            title: 'Event Identity',
          ),
          const SizedBox(height: 14),
          const _LabelText(text: 'Event Logo / Header Image'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UploadImageCard(image: selectedImage, onTap: _pickImage),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload an event logo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PNG, JPG or WEBP (max. 5 MB) and square format recommended.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _LabelText(text: 'Event Title'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.formData['title'] as String? ?? '',
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(hint: 'e.g. Global AI Hackathon 2024'),
            onChanged: (v) => _update({'title': v}),
          ),
          const SizedBox(height: 4),
          const _LabelText(text: 'Event Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory.isEmpty ? null : selectedCategory,
            decoration: _inputDecoration(hint: 'Select a category'),
            icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
            items: eventCategories
                .map(
                  (cat) => DropdownMenuItem<String>(
                    value: cat.value,
                    child: Text(cat.label),
                  ),
                )
                .toList(),
            onChanged: (v) => _update({'category': v ?? ''}),
          ),

          const SizedBox(height: 26),

          const _SectionTitle(
            icon: FontAwesomeIcons.fileLines,
            title: 'About Event',
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      _ToolbarAction(label: 'B', onTap: () {}, isStrong: true),
                      _ToolbarAction(label: 'I', onTap: () {}, isItalic: true),
                      _ToolbarAction(
                        label: 'U',
                        onTap: () {},
                        isUnderlined: true,
                      ),
                      _ToolbarIcon(icon: FontAwesomeIcons.listUl, onTap: () {}),
                      _ToolbarIcon(icon: FontAwesomeIcons.listOl, onTap: () {}),
                      _ToolbarIcon(icon: FontAwesomeIcons.link, onTap: () {}),
                    ],
                  ),
                ),
                TextFormField(
                  initialValue: widget.formData['about'] as String? ?? '',
                  onChanged: (v) => _update({'about': v}),
                  maxLength: 1200,
                  minLines: 6,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText:
                        'What is this event about? Mention key highlights...',
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Describe the event, goals, agenda, and why people should attend.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 26),

          const _SectionTitle(
            icon: FontAwesomeIcons.gears,
            title: 'Eligibility',
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.formData['eligibility'] as String? ?? '',
            onChanged: (v) => _update({'eligibility': v}),
            minLines: 2,
            maxLines: 2,
            decoration: _inputDecoration(
              hint: 'e.g. Open to all university students worldwide',
            ),
          ),

          const SizedBox(height: 28),

          const _SectionTitle(
            icon: FontAwesomeIcons.calendarDays,
            title: 'Event Date & Time',
          ),
          const SizedBox(height: 12),
          const _LabelText(text: 'Date'),
          const SizedBox(height: 8),
          _DatePickerField(
            value: widget.formData['event_date'] as DateTime?,
            onChanged: (d) => _update({'event_date': d}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LabelText(text: 'Start Time'),
                    const SizedBox(height: 8),
                    _TimePickerField(
                      value: widget.formData['start_time'] as TimeOfDay?,
                      onChanged: (t) => _update({'start_time': t}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LabelText(text: 'End Time'),
                    const SizedBox(height: 8),
                    _TimePickerField(
                      value: widget.formData['end_time'] as TimeOfDay?,
                      onChanged: (t) => _update({'end_time': t}),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              const _SectionTitle(
                icon: FontAwesomeIcons.stopwatch,
                title: 'Event Schedule',
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _openScheduleEditor(),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 13),
                label: const Text('Schedule'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            Text(
              'No schedule added yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...List.generate(activities.length, (index) {
              final item = activities[index];
              final tod = item['activity_time'] as TimeOfDay?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 88,
                            child: Text(
                              tod?.format(context).toUpperCase() ?? '--:--',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (item['activity_title'] as String? ?? '')
                                      .trim()
                                      .isEmpty
                                  ? 'Untitled schedule item'
                                  : (item['activity_title'] as String).trim(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 14,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openScheduleEditor(index: index);
                        } else {
                          _deleteSchedule(index);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),

          const _SectionTitle(
            icon: FontAwesomeIcons.locationDot,
            title: 'Event Mode',
          ),
          const SizedBox(height: 12),
          _ModeToggle(
            isOnline: isOnline,
            onChanged: (online) {
              _update({
                'location_type': online ? 'ONLINE' : 'OFFLINE',
                if (online) 'venue_name': '',
              });
            },
          ),
          const SizedBox(height: 14),
          if (isOnline) ...[
            const _LabelText(text: 'Meeting Link'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.formData['meeting_link'] as String? ?? '',
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(
                hint: 'Paste meeting URL',
                prefixIcon: const FaIcon(FontAwesomeIcons.link, size: 15),
              ),
              onChanged: (v) => _update({'meeting_link': v}),
            ),
          ] else ...[
            const _LabelText(text: 'Location'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.formData['location'] as String? ?? '',
              decoration: _inputDecoration(
                hint: 'Search college or city',
                prefixIcon: const FaIcon(
                  FontAwesomeIcons.locationDot,
                  size: 15,
                ),
              ),
              onChanged: (v) => _update({'location': v}),
            ),
            const SizedBox(height: 12),
            const _LabelText(text: 'Venue Name'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.formData['venue_name'] as String? ?? '',
              decoration: _inputDecoration(
                hint: 'e.g. Grand Plaza Convention Center',
              ),
              onChanged: (v) => _update({'venue_name': v}),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FaIcon(icon, size: 16),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;

  const _LabelText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _UploadImageCard extends StatelessWidget {
  final PlatformFile? image;
  final VoidCallback onTap;

  const _UploadImageCard({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surfaceContainerHigh,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: kIsWeb && image!.bytes != null
                    ? Image.memory(image!.bytes!, fit: BoxFit.cover)
                    : Image.file(File(image!.path!), fit: BoxFit.cover),
              )
            : Center(
                child: FaIcon(
                  FontAwesomeIcons.cloudArrowUp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isStrong;
  final bool isItalic;
  final bool isUnderlined;

  const _ToolbarAction({
    required this.label,
    required this.onTap,
    this.isStrong = false,
    this.isItalic = false,
    this.isUnderlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: style),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: FaIcon(icon, size: 13),
      visualDensity: VisualDensity.compact,
      splashRadius: 16,
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isOnline, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget item({
      required bool selected,
      required String text,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: selected ? colorScheme.surface : Colors.transparent,
            ),
            child: Center(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          item(
            selected: !isOnline,
            text: 'Offline',
            onTap: () => onChanged(false),
          ),
          item(
            selected: isOnline,
            text: 'Online',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: Colors.grey.shade100,
    prefixIcon: prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: prefixIcon,
          )
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade500),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'dd/mm/yyyy'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365 * 3)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(
          hint: 'dd/mm/yyyy',
          prefixIcon: const FaIcon(FontAwesomeIcons.calendar, size: 15),
        ),
        child: Text(display),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final display = value?.format(context) ?? '--:--';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(
          hint: '--:--',
          prefixIcon: const FaIcon(FontAwesomeIcons.clock, size: 15),
        ),
        child: Text(display),
      ),
    );
  }
}
