import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ActivityStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;

  const ActivityStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
  });

  @override
  State<ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends State<ActivityStep> {
  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  List<Map<String, dynamic>> get _activities => List<Map<String, dynamic>>.from(
    widget.formData['activities'] as List? ?? [],
  );

  List<Map<String, dynamic>> get _prizes =>
      List<Map<String, dynamic>>.from(widget.formData['prizes'] as List? ?? []);

  // ── Activities CRUD ──

  void _addActivity() {
    final list = _activities
      ..add({'activity_time': null, 'activity_title': ''});
    _update({'activities': list});
  }

  void _removeActivity(int i) {
    final list = _activities..removeAt(i);
    _update({'activities': list});
  }

  void _updateActivity(int i, Map<String, dynamic> patch) {
    final list = _activities;
    list[i] = {...list[i], ...patch};
    _update({'activities': list});
  }

  // ── Prizes CRUD ──

  void _addPrize() {
    final list = _prizes..add({'position': '', 'prize': ''});
    _update({'prizes': list});
  }

  void _removePrize(int i) {
    final list = _prizes..removeAt(i);
    _update({'prizes': list});
  }

  void _updatePrize(int i, Map<String, dynamic> patch) {
    final list = _prizes;
    list[i] = {...list[i], ...patch};
    _update({'prizes': list});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activities = _activities;
    final prizes = _prizes;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════ SCHEDULE ═══════════════════════
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.clockRotateLeft,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Schedule / Activities',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addActivity,
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activities.isEmpty)
            const _EmptyHint(
              icon: FontAwesomeIcons.calendarCheck,
              text: 'No activities added yet.\nTap "Add" to create a schedule.',
            ),

          ...List.generate(activities.length, (i) {
            final a = activities[i];
            return _DismissibleCard(
              key: ValueKey('act_$i'),
              onDismissed: () => _removeActivity(i),
              child: Row(
                children: [
                  // Time picker
                  _CompactTimePicker(
                    value: a['activity_time'] as TimeOfDay?,
                    onChanged: (t) => _updateActivity(i, {'activity_time': t}),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: TextFormField(
                      initialValue: a['activity_title'] as String? ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Activity title',
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdAll,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) =>
                          _updateActivity(i, {'activity_title': v}),
                    ),
                  ),
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 14,
                      color: colorScheme.error,
                    ),
                    onPressed: () => _removeActivity(i),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          // ═══════════════════════ PRIZES ═══════════════════════
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.trophy,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Prizes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addPrize,
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (prizes.isEmpty)
            const _EmptyHint(
              icon: FontAwesomeIcons.award,
              text: 'No prizes added yet.',
            ),

          ...List.generate(prizes.length, (i) {
            final p = prizes[i];
            return _DismissibleCard(
              key: ValueKey('prize_$i'),
              onDismissed: () => _removePrize(i),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: p['position'] as String? ?? '',
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1st',
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdAll,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => _updatePrize(i, {'position': v}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: p['prize'] as String? ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Prize description',
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdAll,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => _updatePrize(i, {'prize': v}),
                    ),
                  ),
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 14,
                      color: colorScheme.error,
                    ),
                    onPressed: () => _removePrize(i),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Compact time picker chip ────────────────────────────────────────────────

class _CompactTimePicker extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;

  const _CompactTimePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: const FaIcon(FontAwesomeIcons.clock, size: 12),
      label: Text(
        value?.format(context) ?? 'Time',
        style: TextStyle(
          fontSize: 12,
          color: value != null
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

// ─── Dismissible card wrapper ────────────────────────────────────────────────

class _DismissibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const _DismissibleCard({
    super.key,
    required this.child,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

// ─── Empty hint widget ───────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 28, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
