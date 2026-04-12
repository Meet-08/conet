import 'dart:io';

import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final List<User> _selectedUsers = [];
  PlatformFile? _groupImageFile;

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _toggleUser(User user) {
    setState(() {
      final exists = _selectedUsers.any((u) => u.id == user.id);
      if (exists) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _removeUser(User user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.id == user.id);
    });
  }

  void _createGroup() {
    if (_selectedUsers.isEmpty) return;
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) return;
    Navigator.of(context).pop();
    context.read<MessageBloc>().add(
      MessageGroupCreated(
        name: groupName,
        userIds: _selectedUsers.map((u) => u.id).toList(),
        groupImageFile: _groupImageFile,
      ),
    );
  }

  Future<void> _pickGroupImage() async {
    final files = await pickFiles(
      limit: 1,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );

    if (!mounted || files == null || files.isEmpty) return;
    setState(() {
      _groupImageFile = files.first;
    });
  }

  Widget _buildGroupImagePreview(ColorScheme colorScheme) {
    if (_groupImageFile != null && _groupImageFile!.bytes != null) {
      return ClipOval(
        child: Image.memory(
          _groupImageFile!.bytes!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!kIsWeb && _groupImageFile?.path != null) {
      return ClipOval(
        child: Image.file(
          File(_groupImageFile!.path!),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    return CircleAvatar(
      radius: 36,
      backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
      child: FaIcon(
        FontAwesomeIcons.userGroup,
        color: colorScheme.onSurface.withValues(alpha: 0.55),
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'New Group',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Create button shown when at least one user selected
                    if (_selectedUsers.isNotEmpty)
                      TextButton(
                        onPressed: _createGroup,
                        child: const Text(
                          'Create',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),

              // Group name input
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: _pickGroupImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildGroupImagePreview(colorScheme),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.camera,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _groupNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Selected user chips
              if (_selectedUsers.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _selectedUsers.map((user) {
                      final displayName = '${user.firstName} ${user.lastName}'
                          .trim();
                      final label = displayName.isNotEmpty
                          ? displayName
                          : (user.username.isNotEmpty ? user.username : 'User');

                      return Chip(
                        avatar: CustomCircleAvatar(
                          size: CustomCircleAvatarSize.small,
                          imageUrl: user.profilePicUrl,
                          displayName: label,
                        ),
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        deleteIcon: const FaIcon(
                          FontAwesomeIcons.xmark,
                          size: 12,
                        ),
                        onDeleted: () => _removeUser(user),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 4),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) {
                    context.read<MessageBloc>().add(
                      MessageUserSearchRequested(value),
                    );
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    hintText: 'Search people, groups, communities...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // User search results / loading
              Expanded(
                child: BlocBuilder<MessageBloc, MessageState>(
                  builder: (context, state) {
                    if (state.isSearchingUsers) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    if (state.userSearchError != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.userSearchError!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    if (state.userSuggestions.isEmpty &&
                        _searchController.text.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.userGroup,
                              size: 48,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Search to add people',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state.userSuggestions.isEmpty) {
                      return Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: state.userSuggestions.length,
                      itemBuilder: (context, index) {
                        final user = state.userSuggestions[index];
                        final isSelected = _selectedUsers.any(
                          (u) => u.id == user.id,
                        );
                        return _SelectableUserTile(
                          user: user,
                          isSelected: isSelected,
                          onTap: () => _toggleUser(user),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _SelectableUserTile extends StatelessWidget {
  final User user;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableUserTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = '${user.firstName} ${user.lastName}'.trim();
    final subtitle = user.email.isNotEmpty
        ? user.email
        : (user.username.isNotEmpty ? '@${user.username}' : '');
    final avatarName = displayName.isNotEmpty ? displayName : user.username;

    return ListTile(
      leading: CustomCircleAvatar(
        size: CustomCircleAvatarSize.medium,
        imageUrl: user.profilePicUrl,
        displayName: avatarName,
      ),
      title: Text(
        displayName.isNotEmpty
            ? displayName
            : (user.username.isNotEmpty ? user.username : 'User'),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: isSelected
          ? CircleAvatar(
              radius: 12,
              backgroundColor: colorScheme.primary,
              child: const FaIcon(
                FontAwesomeIcons.check,
                size: 12,
                color: Colors.white,
              ),
            )
          : CircleAvatar(
              radius: 12,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
      onTap: onTap,
    );
  }
}
