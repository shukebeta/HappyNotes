import 'package:flutter/material.dart';
import 'controllers/markdown_format_service.dart';

/// A horizontal scrollable toolbar with markdown formatting buttons.
/// Shown when markdown mode is enabled in the note editor.
class MarkdownToolbar extends StatelessWidget {
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final bool isSmallScreen;

  const MarkdownToolbar({
    Key? key,
    required this.textController,
    required this.onChanged,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final padding = isSmallScreen ? 6.0 : 8.0;

    return SizedBox(
      height: isSmallScreen ? 36.0 : 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildButton(
            tooltip: 'Bold',
            child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: iconSize - 2)),
            onTap: () => MarkdownFormatService.wrapSelection(
              textController,
              prefix: '**',
              suffix: '**',
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Italic',
            child: Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontSize: iconSize - 2)),
            onTap: () => MarkdownFormatService.wrapSelection(
              textController,
              prefix: '*',
              suffix: '*',
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Heading',
            icon: Icons.title,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.cycleHeading(
              textController,
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Strikethrough',
            child: Text('S', style: TextStyle(
              decoration: TextDecoration.lineThrough,
              fontSize: iconSize - 2,
            )),
            onTap: () => MarkdownFormatService.wrapSelection(
              textController,
              prefix: '~~',
              suffix: '~~',
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _verticalDivider(),
          _buildButton(
            tooltip: 'Bullet list',
            icon: Icons.format_list_bulleted,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.toggleLinePrefix(
              textController,
              prefix: '- ',
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Numbered list',
            icon: Icons.format_list_numbered,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.toggleLinePrefix(
              textController,
              prefix: '1. ',
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Quote',
            icon: Icons.format_quote,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.toggleLinePrefix(
              textController,
              prefix: '> ',
              onChanged: onChanged,
            ),
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
            onTap: () => MarkdownFormatService.wrapSelection(
              textController,
              prefix: '`',
              suffix: '`',
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Code block',
            icon: Icons.code,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.insertCodeBlock(
              textController,
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Link',
            icon: Icons.link,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.insertLink(
              textController,
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Horizontal rule',
            icon: Icons.horizontal_rule,
            iconSize: iconSize,
            onTap: () => MarkdownFormatService.insertHorizontalRule(
              textController,
              onChanged: onChanged,
            ),
            padding: padding,
          ),
          _verticalDivider(),
          _buildButton(
            tooltip: 'Undo',
            icon: Icons.undo,
            iconSize: iconSize,
            onTap: () {
              // Trigger undo via the Actions framework
              final primaryContext = textController.selection.isValid
                  ? FocusManager.instance.primaryFocus?.context
                  : null;
              if (primaryContext != null) {
                Actions.maybeInvoke(primaryContext, const UndoTextIntent(SelectionChangedCause.toolbar));
              }
            },
            padding: padding,
          ),
          _buildButton(
            tooltip: 'Redo',
            icon: Icons.redo,
            iconSize: iconSize,
            onTap: () {
              final primaryContext = textController.selection.isValid
                  ? FocusManager.instance.primaryFocus?.context
                  : null;
              if (primaryContext != null) {
                Actions.maybeInvoke(primaryContext, const RedoTextIntent(SelectionChangedCause.toolbar));
              }
            },
            padding: padding,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String tooltip,
    required VoidCallback onTap,
    required double padding,
    IconData? icon,
    double? iconSize,
    Widget? child,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
          child: child ?? Icon(icon, size: iconSize, color: Colors.black87),
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
