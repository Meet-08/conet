import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/auth/constants/constant.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class AcademicInfoForm extends StatefulWidget {
  /// College name initial value
  final String? initialCollege;

  /// Degree initial value
  final String? initialDegree;

  /// Course/Major initial value
  final String? initialCourse;

  /// Start year initial value
  final int? initialStartYear;

  /// End year initial value
  final int? initialEndYear;

  /// Callback when form data changes
  final void Function({
    required String? college,
    required String? degree,
    required String? course,
    required int? startYear,
    required int? endYear,
  })?
  onChanged;

  /// Callback when form is submitted/saved (triggered externally)
  final void Function({
    required String college,
    required String degree,
    required String course,
    required int? startYear,
    required int? endYear,
  })?
  onSubmit;

  /// Show validation errors
  final bool showErrors;

  /// Whether form is in loading state
  final bool isLoading;

  /// If true, shows creation mode labels (questions). If false, shows edit mode labels.
  final bool isCreationMode;

  /// Form key for external validation
  final GlobalKey<FormState>? formKey;

  const AcademicInfoForm({
    super.key,
    this.initialCollege,
    this.initialDegree,
    this.initialCourse,
    this.initialStartYear,
    this.initialEndYear,
    this.onChanged,
    this.onSubmit,
    this.showErrors = false,
    this.isLoading = false,
    this.isCreationMode = true,
    this.formKey,
  });

  @override
  State<AcademicInfoForm> createState() => _AcademicInfoFormState();
}

class _AcademicInfoFormState extends State<AcademicInfoForm> {
  late String? _selectedCollege;
  late String? _selectedDegree;
  late String? _selectedCourse;
  late TextEditingController _startYearController;
  late TextEditingController _endYearController;

  @override
  void initState() {
    super.initState();
    _selectedCollege = widget.initialCollege;
    _selectedDegree = widget.initialDegree;
    _selectedCourse = widget.initialCourse;
    _startYearController = TextEditingController(
      text: widget.initialStartYear?.toString() ?? '',
    );
    _endYearController = TextEditingController(
      text: widget.initialEndYear?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(AcademicInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCollege != widget.initialCollege) {
      _selectedCollege = widget.initialCollege;
    }
    if (oldWidget.initialDegree != widget.initialDegree) {
      _selectedDegree = widget.initialDegree;
    }
    if (oldWidget.initialCourse != widget.initialCourse) {
      _selectedCourse = widget.initialCourse;
    }
    if (oldWidget.initialStartYear != widget.initialStartYear) {
      _startYearController.text = widget.initialStartYear?.toString() ?? '';
    }
    if (oldWidget.initialEndYear != widget.initialEndYear) {
      _endYearController.text = widget.initialEndYear?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged?.call(
      college: _selectedCollege,
      degree: _selectedDegree,
      course: _selectedCourse,
      startYear: int.tryParse(_startYearController.text.trim()),
      endYear: int.tryParse(_endYearController.text.trim()),
    );
  }

  Future<void> _pickYear({
    required TextEditingController controller,
    required String title,
  }) async {
    if (widget.isLoading) return;

    final currentYear = DateTime.now().year;
    final minYear = 1950;
    final maxYear = currentYear + 10;
    final parsedYear = int.tryParse(controller.text.trim());
    final selectedYear = parsedYear == null
        ? currentYear
        : parsedYear.clamp(minYear, maxYear);

    final pickedYear = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            height: 280,
            child: YearPicker(
              firstDate: DateTime(minYear),
              lastDate: DateTime(maxYear),
              selectedDate: DateTime(selectedYear),
              onChanged: (pickedDate) {
                Navigator.of(dialogContext).pop(pickedDate.year);
              },
            ),
          ),
        );
      },
    );

    if (pickedYear == null) return;

    setState(() {
      controller.text = pickedYear.toString();
    });
    _notifyChange();
  }

  bool validate() {
    if (widget.formKey?.currentState != null) {
      return widget.formKey!.currentState!.validate();
    }
    // Manual validation
    return _selectedCollege != null &&
        _selectedCollege!.isNotEmpty &&
        _selectedDegree != null &&
        _selectedDegree!.isNotEmpty &&
        _selectedCourse != null &&
        _selectedCourse!.isNotEmpty;
  }

  void submit() {
    if (!validate()) return;
    widget.onSubmit?.call(
      college: _selectedCollege!,
      degree: _selectedDegree!,
      course: _selectedCourse!,
      startYear: int.tryParse(_startYearController.text.trim()),
      endYear: int.tryParse(_endYearController.text.trim()),
    );
  }

  /// Get current form values
  ({
    String? college,
    String? degree,
    String? course,
    int? startYear,
    int? endYear,
  })
  getValues() {
    return (
      college: _selectedCollege,
      degree: _selectedDegree,
      course: _selectedCourse,
      startYear: int.tryParse(_startYearController.text.trim()),
      endYear: int.tryParse(_endYearController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchableDropdownField(
            label: widget.isCreationMode
                ? 'Which college do you attend?'
                : 'College / University',
            value: _selectedCollege,
            items: AuthConstants.collegeOptions,
            hint: 'Select your college',
            searchHint: 'Search College',
            onChanged: (value) {
              setState(() => _selectedCollege = value);
              _notifyChange();
            },
          ),
          const SizedBox(height: 16),
          _buildSearchableDropdownField(
            label: widget.isCreationMode
                ? 'What degree are you pursuing?'
                : 'Degree',
            value: _selectedDegree,
            items: AuthConstants.degreeOptions,
            hint: 'Select your degree',
            searchHint: 'Search Degree',
            onChanged: (value) {
              setState(() => _selectedDegree = value);
              _notifyChange();
            },
          ),
          const SizedBox(height: 16),
          _buildSearchableDropdownField(
            label: widget.isCreationMode
                ? 'What course are you pursuing?'
                : 'Course / Major',
            value: _selectedCourse,
            items: AuthConstants.courseOptions,
            hint: 'Select your course/major',
            searchHint: 'Search Course',
            onChanged: (value) {
              setState(() => _selectedCourse = value);
              _notifyChange();
            },
          ),
          const SizedBox(height: 24),
          if (!widget.isCreationMode)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Year', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      _buildYearPickerField(
                        controller: _startYearController,
                        hint: '2023',
                        title: 'Select start year',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Year', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      _buildYearPickerField(
                        controller: _endYearController,
                        hint: '2027',
                        title: 'Select end year',
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required String searchHint,
    required void Function(String?) onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color: semantic.textPrimary,
            fontWeight: AppTypographyTokens.weightMedium,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        DropdownSearch<String>(
          selectedItem: value,
          items: (filter, _) => items,
          onChanged: widget.isLoading ? null : onChanged,
          validator: (selected) {
            if (!widget.showErrors) return null;
            if (selected == null || selected.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
          popupProps: PopupProps.modalBottomSheet(
            showSearchBox: true,
            fit: FlexFit.loose,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.68,
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              barrierColor: semantic.backgroundBackdrop,
              backgroundColor: semantic.backgroundPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: AppRadius.lg),
              ),
            ),
            itemBuilder: (context, item, isDisabled, isSelected) {
              final itemTextStyle = textTheme.bodyLarge?.copyWith(
                color: isDisabled
                    ? semantic.textTertiary
                    : isSelected
                    ? semantic.textSelected
                    : semantic.textPrimary,
                fontWeight: isSelected
                    ? AppTypographyTokens.weightMedium
                    : AppTypographyTokens.weightRegular,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: semantic.borderSubtle),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
                    child: Text(item, style: itemTextStyle),
                  ),
                ),
              );
            },
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: Icon(Icons.search, color: semantic.iconSecondary),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s12,
                  vertical: AppSpace.s12,
                ),
                border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
              ),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: semantic.textSecondary,
              ),
              filled: true,
              fillColor: semantic.backgroundSecondary,
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
                borderSide: BorderSide(color: semantic.borderFocus, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearPickerField({
    required TextEditingController controller,
    required String hint,
    required String title,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickYear(controller: controller, title: title),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: semantic.textSecondary,
        ),
        suffixIcon: const Icon(Icons.keyboard_arrow_down),
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
          borderSide: BorderSide(color: semantic.borderFocus),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s12,
        ),
      ),
    );
  }
}
