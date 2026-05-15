import 'dart:convert';
import 'dart:io';

import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:conet_app/feature/event/presentation/constants/event_constants.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BasicInfoStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;
  final bool lockImage;
  final bool lockImmutableFields;

  const BasicInfoStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
    this.lockImage = false,
    this.lockImmutableFields = false,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  PlatformFile? _pickedImage;
  late QuillController _aboutController;
  late final FocusNode _aboutFocusNode;
  late final ScrollController _aboutScrollController;
  late final TextEditingController _scheduleTitleController;
  late final TextEditingController _scheduleDescriptionController;
  late final TextEditingController _titleController;
  late final TextEditingController _meetingLinkController;
  late final TextEditingController _venueController;
  late final TextEditingController _locationController;
  late final TextEditingController _eligibilityController;
  TimeOfDay? _scheduleTime;
  int? _scheduleEditingIndex;
  bool _showScheduleEditor = false;
  String _lastSerializedAbout = '';

  String _serializedAbout() {
    return jsonEncode({'ops': _aboutController.document.toDelta().toJson()});
  }

  QuillController _buildAboutController(String raw) {
    final document = () {
      try {
        return quillDocumentFromString(raw);
      } catch (_) {
        return Document();
      }
    }();
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _onAboutChanged() {
    final serialized = _serializedAbout();
    if (serialized == _lastSerializedAbout) return;
    _lastSerializedAbout = serialized;
    _update({'about': serialized});
  }

  @override
  void initState() {
    super.initState();
    _aboutFocusNode = FocusNode();
    _aboutScrollController = ScrollController();
    _scheduleTitleController = TextEditingController();
    _scheduleDescriptionController = TextEditingController();
    _titleController = TextEditingController(
      text: widget.formData['title'] as String? ?? '',
    );
    _meetingLinkController = TextEditingController(
      text: widget.formData['meeting_link'] as String? ?? '',
    );
    _venueController = TextEditingController(
      text: widget.formData['venue_name'] as String? ?? '',
    );
    _locationController = TextEditingController(
      text: widget.formData['location'] as String? ?? '',
    );
    _eligibilityController = TextEditingController(
      text: widget.formData['eligibility'] as String? ?? '',
    );
    _aboutController = _buildAboutController(
      widget.formData['about'] as String? ?? '',
    );
    _lastSerializedAbout = _serializedAbout();
    _aboutController.addListener(_onAboutChanged);

    if ((widget.formData['about'] as String? ?? '').isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _update({'about': _serializedAbout()});
      });
    }
  }

  @override
  void didUpdateWidget(covariant BasicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    void syncController(TextEditingController controller, String next) {
      if (controller.text != next) {
        controller.text = next;
      }
    }

    syncController(_titleController, widget.formData['title'] as String? ?? '');
    syncController(
      _meetingLinkController,
      widget.formData['meeting_link'] as String? ?? '',
    );
    syncController(_venueController, widget.formData['venue_name'] as String? ?? '');
    syncController(
      _locationController,
      widget.formData['location'] as String? ?? '',
    );
    syncController(
      _eligibilityController,
      widget.formData['eligibility'] as String? ?? '',
    );

    final incoming = widget.formData['about'] as String? ?? '';
    final current = _serializedAbout();
    if (incoming.isNotEmpty && incoming != current) {
      _aboutController
        ..removeListener(_onAboutChanged)
        ..dispose();
      _aboutController = _buildAboutController(incoming);
      _lastSerializedAbout = _serializedAbout();
      _aboutController.addListener(_onAboutChanged);
    }
  }

  @override
  void dispose() {
    _aboutController
      ..removeListener(_onAboutChanged)
      ..dispose();
    _scheduleTitleController.dispose();
    _scheduleDescriptionController.dispose();
    _titleController.dispose();
    _meetingLinkController.dispose();
    _venueController.dispose();
    _locationController.dispose();
    _eligibilityController.dispose();
    _aboutFocusNode.dispose();
    _aboutScrollController.dispose();
    super.dispose();
  }

  void _toggleInlineStyle(Attribute attribute) {
    final style = _aboutController.getSelectionStyle();
    if (style.attributes.containsKey(attribute.key)) {
      _aboutController.formatSelection(Attribute.clone(attribute, null));
      return;
    }
    _aboutController.formatSelection(attribute);
  }

  void _toggleList(Attribute listAttribute) {
    final style = _aboutController.getSelectionStyle();
    final currentList = style.attributes[Attribute.list.key];
    if (currentList?.value == listAttribute.value) {
      _aboutController.formatSelection(Attribute.clone(listAttribute, null));
      return;
    }
    _aboutController.formatSelection(listAttribute);
  }

  Future<void> _setLink() async {
    String linkValue = '';
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Link'),
        content: TextField(
          keyboardType: TextInputType.url,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (value) => linkValue = value,
          onSubmitted: (value) => ctx.pop(value.trim()),
          decoration: _inputDecoration(ctx, hint: 'https://example.com'),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => ctx.pop(linkValue.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (url == null || url.isEmpty) return;

    final normalizedUrl = _normalizeLinkUrl(url);
    final selection = _aboutController.selection;
    final selectedLength = selection.end - selection.start;

    if (selectedLength > 0) {
      _aboutController.formatSelection(LinkAttribute(normalizedUrl));
      return;
    }

    final insertAt = selection.start;
    _aboutController.replaceText(
      insertAt,
      0,
      normalizedUrl,
      TextSelection.collapsed(offset: insertAt + normalizedUrl.length),
    );
    _aboutController.formatText(
      insertAt,
      normalizedUrl.length,
      LinkAttribute(normalizedUrl),
    );
  }

  String _normalizeLinkUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final hasScheme =
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('mailto:') ||
        trimmed.startsWith('tel:');

    return hasScheme ? trimmed : 'https://$trimmed';
  }

  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  Future<void> _pickImage() async {
    if (widget.lockImage) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      final image = result?.files.first;
      if (image == null) return;
      setState(() => _pickedImage = image);
      _update({'event_image_file': image});
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, 'Unable to open image picker');
    }
  }

  List<Map<String, dynamic>> get _activities => List<Map<String, dynamic>>.from(
    widget.formData['activities'] as List? ?? [],
  );

  void _startScheduleEditor({int? index}) {
    final current = index == null ? <String, dynamic>{} : _activities[index];
    setState(() {
      _scheduleEditingIndex = index;
      _scheduleTime = current['activity_time'] as TimeOfDay?;
      _scheduleTitleController.text =
          (current['activity_title'] as String?) ?? '';
      _scheduleDescriptionController.text =
          (current['description'] as String?) ?? '';
      _showScheduleEditor = true;
    });
  }

  void _cancelScheduleEditor() {
    setState(() {
      _showScheduleEditor = false;
      _scheduleEditingIndex = null;
      _scheduleTime = null;
      _scheduleTitleController.clear();
      _scheduleDescriptionController.clear();
    });
  }

  void _saveScheduleEditor() {
    if (_scheduleTime == null || _scheduleTitleController.text.trim().isEmpty) {
      AppToast.showWarning(context, 'Time and title are required');
      return;
    }

    final list = _activities;
    final item = <String, dynamic>{
      'activity_time': _scheduleTime,
      'activity_title': _scheduleTitleController.text.trim(),
      'description': _scheduleDescriptionController.text.trim(),
    };

    if (_scheduleEditingIndex != null) {
      list[_scheduleEditingIndex!] = item;
    } else {
      list.add(item);
    }

    _update({'activities': list});
    _cancelScheduleEditor();
  }

  void _deleteSchedule(int index) {
    final list = _activities..removeAt(index);
    _update({'activities': list});
    if (_scheduleEditingIndex == index) {
      _cancelScheduleEditor();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final selectedCategory = widget.formData['category'] as String? ?? '';
    final selectedImage =
        _pickedImage ?? widget.formData['event_image_file'] as PlatformFile?;
    final existingImageUrl = widget.formData['event_image_url'] as String?;
    final isOnline = widget.formData['location_type'] == 'ONLINE';
    final activities = _activities;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s24,
        AppSpace.s16,
        AppSpace.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: FontAwesomeIcons.calendar,
            title: 'Basic Info',
          ),
          const SizedBox(height: AppSpace.s24),
          const _LabelText(text: 'Logo'),
          const SizedBox(height: AppSpace.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UploadImageCard(
                image: selectedImage,
                existingImageUrl: existingImageUrl,
                onTap: _pickImage,
                isLocked: widget.lockImage,
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lockImage ? 'Event logo is locked for draft setup' : 'Upload an event logo',
                        style: AppTextStyles.label.copyWith(
                          color: semantic.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        'PNG, JPG or WEBP (max. 5 MB) and square format recommended.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: semantic.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          const _LabelText(text: 'Title'),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            controller: _titleController,
            readOnly: widget.lockImmutableFields,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              context,
              hint: 'e.g. Global AI Hackathon 2024',
            ),
            onChanged: (v) => _update({'title': v}),
          ),
          const SizedBox(height: AppSpace.s8),
          const _LabelText(text: 'Category'),
          const SizedBox(height: AppSpace.s8),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory.isEmpty ? null : selectedCategory,
            decoration: _inputDecoration(context, hint: 'Select a category'),
            icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
            items: eventCategories
                .map(
                  (cat) => DropdownMenuItem<String>(
                    value: cat.value,
                    child: Text(cat.label),
                  ),
                )
                .toList(),
            onChanged: widget.lockImmutableFields
                ? null
                : (v) => _update({'category': v ?? ''}),
          ),
          const SizedBox(height: AppSpace.s32),

          const _SectionTitle(
            icon: FontAwesomeIcons.calendarDays,
            title: 'Date & Time',
          ),
          const SizedBox(height: AppSpace.s16),
          const _LabelText(text: 'Start Date'),
          const SizedBox(height: AppSpace.s8),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  value: widget.formData['start_date'] as DateTime?,
                  enabled: !widget.lockImmutableFields,
                  onChanged: (d) {
                    final endDate = widget.formData['end_date'] as DateTime?;
                    _update({
                      'start_date': d,
                      if (endDate == null || endDate.isBefore(d)) 'end_date': d,
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: _TimePickerField(
                  value: widget.formData['start_time'] as TimeOfDay?,
                  enabled: !widget.lockImmutableFields,
                  onChanged: (t) => _update({'start_time': t}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          const _LabelText(text: 'End'),
          const SizedBox(height: AppSpace.s8),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  value: widget.formData['end_date'] as DateTime?,
                  firstDate:
                      (widget.formData['start_date'] as DateTime?) ??
                      DateTime.now(),
                  enabled: !widget.lockImmutableFields,
                  onChanged: (d) => _update({'end_date': d}),
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: _TimePickerField(
                  value: widget.formData['end_time'] as TimeOfDay?,
                  enabled: !widget.lockImmutableFields,
                  onChanged: (t) => _update({'end_time': t}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s32),

          const _SectionTitle(
            icon: FontAwesomeIcons.mapLocationDot,
            title: 'Location',
          ),
          const SizedBox(height: AppSpace.s16),
          _ModeToggle(
            isOnline: isOnline,
            enabled: !widget.lockImmutableFields,
            onChanged: (online) {
              _update({
                'location_type': online ? 'ONLINE' : 'OFFLINE',
                if (online) 'venue_name': '',
              });
            },
          ),
          const SizedBox(height: AppSpace.s16),
          if (isOnline) ...[
            const _LabelText(text: 'Meeting Link'),
            const SizedBox(height: AppSpace.s8),
            TextFormField(
              controller: _meetingLinkController,
              readOnly: widget.lockImmutableFields,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(
                context,
                hint: 'Paste meeting URL',
                prefixIcon: Icon(
                  PhosphorIconsRegular.link,
                  size: 18,
                  color: semantic.iconTertiary,
                ),
              ),
              onChanged: (v) => _update({'meeting_link': v}),
            ),
          ] else ...[
            const _LabelText(text: 'Venue'),
            const SizedBox(height: AppSpace.s8),
            TextFormField(
              controller: _venueController,
              readOnly: widget.lockImmutableFields,
              decoration: _inputDecoration(
                context,
                hint: 'e.g. A-block Auditorium',
              ),
              onChanged: (v) => _update({'venue_name': v}),
            ),
            const SizedBox(height: AppSpace.s16),
            const _LabelText(text: 'Address'),
            const SizedBox(height: AppSpace.s8),
            TextFormField(
              controller: _locationController,
              readOnly: widget.lockImmutableFields,
              decoration: _inputDecoration(
                context,
                hint: 'e.g. VGEC, Chandkheda',
                prefixIcon: Icon(
                  PhosphorIconsRegular.mapPin,
                  size: 18,
                  color: semantic.iconTertiary,
                ),
              ),
              onChanged: (v) => _update({'location': v}),
            ),
          ],
          const SizedBox(height: AppSpace.s32),

          const _SectionTitle(icon: FontAwesomeIcons.fileLines, title: 'About'),
          const SizedBox(height: AppSpace.s16),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: semantic.borderDefault),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s6,
                    vertical: AppSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: semantic.surfaceOverlay,
                    border: Border(
                      bottom: BorderSide(color: semantic.borderDefault),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _aboutController,
                    builder: (context, _) {
                      final style = _aboutController.getSelectionStyle();
                      final listAttr = style.attributes[Attribute.list.key];
                      return Row(
                        children: [
                          _ToolbarAction(
                            label: 'B',
                            onTap: () => _toggleInlineStyle(Attribute.bold),
                            isStrong: true,
                            isActive: style.attributes.containsKey(
                              Attribute.bold.key,
                            ),
                          ),
                          _ToolbarAction(
                            label: 'I',
                            onTap: () => _toggleInlineStyle(Attribute.italic),
                            isItalic: true,
                            isActive: style.attributes.containsKey(
                              Attribute.italic.key,
                            ),
                          ),
                          _ToolbarAction(
                            label: 'U',
                            onTap: () =>
                                _toggleInlineStyle(Attribute.underline),
                            isUnderlined: true,
                            isActive: style.attributes.containsKey(
                              Attribute.underline.key,
                            ),
                          ),
                          _ToolbarIcon(
                            icon: FontAwesomeIcons.listUl,
                            onTap: () => _toggleList(Attribute.ul),
                            isActive: listAttr?.value == Attribute.ul.value,
                          ),
                          _ToolbarIcon(
                            icon: FontAwesomeIcons.listOl,
                            onTap: () => _toggleList(Attribute.ol),
                            isActive: listAttr?.value == Attribute.ol.value,
                          ),
                          _ToolbarIcon(
                            icon: FontAwesomeIcons.link,
                            onTap: _setLink,
                            isActive: style.attributes.containsKey(
                              Attribute.link.key,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                QuillEditor.basic(
                  controller: _aboutController,
                  focusNode: _aboutFocusNode,
                  scrollController: _aboutScrollController,
                  config: const QuillEditorConfig(
                    minHeight: 140,
                    maxHeight: 220,
                    placeholder:
                        'What is this event about? Mention key highlights...',
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Describe the event, goals, agenda, and why people should attend.',
            style: AppTextStyles.bodySmall.copyWith(
              color: semantic.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.s24),

          const _SectionTitle(
            icon: FontAwesomeIcons.userCheck,
            title: 'Eligibility',
          ),
          const SizedBox(height: AppSpace.s16),
          TextFormField(
            controller: _eligibilityController,
            readOnly: widget.lockImmutableFields,
            onChanged: (v) => _update({'eligibility': v}),
            minLines: 2,
            maxLines: 2,
            decoration: _inputDecoration(
              context,
              hint: 'e.g. Open to all university students worldwide',
            ),
          ),
          const SizedBox(height: AppSpace.s24),

          const _SectionTitle(
            icon: FontAwesomeIcons.calendarCheck,
            title: 'Schedule',
          ),
          const SizedBox(height: AppSpace.s16),
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final tod = item['activity_time'] as TimeOfDay?;
            final title = (item['activity_title'] as String? ?? '').trim();
            final description = (item['description'] as String? ?? '').trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: InkWell(
                onTap: () => _startScheduleEditor(index: index),
                borderRadius: AppRadius.mdAll,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.s12),
                  decoration: BoxDecoration(
                    color: semantic.surfaceRaised,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tod?.format(context).toUpperCase() ?? '--:--',
                            style: AppTextStyles.caption.copyWith(
                              color: semantic.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _deleteSchedule(index),
                            icon: FaIcon(
                              FontAwesomeIcons.xmark,
                              size: 14,
                              color: semantic.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        title.isEmpty ? 'Untitled schedule item' : title,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: semantic.textPrimary,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          description,
                          style: AppTextStyles.bodyDefault.copyWith(
                            color: semantic.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_showScheduleEditor)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpace.s12),
              padding: const EdgeInsets.all(AppSpace.s16),
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: FontAwesomeIcons.calendarCheck,
                    title: 'Schedule',
                  ),
                  const SizedBox(height: AppSpace.s16),
                  const _LabelText(text: 'Time'),
                  const SizedBox(height: AppSpace.s8),
                  _TimePickerField(
                    value: _scheduleTime,
                    onChanged: (value) => setState(() => _scheduleTime = value),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  const _LabelText(text: 'Title'),
                  const SizedBox(height: AppSpace.s8),
                  TextFormField(
                    controller: _scheduleTitleController,
                    decoration: _inputDecoration(
                      context,
                      hint: 'Opening Keynote',
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  const _LabelText(text: 'Description'),
                  const SizedBox(height: AppSpace.s8),
                  TextFormField(
                    controller: _scheduleDescriptionController,
                    minLines: 2,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      context,
                      hint:
                          'Future of AI in Sustainable Energy by Dr. Rajesh Kumar',
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelScheduleEditor,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveScheduleEditor,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.s12,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.mdAll,
                            ),
                          ),
                          child: Text(
                            _scheduleEditingIndex == null ? 'Add' : 'Save',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: AppRadius.md,
              dashPattern: const [6, 4],
              strokeWidth: 1.2,
              color: semantic.borderDefault,
            ),
            child: InkWell(
              onTap: () => _startScheduleEditor(),
              borderRadius: AppRadius.mdAll,
              child: Container(
                width: double.infinity,
                height: AppSpace.s48,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.plus,
                      size: 14,
                      color: semantic.textPrimary,
                    ),
                    const SizedBox(width: AppSpace.s8),
                    Text(
                      'Schedule',
                      style: AppTextStyles.button.copyWith(
                        color: semantic.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s12),
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
    final semantic = context.semanticColors;
    return Row(
      children: [
        FaIcon(icon, size: 16, color: semantic.iconPrimary),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.headingH3.copyWith(
            fontWeight: FontWeight.w800,
            color: semantic.textPrimary,
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
    final semantic = context.semanticColors;
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w700,
        color: semantic.textPrimary,
      ),
    );
  }
}

class _UploadImageCard extends StatelessWidget {
  final PlatformFile? image;
  final String? existingImageUrl;
  final VoidCallback onTap;
  final bool isLocked;

  const _UploadImageCard({
    required this.image,
    required this.onTap,
    this.existingImageUrl,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: AppRadius.mdAll,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: AppRadius.md,
          dashPattern: const [6, 4],
          strokeWidth: 1.2,
          color: semantic.borderDefault,
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: 110,
          height: 110,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            color: semantic.surfaceRaised,
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: kIsWeb && image!.bytes != null
                      ? Image.memory(image!.bytes!, fit: BoxFit.cover)
                      : Image.file(File(image!.path!), fit: BoxFit.cover),
                )
              : (existingImageUrl != null && existingImageUrl!.trim().isNotEmpty)
              ? Image.network(
                  existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: FaIcon(
                      FontAwesomeIcons.cloudArrowUp,
                      color: semantic.iconTertiary,
                    ),
                  ),
                )
              : Center(
                  child: FaIcon(
                    FontAwesomeIcons.cloudArrowUp,
                    color: semantic.iconTertiary,
                  ),
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
  final bool isActive;

  const _ToolbarAction({
    required this.label,
    required this.onTap,
    this.isStrong = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final style = AppTextStyles.button.copyWith(
      fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
      color: isActive ? semantic.textOnBrand : semantic.textPrimary,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xsAll,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.xsAll,
          color: isActive ? semantic.backgroundBrand : Colors.transparent,
        ),
        child: Text(label, style: style),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarIcon({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xsAll,
        color: isActive ? semantic.backgroundBrand : Colors.transparent,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: FaIcon(
          icon,
          size: 13,
          color: isActive ? semantic.iconOnBrand : semantic.iconPrimary,
        ),
        visualDensity: VisualDensity.compact,
        splashRadius: 16,
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isOnline;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.isOnline,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    Widget item({
      required bool selected,
      required String text,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.smAll,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadius.smAll,
              color: selected ? semantic.surfaceBase : Colors.transparent,
            ),
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? semantic.textPrimary
                      : semantic.textTertiary,
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
        color: semantic.surfaceOverlay,
        borderRadius: AppRadius.mdAll,
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

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  Widget? prefixIcon,
}) {
  final semantic = context.semanticColors;
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyDefault.copyWith(color: semantic.textTertiary),
    counterText: '',
    filled: true,
    fillColor: semantic.surfaceRaised,
    prefixIcon: prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(
              left: AppSpace.s12,
              right: AppSpace.s10,
            ),
            child: prefixIcon,
          )
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 52),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.s12,
      vertical: AppSpace.s12,
    ),
    border: OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: semantic.borderDefault),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: semantic.borderDefault),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: semantic.borderBrand, width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: semantic.borderDefault),
    ),
  );
}

class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final DateTime? firstDate;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.value,
    this.firstDate,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'dd/mm/yyyy'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return _PickerInputShell(
      valueText: display,
      placeholderText: 'dd/mm/yyyy',
      isPlaceholder: value == null,
      icon: FontAwesomeIcons.calendar,
      onTap: !enabled
          ? null
          : () async {
        final now = DateTime.now();
        final minDate = firstDate ?? now;
        final effectiveInitialDate = value != null && value!.isBefore(minDate)
            ? minDate
            : (value ?? now);
        final picked = await showDatePicker(
          context: context,
          initialDate: effectiveInitialDate,
          firstDate: minDate,
          lastDate: now.add(const Duration(days: 365 * 3)),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TimeOfDay? value;
  final bool enabled;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerField({
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = value?.format(context) ?? '--:--';

    return _PickerInputShell(
      valueText: display,
      placeholderText: '--:--',
      isPlaceholder: value == null,
      icon: FontAwesomeIcons.clock,
      onTap: !enabled
          ? null
          : () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _PickerInputShell extends StatelessWidget {
  final String valueText;
  final String placeholderText;
  final bool isPlaceholder;
  final IconData icon;
  final VoidCallback? onTap;

  const _PickerInputShell({
    required this.valueText,
    required this.placeholderText,
    required this.isPlaceholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    const enabledBorder = OutlineInputBorder(borderRadius: AppRadius.mdAll);

    return InkWell(
      borderRadius: enabledBorder.borderRadius,
      onTap: onTap,
      child: Container(
        height: AppSpace.s48 + AppSpace.s4,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: enabledBorder.borderRadius,
          border: Border.all(
            color: semantic.borderDefault,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FaIcon(icon, size: 16, color: semantic.iconTertiary),
            const SizedBox(width: AppSpace.s8),
            Expanded(
              child: Text(
                valueText,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isPlaceholder
                      ? semantic.textTertiary
                      : semantic.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
