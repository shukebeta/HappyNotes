import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/util.dart';
import 'controllers/markdown_format_service.dart';

/// A unified toolbar for the note editor.
/// In non-markdown mode: shows only M↓ toggle and # tag button.
/// In markdown mode: shows M↓, formatting buttons, upload, paste, and # tag.
class MarkdownToolbar extends StatelessWidget {
  final TextEditingController textController;
  final UndoHistoryController undoController;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isMarkdown;
  final VoidCallback onToggleMarkdown;
  final VoidCallback onTagPressed;
  final VoidCallback? onImageUpload;
  final VoidCallback? onPaste;
  final bool isUploading;
  final bool isPasting;
  final bool isSmallScreen;

  const MarkdownToolbar({
    Key? key,
    required this.textController,
    required this.undoController,
    required this.focusNode,
    required this.onChanged,
    required this.isMarkdown,
    required this.onToggleMarkdown,
    required this.onTagPressed,
    this.onImageUpload,
    this.onPaste,
    this.isUploading = false,
    this.isPasting = false,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final padding = isSmallScreen ? 6.0 : 8.0;

    // Wraps an action to refocus the editor after execution
    VoidCallback withRefocus(VoidCallback action) {
      return () {
        action();
        _refocusEditor();
      };
    }

    return Container(
      height: isSmallScreen ? 36.0 : 40.0,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // M↓ toggle — always visible
          _buildButton(
            tooltip: 'Markdown',
            child: Text(
              'M↓',
              style: TextStyle(
                fontSize: isSmallScreen ? 14.0 : 16.0,
                color: isMarkdown ? Colors.blue : Colors.grey,
                fontWeight: isMarkdown ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: onToggleMarkdown,
            padding: padding,
          ),
          if (!isMarkdown) ...[
            // Non-markdown mode: only # tag button
            _buildButton(
              tooltip: 'Tag',
              icon: Icons.tag,
              iconSize: iconSize,
              iconColor: Colors.grey,
              onTap: onTagPressed,
              padding: padding,
            ),
          ],
          if (isMarkdown) ...[
            _verticalDivider(),
            // Formatting buttons
            _buildButton(
              tooltip: 'Bold',
              child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: iconSize - 2)),
              onTap: withRefocus(() => MarkdownFormatService.wrapSelection(
                textController,
                prefix: '**',
                suffix: '**',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Italic',
              child: Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontSize: iconSize - 2)),
              onTap: withRefocus(() => MarkdownFormatService.wrapSelection(
                textController,
                prefix: '*',
                suffix: '*',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Heading',
              icon: Icons.title,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.cycleHeading(
                textController,
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Strikethrough',
              child: Text('S', style: TextStyle(
                decoration: TextDecoration.lineThrough,
                fontSize: iconSize - 2,
              )),
              onTap: withRefocus(() => MarkdownFormatService.wrapSelection(
                textController,
                prefix: '~~',
                suffix: '~~',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _verticalDivider(),
            _buildButton(
              tooltip: 'Bullet list',
              icon: Icons.format_list_bulleted,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.toggleLinePrefix(
                textController,
                prefix: '- ',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Numbered list',
              icon: Icons.format_list_numbered,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.toggleLinePrefix(
                textController,
                prefix: '1. ',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Quote',
              icon: Icons.format_quote,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.toggleLinePrefix(
                textController,
                prefix: '> ',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _verticalDivider(),
            _buildButton(
              tooltip: 'Inline code',
              child: Text('`', style: TextStyle(
                fontFamily: 'monospace',
                fontSize: iconSize,
                fontWeight: FontWeight.bold,
              )),
              onTap: withRefocus(() => MarkdownFormatService.wrapSelection(
                textController,
                prefix: '`',
                suffix: '`',
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Code block',
              icon: Icons.code,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.insertCodeBlock(
                textController,
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Link',
              icon: Icons.link,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.insertLink(
                textController,
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _buildButton(
              tooltip: 'Horizontal rule',
              icon: Icons.horizontal_rule,
              iconSize: iconSize,
              onTap: withRefocus(() => MarkdownFormatService.insertHorizontalRule(
                textController,
                onChanged: onChanged,
              )),
              padding: padding,
            ),
            _verticalDivider(),
            // Image upload
            if (onImageUpload != null && (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS))
              _buildButton(
                tooltip: 'Add image',
                icon: Icons.add_photo_alternate,
                iconSize: iconSize,
                onTap: onImageUpload!,
                padding: padding,
                isLoading: isUploading,
              ),
            // Paste
            if (onPaste != null && Util.isPasteBoardSupported())
              _buildButton(
                tooltip: 'Paste',
                icon: Icons.paste,
                iconSize: iconSize,
                onTap: onPaste!,
                padding: padding,
                isLoading: isPasting,
              ),
            // Tag
            _buildButton(
              tooltip: 'Tag',
              icon: Icons.tag,
              iconSize: iconSize,
              onTap: onTagPressed,
              padding: padding,
            ),
            _verticalDivider(),
            ValueListenableBuilder<UndoHistoryValue>(
              valueListenable: undoController,
              builder: (context, value, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      tooltip: 'Undo',
                      icon: Icons.undo,
                      iconSize: iconSize,
                      iconColor: value.canUndo ? Colors.black87 : Colors.grey.shade400,
                      onTap: () {
                        if (value.canUndo) {
                          undoController.undo();
                          _refocusEditor();
                        }
                      },
                      padding: padding,
                    ),
                    _buildButton(
                      tooltip: 'Redo',
                      icon: Icons.redo,
                      iconSize: iconSize,
                      iconColor: value.canRedo ? Colors.black87 : Colors.grey.shade400,
                      onTap: () {
                        if (value.canRedo) {
                          undoController.redo();
                          _refocusEditor();
                        }
                      },
                      padding: padding,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Re-requests focus on the editor after a toolbar action,
  /// preserving the cursor position set by MarkdownFormatService.
  void _refocusEditor() {
    // Use post-frame callback to ensure focus is requested after the
    // current frame completes (toolbar button's focus handling is done)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!focusNode.hasFocus) {
        focusNode.requestFocus();
      }
    });
  }

  Widget _buildButton({
    required String tooltip,
    required VoidCallback onTap,
    required double padding,
    IconData? icon,
    double? iconSize,
    Color? iconColor,
    Widget? child,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
          child: isLoading
              ? SizedBox(
                  width: iconSize ?? 20.0,
                  height: iconSize ?? 20.0,
                  child: const CircularProgressIndicator(strokeWidth: 2.0),
                )
              : child ?? Icon(icon, size: iconSize, color: iconColor ?? Colors.black87),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
    );
  }
}
