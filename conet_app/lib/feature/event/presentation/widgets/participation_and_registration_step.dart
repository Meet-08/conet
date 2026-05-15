import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/payment/presentation/pages/setup_organizer_account_page.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ParticipationAndRegistrationStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;
  final bool lockToggles;
  final bool lockCustomFields;

  const ParticipationAndRegistrationStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
    this.lockToggles = false,
    this.lockCustomFields = false,
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

    final startDate = widget.formData['start_date'] as DateTime?;
    final eventStartTime = widget.formData['start_time'] as TimeOfDay?;
    final eventStartDateTime = startDate != null && eventStartTime != null
        ? DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
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

  void _addCustomField() {
    if (widget.lockCustomFields) return;
    _startEditingCustomField();
  }

  void _removeCustomField(int index) {
    if (widget.lockCustomFields) return;
    final list = _customFields..removeAt(index);
    _update({'custom_fields': list});
  }

  String _displayFieldType(String? rawType) {
    switch ((rawType ?? 'text').toLowerCase()) {
      case 'email':
        return 'Email';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'image':
        return 'Image';
      default:
        return 'Short text';
    }
  }

  Widget _buildCustomFieldImagePreview(
    BuildContext context,
    PlatformFile file,
  ) {
    if (file.bytes != null) {
      return ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Image.memory(
          file.bytes!,
          width: double.infinity,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 80,
      decoration: const BoxDecoration(borderRadius: AppRadius.mdAll),
      alignment: Alignment.center,
      child: Text(file.name, textAlign: TextAlign.center),
    );
  }

  // --- Custom field editor state and handlers ---
  final TextEditingController _cfLabelController = TextEditingController();
  final TextEditingController _cfHelperController = TextEditingController();
  final TextEditingController _cfOptionsController = TextEditingController();
  String _cfType = 'text';
  bool _cfRequired = false;
  PlatformFile? _cfImageFile;
  int? _editingCustomIndex;
  bool _showCustomEditor = false;

  void _startEditingCustomField({int? index}) {
    if (widget.lockCustomFields) return;
    final field = index == null ? null : _customFields[index];
    _editingCustomIndex = index;
    if (field == null) {
      _cfLabelController.text = '';
      _cfHelperController.text = '';
      _cfOptionsController.text = '';
      _cfType = 'text';
      _cfRequired = false;
      _cfImageFile = null;
    } else {
      _cfLabelController.text = field['label'] as String? ?? '';
      _cfHelperController.text = field['helper_text'] as String? ?? '';
      _cfType = (field['type'] as String? ?? 'text').toLowerCase();
      final options = (field['options'] as List?)?.join(', ') ?? '';
      _cfOptionsController.text = options;
      _cfRequired = field['required'] == true;
      _cfImageFile = field['image_file'] as PlatformFile?;
    }
    setState(() => _showCustomEditor = true);
  }

  void _cancelCustomEditor() {
    _editingCustomIndex = null;
    _cfImageFile = null;
    _showCustomEditor = false;
    _cfLabelController.clear();
    _cfHelperController.clear();
    _cfOptionsController.clear();
    setState(() {});
  }

  Future<void> _pickEditorImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final selected = result.files.first;
    if (selected.name.trim().isEmpty) {
      AppToast.showWarning(context, 'Invalid image selection');
      return;
    }
    setState(() => _cfImageFile = selected);
  }

  void _saveCustomEditor() {
    final label = _cfLabelController.text.trim();
    if (label.isEmpty) {
      AppToast.showWarning(context, 'Field label is required');
      return;
    }

    final parsedOptions = _cfOptionsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final item = <String, dynamic>{
      'label': label,
      'helper_text': _cfHelperController.text.trim(),
      'type': _cfType,
      'required': _cfRequired,
      'options': parsedOptions,
      'image_file': _cfImageFile,
      'image_url': null,
    };

    final list = _customFields;
    if (_editingCustomIndex != null) {
      list[_editingCustomIndex!] = item;
    } else {
      list.add(item);
    }

    _update({'custom_fields': list});
    _cancelCustomEditor();
  }

  @override
  void dispose() {
    _cfLabelController.dispose();
    _cfHelperController.dispose();
    _cfOptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isPaid =
        (widget.formData['ticket_price_type'] as String? ?? 'FREE') == 'PAID';
    final participationType =
        (widget.formData['participation_type'] as String? ?? 'individual')
            .toLowerCase();
    final isTeam = participationType == 'team';
    final customFields = _customFields;

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
          Text(
            widget.stepTitle,
            style: AppTextStyles.headingH2.copyWith(
              fontWeight: FontWeight.w800,
              color: semantic.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            widget.stepSubtitle,
            style: AppTextStyles.bodyDefault.copyWith(
              color: semantic.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          // ── Registration Ends Section ──
          const _SectionTitle(
            icon: FontAwesomeIcons.calendarCheck,
            title: 'Registration',
          ),
          const SizedBox(height: AppSpace.s16),
          const _LabelText(text: 'Registration Deadline'),
          const SizedBox(height: AppSpace.s8),
          _RegistrationDeadlineField(
            value: widget.formData['registration_deadline'] as DateTime?,
            onTap: widget.lockToggles ? null : _selectRegistrationDeadline,
          ),
          const SizedBox(height: AppSpace.s24),
          // ── Participation Type Section ──
          const _LabelText(text: 'Participation Type'),
          const SizedBox(height: AppSpace.s8),
          _ToggleRow(
            options: const ['Individual', 'Team'],
            selected: isTeam ? 'Team' : 'Individual',
            enabled: !widget.lockToggles,
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
            const SizedBox(height: AppSpace.s24),
            const _LabelText(text: 'Team Size'),
            const SizedBox(height: AppSpace.s8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum',
                        style: AppTextStyles.caption.copyWith(
                          color: semantic.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      TextFormField(
                        initialValue:
                            widget.formData['min_team_size']?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          context,
                          hint: '2',
                          prefixIcon: Icon(
                            FontAwesomeIcons.userGroup,
                            size: 15,
                            color: semantic.iconTertiary,
                          ),
                        ),
                        onChanged: (v) => _update({
                          'min_team_size': v.isEmpty ? null : int.tryParse(v),
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum',
                        style: AppTextStyles.caption.copyWith(
                          color: semantic.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      TextFormField(
                        initialValue:
                            widget.formData['max_team_size']?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          context,
                          hint: '5',
                          prefixIcon: Icon(
                            FontAwesomeIcons.userGroup,
                            size: 15,
                            color: semantic.iconTertiary,
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
          const SizedBox(height: AppSpace.s24),
          // ── Registration Limit Section ──
          const _LabelText(text: 'Participant Limit'),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            initialValue: widget.formData['max_participant']?.toString() ?? '',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              context,
              hint: 'No limit (optional)',
              prefixIcon: Icon(
                FontAwesomeIcons.userGroup,
                size: 15,
                color: semantic.iconTertiary,
              ),
            ),
            onChanged: (v) => _update({
              'max_participant': v.isEmpty ? null : int.tryParse(v),
            }),
          ),
          const SizedBox(height: AppSpace.s24),
          // ── Ticket Pricing Section ──
          const _SectionTitle(icon: FontAwesomeIcons.ticket, title: 'Pricing'),
          const SizedBox(height: AppSpace.s16),
          const _LabelText(text: 'Ticket Type'),
          const SizedBox(height: AppSpace.s8),
          _ToggleRow(
            options: const ['Free', 'Paid'],
            selected: isPaid ? 'Paid' : 'Free',
            enabled: !widget.lockToggles,
            onChanged: (value) {
              final isPaidValue = value == 'Paid';
              _update({
                'ticket_price_type': isPaidValue ? 'PAID' : 'FREE',
                if (!isPaidValue) ...{'price': null},
              });
            },
          ),
          if (isPaid) ...[
            const SizedBox(height: AppSpace.s12),
            const _LabelText(text: 'Price per Person'),
            const SizedBox(height: AppSpace.s8),
            TextFormField(
              initialValue: widget.formData['price']?.toString(),
              readOnly: widget.lockToggles,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ],
              decoration: _inputDecoration(
                context,
                hint: 'In INR',
                prefixIcon: Icon(
                  FontAwesomeIcons.indianRupeeSign,
                  size: 15,
                  color: semantic.iconTertiary,
                ),
              ),
              onChanged: (value) => _update({
                'price': value.trim().isEmpty ? null : double.tryParse(value),
              }),
            ),
            const SizedBox(height: AppSpace.s16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.s12),
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Razorpay payout account details are required to receive payments.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: semantic.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SetupOrganizerAccountPage(),
                        ),
                      );
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.buildingColumns,
                      size: 14,
                      color: semantic.textOnBrand,
                    ),
                    label: const Text('Setup Razorpay Account'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.s24),
          // ── Registration Form Section ──
          const _SectionTitle(
            icon: FontAwesomeIcons.fileLines,
            title: 'Registration Form',
          ),
          const SizedBox(height: AppSpace.s16),
                  Row(
                    children: [
                      const Expanded(child: _LabelText(text: 'Custom Fields')),
                      const SizedBox(),
                      if (!widget.lockCustomFields)
                        TextButton.icon(
                          onPressed: _addCustomField,
                          icon: const FaIcon(FontAwesomeIcons.plus, size: 12),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
          const SizedBox(height: AppSpace.s8),
          if (customFields.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.s12),
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                borderRadius: AppRadius.mdAll,
              ),
              child: Text(
                'No custom fields yet. Add fields for participant information.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: semantic.textTertiary,
                ),
              ),
            ),

          // Editor panel (appears when adding or editing)
          if (_showCustomEditor) ...[
            Container(
              margin: const EdgeInsets.only(top: AppSpace.s12),
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
                      FaIcon(
                        FontAwesomeIcons.clipboard,
                        size: 16,
                        color: semantic.iconPrimary,
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Text(
                        _editingCustomIndex == null
                            ? 'Add Field'
                            : 'Edit Field',
                        style: AppTextStyles.headingH3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: semantic.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s8),
                  const _LabelText(text: 'Field Name'),
                  const SizedBox(height: AppSpace.s8),
                  TextFormField(
                    controller: _cfLabelController,
                    decoration: _inputDecoration(
                      context,
                      hint: 'Email',
                      prefixIcon: Icon(
                        FontAwesomeIcons.tag,
                        size: 15,
                        color: semantic.iconTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  const _LabelText(text: 'Field Type'),
                  const SizedBox(height: AppSpace.s8),
                  DropdownButtonFormField<String>(
                    initialValue: _cfType,
                    decoration: _inputDecoration(
                      context,
                      hint: 'Type',
                      prefixIcon: Icon(
                        FontAwesomeIcons.listCheck,
                        size: 15,
                        color: semantic.iconTertiary,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'text',
                        child: Text('Short text'),
                      ),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(value: 'number', child: Text('Number')),
                      DropdownMenuItem(value: 'date', child: Text('Date')),
                      DropdownMenuItem(value: 'image', child: Text('Image')),
                    ],
                    onChanged: (v) => setState(() {
                      _cfType = v ?? 'text';
                      if (_cfType != 'image') _cfImageFile = null;
                      if (_cfType == 'image') _cfRequired = false;
                    }),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  const _LabelText(text: 'Field Requirement'),
                  const SizedBox(height: AppSpace.s8),
                  DropdownButtonFormField<bool>(
                    initialValue: _cfType == 'image' ? false : _cfRequired,
                    decoration: _inputDecoration(
                      context,
                      hint: 'Optional',
                      prefixIcon: Icon(
                        FontAwesomeIcons.circleCheck,
                        size: 15,
                        color: semantic.iconTertiary,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Optional')),
                      DropdownMenuItem(value: true, child: Text('Required')),
                    ],
                    onChanged: _cfType == 'image'
                        ? null
                        : (v) => setState(() => _cfRequired = v ?? false),
                  ),
                  if (_cfType == 'image') ...[
                    const SizedBox(height: AppSpace.s8),
                    const _LabelText(text: 'Field Image'),
                    const SizedBox(height: AppSpace.s8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickEditorImage,
                        icon: FaIcon(
                          FontAwesomeIcons.image,
                          size: 14,
                          color: semantic.textOnBrand,
                        ),
                        label: Text(
                          _cfImageFile == null
                              ? 'Select image'
                              : 'Change image',
                        ),
                      ),
                    ),
                    if (_cfImageFile != null) ...[
                      const SizedBox(height: AppSpace.s8),
                      _buildCustomFieldImagePreview(context, _cfImageFile!),
                    ],
                  ],
                  if (_cfType == 'text' || _cfType == 'email') ...[
                    const SizedBox(height: AppSpace.s8),
                    const _LabelText(text: 'Helper Text'),
                    const SizedBox(height: AppSpace.s8),
                    TextFormField(
                      controller: _cfHelperController,
                      decoration: _inputDecoration(
                        context,
                        hint: 'Optional helper text',
                        prefixIcon: Icon(
                          FontAwesomeIcons.circleInfo,
                          size: 15,
                          color: semantic.iconTertiary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.s12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelCustomEditor,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveCustomEditor,
                          child: Text(
                            _editingCustomIndex == null ? 'Add' : 'Save',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Compact saved field cards
          if (customFields.isNotEmpty)
            ...List.generate(customFields.length, (index) {
              final field = customFields[index];
              final imageFile = field['image_file'] as PlatformFile?;
              final isRequired = field['required'] == true;
              final fieldLabel = field['label'] as String? ?? 'Untitled field';
              final fieldType = _displayFieldType(field['type'] as String?);

              return Container(
                margin: const EdgeInsets.only(top: AppSpace.s12),
                child: Material(
                  color: semantic.surfaceRaised,
                  borderRadius: AppRadius.mdAll,
                  child: InkWell(
                    onTap: widget.lockCustomFields
                        ? null
                        : () => _startEditingCustomField(index: index),
                    borderRadius: AppRadius.mdAll,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: semantic.surfaceOverlay,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Icon(
                              imageFile != null
                                  ? FontAwesomeIcons.image
                                  : FontAwesomeIcons.user,
                              size: 16,
                              color: semantic.iconPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s12),
                          if (imageFile != null) ...[const SizedBox.shrink()],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fieldLabel,
                                  style: AppTextStyles.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: semantic.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Type: $fieldType',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: semantic.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.s10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: semantic.surfaceBase,
                                  borderRadius: AppRadius.fullAll,
                                  border: Border.all(
                                    color: semantic.borderDefault,
                                  ),
                                ),
                                child: Text(
                                  isRequired ? 'Required' : 'Optional',
                                  style: AppTextStyles.caption.copyWith(
                                    color: semantic.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!widget.lockCustomFields) ...[
                                const SizedBox(width: AppSpace.s8),
                                InkWell(
                                  onTap: () => _removeCustomField(index),
                                  borderRadius: AppRadius.fullAll,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: semantic.surfaceBase,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: semantic.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: AppSpace.s16),
          if (!widget.lockCustomFields)
            DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: AppRadius.md,
                dashPattern: const [6, 4],
                strokeWidth: 1.2,
                color: semantic.borderDefault,
              ),
              child: InkWell(
                onTap: _addCustomField,
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
                        'Add Field',
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
        const SizedBox(width: AppSpace.s10),
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

class _RegistrationDeadlineField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback? onTap;

  const _RegistrationDeadlineField({required this.value, required this.onTap});

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return 'Select date and time';
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
    final semantic = context.semanticColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s12,
        ),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: semantic.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDeadline(value),
                style: AppTextStyles.bodyDefault.copyWith(
                  color: value != null
                      ? semantic.textPrimary
                      : semantic.textTertiary,
                ),
              ),
            ),
            FaIcon(
              FontAwesomeIcons.calendar,
              size: 16,
              color: semantic.iconTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        final isFirst = opt == options.first;
        return Expanded(
          child: GestureDetector(
            onTap: enabled ? () => onChanged(opt) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: isFirst ? AppSpace.s8 : 0),
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
              decoration: BoxDecoration(
                color: isSelected
                    ? semantic.surfaceBase
                    : semantic.surfaceOverlay,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: semantic.borderDefault),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  opt,
                  style: AppTextStyles.button.copyWith(
                    color: isSelected
                        ? semantic.textPrimary
                        : semantic.textSecondary,
                    fontWeight: FontWeight.w600,
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

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  Widget? prefixIcon,
}) {
  final semantic = context.semanticColors;
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyDefault.copyWith(color: semantic.textTertiary),
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
    filled: true,
    fillColor: semantic.surfaceRaised,
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.s16,
      vertical: AppSpace.s12,
    ),
  );
}
