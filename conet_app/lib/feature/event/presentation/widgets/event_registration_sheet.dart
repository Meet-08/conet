import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<EventRegistrationPayload?> showEventRegistrationSheet({
  required BuildContext context,
  required Event event,
}) {
  return showModalBottomSheet<EventRegistrationPayload>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _EventRegistrationSheet(event: event),
  );
}

class _EventRegistrationSheet extends StatefulWidget {
  final Event event;

  const _EventRegistrationSheet({required this.event});

  @override
  State<_EventRegistrationSheet> createState() => _EventRegistrationSheetState();
}

class _EventRegistrationSheetState extends State<_EventRegistrationSheet> {
  final _enrollmentController = TextEditingController();
  final _contactController = TextEditingController();
  final _semesterController = TextEditingController();
  final _branchController = TextEditingController();
  final _transactionController = TextEditingController();
  final _paymentProofController = TextEditingController();

  final Map<String, TextEditingController> _customTextControllers = {};
  final Map<String, String?> _customSelectValues = {};
  final Map<String, List<String>> _customMultiSelectValues = {};

  final List<User> _selectedMembers = [];

  late int _teamSize;
  bool _submitting = false;
  bool _uploadingProof = false;

  bool get _isTeamEvent =>
      (widget.event.participationType ?? '').trim().toLowerCase() == 'team';

  int get _minTeamSize => widget.event.minTeamSize ?? 1;
  int get _maxTeamSize => widget.event.maxTeamSize ?? (_minTeamSize + 10);

  double get _perMemberAmount => widget.event.isPaid ? (widget.event.price ?? 0) : 0;

  int get _paymentMemberCount => _isTeamEvent ? _teamSize : 1;

  double get _totalAmount => _perMemberAmount * _paymentMemberCount;

  String? get _upiPaymentUri {
    final upiId = widget.event.upiId?.trim();
    if (!widget.event.isPaid || upiId == null || upiId.isEmpty) return null;

    return 'upi://pay?pa=${Uri.encodeComponent(upiId)}&pn=${Uri.encodeComponent(widget.event.title)}&tn=${Uri.encodeComponent('Event Registration')}&am=${_totalAmount.toStringAsFixed(2)}&cu=INR';
  }

  @override
  void initState() {
    super.initState();
    _teamSize = _isTeamEvent ? _minTeamSize : 1;

    for (final field in widget.event.customFields) {
      if (field.normalizedType == 'select' && field.options.isNotEmpty) {
        _customSelectValues[field.key] = null;
      } else if (field.normalizedType == 'multi_select' &&
          field.options.isNotEmpty) {
        _customMultiSelectValues[field.key] = [];
      } else {
        _customTextControllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _enrollmentController.dispose();
    _contactController.dispose();
    _semesterController.dispose();
    _branchController.dispose();
    _transactionController.dispose();
    _paymentProofController.dispose();

    for (final controller in _customTextControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _pickTeamMembers() async {
    final appUserState = context.read<AppUserCubit>().state;
    final currentUserId = appUserState is AppUserAuthenticated
        ? appUserState.user.id
        : null;

    final searchUsers = serviceLocator<MessageSearchUsers>();
    final selected = await showUserSelectorBottomSheet(
      context: context,
      title: 'Add Team Members',
      searchHint: 'Search users to add in team',
      emptyMessage: 'Search by name or username',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Done',
      excludedUserId: currentUserId,
      initialSelectedUsers: _selectedMembers,
      searchUsers: (query, limit) async {
        final result = await searchUsers(query: query, limit: limit);
        return result.fold((failure) => throw Exception(failure.message), (users) {
          return users;
        });
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedMembers
        ..clear()
        ..addAll(selected);

      final minRequired = _selectedMembers.length + 1;
      if (_teamSize < minRequired) {
        _teamSize = minRequired;
      }
      if (_teamSize > _maxTeamSize) {
        _teamSize = _maxTeamSize;
      }
    });
  }

  Future<void> _uploadPaymentProof() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );

    final file = picked?.files.single;
    if (file == null) return;

    setState(() {
      _uploadingProof = true;
    });

    try {
      final uploader = serviceLocator<FileUploadDataSource>();
      final urls = await uploader.uploadFiles(
        files: [file],
        bucket: 'event',
        folder: 'registration-proofs/${widget.event.id}',
      );

      if (!mounted) return;

      final uploadedUrl = urls.isEmpty ? null : urls.first;
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        AppToast.showError(context, 'Failed to upload payment proof');
        return;
      }

      _paymentProofController.text = uploadedUrl;
      AppToast.showSuccess(context, 'Payment proof uploaded');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _uploadingProof = false;
      });
    }
  }

  String? _validate() {
    if (_isTeamEvent) {
      if (_teamSize < _minTeamSize) {
        return 'Team size must be at least $_minTeamSize';
      }
      if (_teamSize > _maxTeamSize) {
        return 'Team size cannot exceed $_maxTeamSize';
      }
      if (_teamSize < _selectedMembers.length + 1) {
        return 'Team size must include captain and selected members';
      }
      if (_enrollmentController.text.trim().isEmpty) {
        return 'Enrollment number is required for team events';
      }
      if (_semesterController.text.trim().isEmpty) {
        return 'Semester is required for team events';
      }
      if (_branchController.text.trim().isEmpty) {
        return 'Branch is required for team events';
      }
    }

    for (final field in widget.event.customFields) {
      if (!field.required) continue;

      final type = field.normalizedType;
      if (type == 'select') {
        final selected = (_customSelectValues[field.key] ?? '').trim();
        if (selected.isEmpty) {
          return '${field.label} is required';
        }
        continue;
      }

      if (type == 'multi_select') {
        final selected = _customMultiSelectValues[field.key] ?? const <String>[];
        if (selected.isEmpty) {
          return '${field.label} is required';
        }
        continue;
      }

      final value = (_customTextControllers[field.key]?.text ?? '').trim();
      if (value.isEmpty) {
        return '${field.label} is required';
      }
    }

    if (widget.event.isPaid) {
      if (_transactionController.text.trim().isEmpty) {
        return 'Transaction ID is required for paid events';
      }
      if (_paymentProofController.text.trim().isEmpty) {
        return 'Payment proof URL is required for paid events';
      }
    }

    return null;
  }

  EventRegistrationPayload _buildPayload() {
    final customResponses = <String, dynamic>{};

    for (final field in widget.event.customFields) {
      final type = field.normalizedType;
      if (type == 'select') {
        final selected = (_customSelectValues[field.key] ?? '').trim();
        if (selected.isNotEmpty) {
          customResponses[field.key] = selected;
        }
        continue;
      }

      if (type == 'multi_select') {
        final selected = (_customMultiSelectValues[field.key] ?? const <String>[])
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false);
        if (selected.isNotEmpty) {
          customResponses[field.key] = selected;
        }
        continue;
      }

      final value = (_customTextControllers[field.key]?.text ?? '').trim();
      if (value.isNotEmpty) {
        customResponses[field.key] = value;
      }
    }

    final semesterText = _semesterController.text.trim();

    return EventRegistrationPayload(
      teamSize: _isTeamEvent ? _teamSize : null,
      enrollmentNumber: _enrollmentController.text.trim().isEmpty
          ? null
          : _enrollmentController.text.trim(),
      contactNumber: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      semester: semesterText.isEmpty ? null : int.tryParse(semesterText),
      branch: _branchController.text.trim().isEmpty
          ? null
          : _branchController.text.trim(),
      transactionId: _transactionController.text.trim().isEmpty
          ? null
          : _transactionController.text.trim(),
      paymentProofUrl: _paymentProofController.text.trim().isEmpty
          ? null
          : _paymentProofController.text.trim(),
      customFieldResponses: customResponses,
      memberUserIds: _selectedMembers.map((member) => member.id).toList(growable: false),
    );
  }

  Future<void> _submit() async {
    final validation = _validate();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }

    setState(() {
      _submitting = true;
    });

    final payload = _buildPayload();

    if (!mounted) return;

    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Register for ${widget.event.title}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isTeamEvent) ...[
                Text(
                  'Team Registration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _teamSize > _minTeamSize
                            ? () => setState(() => _teamSize--)
                            : null,
                        icon: const FaIcon(FontAwesomeIcons.minus, size: 14),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$_teamSize Members',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Allowed: $_minTeamSize - $_maxTeamSize',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _teamSize < _maxTeamSize
                            ? () => setState(() => _teamSize++)
                            : null,
                        icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _enrollmentController,
                  label: 'Captain Enrollment Number *',
                  icon: FontAwesomeIcons.idCard,
                ),
                _InputField(
                  controller: _semesterController,
                  label: 'Captain Semester *',
                  icon: FontAwesomeIcons.calendarWeek,
                  keyboardType: TextInputType.number,
                ),
                _InputField(
                  controller: _branchController,
                  label: 'Captain Branch *',
                  icon: FontAwesomeIcons.codeBranch,
                ),
                _InputField(
                  controller: _contactController,
                  label: 'Captain Contact Number',
                  icon: FontAwesomeIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Optional Team Members (${_selectedMembers.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickTeamMembers,
                      child: const Text('Search & Add'),
                    ),
                  ],
                ),
                if (_selectedMembers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedMembers
                        .map(
                          (member) => Chip(
                            label: Text(_displayName(member)),
                            onDeleted: () {
                              setState(() {
                                _selectedMembers.removeWhere((u) => u.id == member.id);
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  )
                else
                  Text(
                    'No optional members added',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 14),
              ],
              if (widget.event.customFields.isNotEmpty) ...[
                Text(
                  'Registration Fields',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.event.customFields.map((field) {
                  final normalizedType = field.normalizedType;
                  final requiredMark = field.required ? ' *' : '';

                  if (normalizedType == 'select' && field.options.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                        initialValue: _customSelectValues[field.key],
                        decoration: _decoration(
                          context,
                          label: '${field.label}$requiredMark',
                          icon: FontAwesomeIcons.list,
                        ),
                        items: field.options
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _customSelectValues[field.key] = value;
                          });
                        },
                      ),
                    );
                  }

                  if (normalizedType == 'multi_select' &&
                      field.options.isNotEmpty) {
                    final selectedValues =
                        _customMultiSelectValues[field.key] ?? const <String>[];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InputDecorator(
                        decoration: _decoration(
                          context,
                          label: '${field.label}$requiredMark',
                          icon: FontAwesomeIcons.listCheck,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: field.options.map((option) {
                            final isSelected = selectedValues.contains(option);
                            return FilterChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (selected) {
                                final nextValues = List<String>.from(selectedValues);
                                if (selected) {
                                  nextValues.add(option);
                                } else {
                                  nextValues.remove(option);
                                }

                                setState(() {
                                  _customMultiSelectValues[field.key] = nextValues
                                      .toSet()
                                      .toList(growable: false);
                                });
                              },
                            );
                          }).toList(growable: false),
                        ),
                      ),
                    );
                  }

                  return _InputField(
                    controller: _customTextControllers[field.key]!,
                    label: '${field.label}$requiredMark',
                    icon: normalizedType == 'number'
                        ? FontAwesomeIcons.hashtag
                        : FontAwesomeIcons.pen,
                    keyboardType: normalizedType == 'number'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    maxLines: normalizedType == 'textarea' ? 3 : 1,
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (widget.event.isPaid) ...[
                Text(
                  'Payment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price per member: Rs ${_perMemberAmount.toStringAsFixed(2)}'),
                      Text('Members: $_paymentMemberCount'),
                      Text(
                        'Total: Rs ${_totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.event.upiId?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('UPI ID: ${widget.event.upiId!.trim()}'),
                        ),
                    ],
                  ),
                ),
                if (_upiPaymentUri != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: _upiPaymentUri!,
                        size: 180,
                        version: QrVersions.auto,
                      ),
                    ),
                  ),
                ],
                _InputField(
                  controller: _transactionController,
                  label: 'Transaction ID *',
                  icon: FontAwesomeIcons.receipt,
                ),
                _InputField(
                  controller: _paymentProofController,
                  label: 'Payment Proof URL *',
                  icon: FontAwesomeIcons.link,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _uploadingProof ? null : _uploadPaymentProof,
                    icon: _uploadingProof
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const FaIcon(FontAwesomeIcons.upload, size: 14),
                    label: Text(_uploadingProof ? 'Uploading...' : 'Upload Proof'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(User user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user.username.isNotEmpty) return user.username;
    return 'User';
  }
}

InputDecoration _decoration(
  BuildContext context, {
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: FaIcon(icon, size: 14),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _decoration(context, label: label, icon: icon),
      ),
    );
  }
}
