import 'package:equatable/equatable.dart';

class EventCustomField extends Equatable {
  final String key;
  final String label;
  final String? helperText;
  final String type;
  final bool required;
  final List<String> options;

  const EventCustomField({
    required this.key,
    required this.label,
    this.helperText,
    this.type = 'text',
    this.required = false,
    this.options = const [],
  });

  String get normalizedType {
    final value = type.trim().toLowerCase();
    if (value.isEmpty) return 'text';
    if (value == 'single_select' ||
        value == 'single-select' ||
        value == 'singleselect' ||
        value == 'dropdown') {
      return 'select';
    }
    if (value == 'multiselect' ||
        value == 'multi-select' ||
        value == 'multiple_select' ||
        value == 'multiple-select' ||
        value == 'multiple') {
      return 'multi_select';
    }
    return value;
  }

  factory EventCustomField.fromJson(Map<String, dynamic> json) {
    final key = (json['key'] ?? json['id'] ?? '').toString().trim();
    final label = (json['label'] ?? json['name'] ?? key).toString().trim();
    final helperText =
        (json['helper_text'] ?? json['helperText'] ?? json['description'])
            ?.toString()
            .trim();
    final type = (json['type'] ?? 'text').toString().trim().toLowerCase();
    final optionsRaw = json['options'];

    final options = optionsRaw is List
        ? optionsRaw
              .map((option) => option.toString().trim())
              .where((option) => option.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return EventCustomField(
      key: key,
      label: label.isEmpty ? key : label,
      helperText: (helperText == null || helperText.isEmpty)
          ? null
          : helperText,
      type: type.isEmpty ? 'text' : type,
      required: json['required'] == true,
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      if (helperText != null && helperText!.trim().isNotEmpty)
        'helper_text': helperText!.trim(),
      'type': normalizedType,
      'required': required,
      if (options.isNotEmpty) 'options': options,
    };
  }

  @override
  List<Object?> get props => [
    key,
    label,
    helperText,
    normalizedType,
    required,
    options,
  ];
}
