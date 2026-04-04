import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillReadOnlyView extends StatefulWidget {
  final String deltaJson;

  const QuillReadOnlyView({super.key, required this.deltaJson});

  @override
  State<QuillReadOnlyView> createState() => _QuillReadOnlyViewState();
}

class _QuillReadOnlyViewState extends State<QuillReadOnlyView> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.deltaJson);
  }

  @override
  void didUpdateWidget(covariant QuillReadOnlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deltaJson != widget.deltaJson) {
      _controller.dispose();
      _controller = _buildController(widget.deltaJson);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  QuillController _buildController(String deltaJson) {
    final document = () {
      try {
        return quillDocumentFromString(deltaJson);
      } catch (_) {
        return Document.fromJson(const [
          {'insert': '\n'},
        ]);
      }
    }();
    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.readOnly = true;
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: _controller,
      config: const QuillEditorConfig(
        padding: EdgeInsets.zero,
        scrollable: false,
        showCursor: false,
      ),
    );
  }
}
