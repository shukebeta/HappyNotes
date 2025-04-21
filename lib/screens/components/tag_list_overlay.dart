import 'package:flutter/material.dart';
import 'dart:async';
import '../../dependency_injection.dart';
import '../../services/note_tag_service.dart';
import '../../models/note_model.dart';
import '../../models/tag_count.dart';
import './tag_cloud.dart';

class TagListOverlay extends StatefulWidget {
  final NoteModel noteModel;
  final String text;
  final int cursorPosition;
  final Function(String, int, String) onTagSelected;

  const TagListOverlay({
    Key? key,
    required this.noteModel,
    required this.text,
    required this.cursorPosition,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  TagListOverlayState createState() => TagListOverlayState();
}

class TagListOverlayState extends State<TagListOverlay> {
  late NoteTagService noteTagService;
  OverlayEntry? _tagListOverlay;
  Timer? _tagListTimer;
  Map<String, int> tagsToShow = {};
  static const int _maxTagsToShow = 15;
  static const double _overlayHeight = 200.0;
  static const double _overlayElevation = 8.0;
  static const double _standardLineHeight = 24.0;

  @override
  void initState() {
    super.initState();
    noteTagService = locator<NoteTagService>();
    _fetchTags();
  }

  @override
  void dispose() {
    _tagListTimer?.cancel();
    _tagListOverlay?.remove();
    super.dispose();
  }

  void _fetchTags() async {
    try {
      final tagCloud = await noteTagService.getMyTagCloud();
      final tags = Map<String, int>.fromEntries(tagCloud
          .take(_maxTagsToShow)
          .map((item) => MapEntry(item.tag, item.count)));
      setState(() {
        tagsToShow = tags;
      });
      if (tags.isNotEmpty) {
        _createAndShowTagListOverlay();
      }
    } catch (e) {
      print('Error fetching tag cloud: $e');
    }
  }

  void _createAndShowTagListOverlay() {
    Future.microtask(() {
      if (!mounted) return;

      final overlayWidth = _calculateOverlayWidth(tagsToShow.keys.toList());
      final (top, left) = _calculateOverlayPosition(
        widget.noteModel,
        widget.cursorPosition,
        overlayWidth,
        _overlayHeight,
      );

      _tagListOverlay = OverlayEntry(
        builder: (context) => Positioned(
          top: top,
          left: left,
          width: overlayWidth,
          child: Material(
            elevation: _overlayElevation,
            borderRadius: BorderRadius.circular(4.0),
            color: Colors.grey[200],
            child: Container(
              padding: const EdgeInsets.all(8.0),
              height: _overlayHeight,
              child: TagCloud(
                tagData: tagsToShow,
                onTagTap: (tag) {
                  widget.onTagSelected(
                    widget.text,
                    widget.cursorPosition,
                    tag,
                  );
                  _tagListOverlay?.remove();
                  _tagListOverlay = null;
                },
              ),
            ),
          ),
        ),
      );

      if (mounted) {
        Overlay.of(context).insert(_tagListOverlay!);
      }
    });
  }

  (double top, double left) _calculateOverlayPosition(
    NoteModel noteModel,
    int cursorPosition,
    double overlayWidth,
    double overlayHeight,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final renderObject =
        noteModel.focusNode.context?.findRenderObject() as RenderBox?;
    if (renderObject == null) {
      return (0, 0);
    }

    final offset = renderObject.localToGlobal(Offset.zero);
    final linePosition = _getCursorLinePosition(cursorPosition);
    final horizontalPosition = _getCursorHorizontalPosition(cursorPosition);

    double top = offset.dy + linePosition;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final effectiveScreenHeight = screenHeight - keyboardHeight;

    final bottomHalf = top > (effectiveScreenHeight / 2);
    final nearBottom = top + overlayHeight + 50 > effectiveScreenHeight;

    if (bottomHalf || nearBottom) {
      top = top - overlayHeight - 50;
      if (top < 10) top = 10;
    } else {
      top += _standardLineHeight;
    }

    double left = offset.dx + horizontalPosition;
    if (left + overlayWidth > screenWidth) {
      left = screenWidth - overlayWidth - 10;
      if (left < 10) left = 10;
    }
    left = left < 10 ? 10 : left;

    return (top, left);
  }

  double _getCursorLinePosition(int cursorPosition) {
    final text = widget.text.substring(0, cursorPosition);
    final lines = text.split('\n');
    final cursorLine = lines.length - 1;
    const lineHeight = 24.0;
    return cursorLine * lineHeight;
  }

  double _getCursorHorizontalPosition(int cursorPosition) {
    final text = widget.text.substring(0, cursorPosition);
    final lines = text.split('\n');
    final currentLine = lines.isNotEmpty ? lines.last : '';
    const charWidth = 9.0;
    return currentLine.length * charWidth;
  }

  double _calculateOverlayWidth(List<String> tags) {
    if (tags.isEmpty) return 300.0;
    final longestTag = tags.reduce((a, b) => a.length > b.length ? a : b);
    return longestTag.length * 10.0 + 40.0;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
