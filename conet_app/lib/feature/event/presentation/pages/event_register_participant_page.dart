import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/media_cache_manager.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:conet_app/feature/message/presentation/pages/image_viewer_page.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventRegisterParticipantPage extends StatefulWidget {
  final Event event;

  const EventRegisterParticipantPage({super.key, required this.event});

  @override
  State<EventRegisterParticipantPage> createState() =>
      _EventRegisterParticipantPageState();
}

class _EventRegisterParticipantPageState
    extends State<EventRegisterParticipantPage> {
  final _teamNameController = TextEditingController();

  final Map<String, TextEditingController> _customTextControllers = {};
  final Map<String, String?> _customSelectValues = {};
  final Map<String, List<String>> _customMultiSelectValues = {};

  User? _selectedParticipant;
  final List<User> _selectedMembers = [];
  late int _teamSize;
  bool _submitting = false;

  bool get _isTeamEvent =>
      (widget.event.participationType ?? '').trim().toLowerCase() == 'team';

  int get _minTeamSize => widget.event.minTeamSize ?? 1;
  int get _maxTeamSize => widget.event.maxTeamSize ?? (_minTeamSize + 10);

  @override
  void initState() {
    super.initState();
    _teamSize = _isTeamEvent ? _minTeamSize : 1;

    for (final field in widget.event.customFields) {
      if (field.normalizedType == 'image') continue;

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
    _teamNameController.dispose();
    for (final controller in _customTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickParticipant() async {
    final searchUsers = serviceLocator<MessageSearchUsers>();

    final selected = await showUserSelectorBottomSheet(
      context: context,
      title: 'Select Participant',
      searchHint: 'Search participant by name or username',
      emptyMessage: 'Search to select participant',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Select',
      initialSelectedUsers: _selectedParticipant == null
          ? const []
          : [_selectedParticipant!],
      searchUsers: (query, limit) async {
        final result = await searchUsers(query: query, limit: limit);
        return result.fold((failure) => throw Exception(failure.message), (
          users,
        ) {
          return users;
        });
      },
    );

    if (!mounted || selected == null) return;

    if (selected.length > 1) {
      AppToast.showWarning(context, 'Select only one participant');
    }

    setState(() {
      _selectedParticipant = selected.isEmpty ? null : selected.first;
      _selectedMembers.removeWhere((u) => u.id == _selectedParticipant?.id);
    });
  }

  Future<void> _pickTeamMembers() async {
    if (_selectedParticipant == null) {
      AppToast.showWarning(
        context,
        'Select participant first to set team captain',
      );
      return;
    }

    final searchUsers = serviceLocator<MessageSearchUsers>();

    final selected = await showUserSelectorBottomSheet(
      context: context,
      title: 'Add Team Members',
      searchHint: 'Search users to add in team',
      emptyMessage: 'Search by name or username',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Done',
      excludedUserId: _selectedParticipant!.id,
      initialSelectedUsers: _selectedMembers,
      searchUsers: (query, limit) async {
        final result = await searchUsers(query: query, limit: limit);
        return result.fold((failure) => throw Exception(failure.message), (
          users,
        ) {
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

  String? _validate() {
    if (_selectedParticipant == null) {
      return 'Participant is required';
    }

    if (_isTeamEvent) {
      if (_teamNameController.text.trim().isEmpty) {
        return 'Team name is required for team events';
      }
      if (_teamSize < _minTeamSize) {
        return 'Team size must be at least $_minTeamSize';
      }
      if (_teamSize > _maxTeamSize) {
        return 'Team size cannot exceed $_maxTeamSize';
      }
      if (_teamSize < _selectedMembers.length + 1) {
        return 'Team size must include captain and selected members';
      }
      final requiredMembers = _teamSize - 1;
      if (_selectedMembers.length != requiredMembers) {
        return 'Add exactly $requiredMembers team members to continue';
      }
    }

    for (final field in widget.event.customFields) {
      if (field.normalizedType == 'image') continue;
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
        final selected =
            _customMultiSelectValues[field.key] ?? const <String>[];
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

    return null;
  }

  EventRegistrationPayload _buildPayload() {
    final customResponses = <String, dynamic>{};

    for (final field in widget.event.customFields) {
      final type = field.normalizedType;
      if (type == 'image') continue;

      if (type == 'select') {
        final selected = (_customSelectValues[field.key] ?? '').trim();
        if (selected.isNotEmpty) {
          customResponses[field.key] = selected;
        }
        continue;
      }

      if (type == 'multi_select') {
        final selected =
            (_customMultiSelectValues[field.key] ?? const <String>[])
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

    return EventRegistrationPayload(
      teamName: _isTeamEvent ? _teamNameController.text.trim() : null,
      teamSize: _isTeamEvent ? _teamSize : null,
      customFieldResponses: customResponses,
      memberUserIds: _selectedMembers
          .map((member) => member.id)
          .toList(growable: false),
    );
  }

  Future<void> _submit() async {
    final validation = _validate();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }

    final participant = _selectedParticipant;
    if (participant == null) return;

    final payload = _buildPayload();

    setState(() {
      _submitting = true;
    });

    context.read<EventBloc>().add(
      EventRegisterParticipantEvent(
        eventId: widget.event.id,
        participantUserId: participant.id,
        payload: payload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventRegistrationLoading) {
          setState(() {
            _submitting = true;
          });
          return;
        }

        if (state is EventRegistrationSuccess &&
            state.response.event.id == widget.event.id) {
          setState(() {
            _submitting = false;
          });
          AppToast.showSuccess(context, 'Participant registered successfully');
          Navigator.of(context).pop(true);
          return;
        }

        if (state is EventRegistrationFailure) {
          setState(() {
            _submitting = false;
          });
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Register Participant')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organizer/co-host can register teams for other participants.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Participant',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickParticipant,
                        child: Text(
                          _selectedParticipant == null ? 'Select' : 'Change',
                        ),
                      ),
                    ],
                  ),
                  if (_selectedParticipant != null)
                    Chip(
                      label: Text(_displayName(_selectedParticipant!)),
                      onDeleted: () {
                        setState(() {
                          _selectedParticipant = null;
                          _selectedMembers.clear();
                        });
                      },
                    )
                  else
                    Text(
                      'Select the participant who will be registered.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (_isTeamEvent) ...[
                    Text(
                      'Team Registration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _teamNameController,
                      label: 'Team Name *',
                      icon: FontAwesomeIcons.users,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                            icon: const FaIcon(
                              FontAwesomeIcons.minus,
                              size: 14,
                            ),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Team Members (${_selectedMembers.length})',
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
                                    _selectedMembers.removeWhere(
                                      (u) => u.id == member.id,
                                    );
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      )
                    else
                      Text(
                        'Add members to match selected team size.',
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
                      if (normalizedType == 'image') {
                        return _buildReadOnlyImageField(field);
                      }

                      final requiredMark = field.required ? ' *' : '';

                      if (normalizedType == 'select' &&
                          field.options.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DropdownButtonFormField<String>(
                            initialValue: _customSelectValues[field.key],
                            decoration: _decoration(
                              context,
                              label: '${field.label}$requiredMark',
                              icon: FontAwesomeIcons.list,
                              helperText: field.helperText,
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
                            _customMultiSelectValues[field.key] ??
                            const <String>[];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InputDecorator(
                            decoration: _decoration(
                              context,
                              label: '${field.label}$requiredMark',
                              icon: FontAwesomeIcons.listCheck,
                              helperText: field.helperText,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: field.options
                                  .map((option) {
                                    final isSelected = selectedValues.contains(
                                      option,
                                    );
                                    return FilterChip(
                                      label: Text(option),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final nextValues = List<String>.from(
                                          selectedValues,
                                        );
                                        if (selected) {
                                          nextValues.add(option);
                                        } else {
                                          nextValues.remove(option);
                                        }

                                        setState(() {
                                          _customMultiSelectValues[field.key] =
                                              nextValues.toSet().toList(
                                                growable: false,
                                              );
                                        });
                                      },
                                    );
                                  })
                                  .toList(growable: false),
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
                        helperText: field.helperText,
                        keyboardType: normalizedType == 'number'
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.text,
                        maxLines: normalizedType == 'textarea' ? 3 : 1,
                      );
                    }),
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
                          : const Text('Register Participant'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyImageField(EventCustomField field) {
    final imageUrl = field.imageUrl?.trim();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    void openViewer() {
      if (imageUrl == null || imageUrl.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewerPage(
            imageUrls: [Uri.encodeFull(imageUrl)],
            initialIndex: 0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: imageUrl == null || imageUrl.isEmpty ? null : openViewer,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.image,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: Uri.encodeFull(imageUrl),
                        cacheManager: MediaCacheManager.instance,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            'Image unavailable',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          'Image unavailable',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
              ),
            ),
          ],
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
  String? helperText,
}) {
  return InputDecoration(
    labelText: label,
    helperText: helperText?.trim().isEmpty == true ? null : helperText?.trim(),
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
  final String? helperText;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.helperText,
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
        decoration: _decoration(
          context,
          label: label,
          icon: icon,
          helperText: helperText,
        ),
      ),
    );
  }
}
