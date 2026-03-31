import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FaqsStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;

  const FaqsStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  State<FaqsStep> createState() => _FaqsStepState();
}

class _FaqsStepState extends State<FaqsStep> {
  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  List<Map<String, dynamic>> get _faqs =>
      List<Map<String, dynamic>>.from(widget.formData['faqs'] as List? ?? []);

  void _addFaq() {
    final list = _faqs..add({'question': '', 'answer': ''});
    _update({'faqs': list});
  }

  void _removeFaq(int i) {
    final list = _faqs..removeAt(i);
    _update({'faqs': list});
  }

  void _updateFaq(int i, Map<String, dynamic> patch) {
    final list = _faqs;
    list[i] = {...list[i], ...patch};
    _update({'faqs': list});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final faqs = _faqs;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step Header ──
          Text(
            widget.stepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.stepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.circleQuestion,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Frequently Asked Questions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addFaq,
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
          const SizedBox(height: 8),
          Text(
            'Help attendees by answering common questions.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          if (faqs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.solidCircleQuestion,
                    size: 30,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No FAQs added yet.\nTap "Add" to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          ...List.generate(faqs.length, (i) {
            final faq = faqs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              'Q${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.trashCan,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            onPressed: () => _removeFaq(i),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: faq['question'] as String? ?? '',
                        decoration: const InputDecoration(
                          hintText: 'Question',
                          filled: true,
                          isDense: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: FaIcon(
                              FontAwesomeIcons.circleQuestion,
                              size: 14,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.mdAll,
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => _updateFaq(i, {'question': v}),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: faq['answer'] as String? ?? '',
                        maxLines: 3,
                        minLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Answer',
                          filled: true,
                          isDense: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: FaIcon(FontAwesomeIcons.comment, size: 14),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.mdAll,
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => _updateFaq(i, {'answer': v}),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
