import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

const Object _eventCustomFieldUnset = Object();

class EventCustomField extends Equatable {
  final String key;
  final String label;
  final String? helperText;
  final String type;
  final bool required;
  final List<String> options;
  final String? imageUrl;
  final PlatformFile? imageFile;

  const EventCustomField({
    required this.key,
    required this.label,
    this.helperText,
    this.type = 'text',
    this.required = false,
    this.options = const [],
    this.imageUrl,
    this.imageFile,
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
    if (value == 'image_url' || value == 'image-url') {
      return 'image';
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
    final normalizedType = EventCustomField(
      key: key,
      label: label,
      type: type,
    ).normalizedType;
    final optionsRaw = json['options'];
    final imageUrl = (json['image_url'] ?? json['imageUrl'])?.toString().trim();

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
      required: normalizedType == 'image' ? false : json['required'] == true,
      options: options,
      imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      if (helperText != null && helperText!.trim().isNotEmpty)
        'helper_text': helperText!.trim(),
      'type': normalizedType,
      'required': normalizedType == 'image' ? false : required,
      if (normalizedType == 'image' &&
          imageUrl != null &&
          imageUrl!.trim().isNotEmpty)
        'image_url': imageUrl!.trim(),
      if (normalizedType != 'image' && options.isNotEmpty) 'options': options,
    };
  }

  EventCustomField copyWith({
    String? key,
    String? label,
    String? helperText,
    String? type,
    bool? required,
    List<String>? options,
    Object? imageUrl = _eventCustomFieldUnset,
    Object? imageFile = _eventCustomFieldUnset,
  }) {
    return EventCustomField(
      key: key ?? this.key,
      label: label ?? this.label,
      helperText: helperText ?? this.helperText,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
      imageUrl: identical(imageUrl, _eventCustomFieldUnset)
          ? this.imageUrl
          : imageUrl as String?,
      imageFile: identical(imageFile, _eventCustomFieldUnset)
          ? this.imageFile
          : imageFile as PlatformFile?,
    );
  }

  @override
  List<Object?> get props => [
    key,
    label,
    helperText,
    normalizedType,
    required,
    options,
    imageUrl,
    imageFile,
  ];
}
