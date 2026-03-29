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
                      const Text(
                        'Start Year',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _startYearController,
                        hint: '2023',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Year',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _endYearController,
                        hint: '2027',
                        keyboardType: TextInputType.number,
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
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
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
          popupProps: PopupProps.menu(
            showSearchBox: true,
            fit: FlexFit.loose,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => _notifyChange(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
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
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
