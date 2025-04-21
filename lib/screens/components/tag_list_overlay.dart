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
  static const int _maxTagsToShow = 25;
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final effectiveScreenHeight = screenHeight - keyboardHeight;

    // Position the overlay in the center of the screen
    double top = (effectiveScreenHeight - overlayHeight) / 2;
    double left = (screenWidth - overlayWidth) / 2;

    // Ensure the overlay stays within screen bounds
    top = top < 10 ? 10 : top;
    left = left < 10 ? 10 : left;

    return (top, left);
  }

  double _calculateOverlayWidth(List<String> tags) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use 80% of screen width for the overlay, with min and max constraints
    return screenWidth * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
