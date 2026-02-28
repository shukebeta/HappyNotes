import 'package:flutter/material.dart';

/// Utility service for markdown text formatting operations.
/// Works with a TextEditingController to wrap/insert markdown syntax.
class MarkdownFormatService {
  /// Wraps the selected text with [prefix] and [suffix].
  /// If no text is selected, inserts prefix+suffix and places cursor between them.
  /// Notifies [onChanged] with the new text.
  static void wrapSelection(
    TextEditingController controller, {
    required String prefix,
    required String suffix,
    required ValueChanged<String> onChanged,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final start = selection.start;
    final end = selection.end;
    final selectedText = selection.textInside(text);

    // Check if already wrapped — if so, unwrap
    if (start >= prefix.length && end + suffix.length <= text.length) {
      final before = text.substring(start - prefix.length, start);
      final after = text.substring(end, end + suffix.length);
      if (before == prefix && after == suffix) {
        final newText = text.substring(0, start - prefix.length) +
            selectedText +
            text.substring(end + suffix.length);
        controller.text = newText;
        controller.selection = TextSelection(
          baseOffset: start - prefix.length,
          extentOffset: end - prefix.length,
        );
        onChanged(newText);
        return;
      }
    }

    final newText = text.substring(0, start) +
        prefix +
        selectedText +
        suffix +
        text.substring(end);
    controller.text = newText;

    if (selectedText.isEmpty) {
      // Place cursor between prefix and suffix
      controller.selection = TextSelection.collapsed(offset: start + prefix.length);
    } else {
      // Keep the text selected (shifted by prefix length)
      controller.selection = TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: end + prefix.length,
      );
    }
    onChanged(newText);
  }

  /// Inserts or toggles a [prefix] at the start of the current line.
  /// If the line already starts with [prefix], it is removed.
  static void toggleLinePrefix(
    TextEditingController controller, {
    required String prefix,
    required ValueChanged<String> onChanged,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final cursorPos = selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', cursorPos > 0 ? cursorPos - 1 : 0);
    final effectiveLineStart = lineStart == -1 ? 0 : lineStart + 1;

    // Check if line already has the prefix
    if (text.length >= effectiveLineStart + prefix.length &&
        text.substring(effectiveLineStart, effectiveLineStart + prefix.length) == prefix) {
      // Remove prefix
      final newText = text.substring(0, effectiveLineStart) +
          text.substring(effectiveLineStart + prefix.length);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: (cursorPos - prefix.length).clamp(effectiveLineStart, newText.length),
      );
      onChanged(newText);
    } else {
      // Add prefix
      final newText = text.substring(0, effectiveLineStart) +
          prefix +
          text.substring(effectiveLineStart);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      );
      onChanged(newText);
    }
  }

  /// Cycles heading level: no heading → # → ## → ### → remove
  static void cycleHeading(
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final cursorPos = selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', cursorPos > 0 ? cursorPos - 1 : 0);
    final effectiveLineStart = lineStart == -1 ? 0 : lineStart + 1;

    // Detect current heading level
    int currentLevel = 0;
    int i = effectiveLineStart;
    while (i < text.length && text[i] == '#') {
      currentLevel++;
      i++;
    }
    // Verify there's a space after the hashes (or it's not a heading)
    if (currentLevel > 0 && i < text.length && text[i] == ' ') {
      // Valid heading — remove current and maybe add next level
      final oldPrefix = '${'#' * currentLevel} ';
      final withoutPrefix = text.substring(0, effectiveLineStart) +
          text.substring(effectiveLineStart + oldPrefix.length);

      if (currentLevel >= 3) {
        // Remove heading entirely
        controller.text = withoutPrefix;
        controller.selection = TextSelection.collapsed(
          offset: (cursorPos - oldPrefix.length).clamp(effectiveLineStart, withoutPrefix.length),
        );
        onChanged(withoutPrefix);
      } else {
        // Upgrade to next level
        final newPrefix = '${'#' * (currentLevel + 1)} ';
        final newText = withoutPrefix.substring(0, effectiveLineStart) +
            newPrefix +
            withoutPrefix.substring(effectiveLineStart);
        controller.text = newText;
        controller.selection = TextSelection.collapsed(
          offset: cursorPos + (newPrefix.length - oldPrefix.length),
        );
        onChanged(newText);
      }
    } else {
      // No heading — add H1
      const newPrefix = '# ';
      final newText = text.substring(0, effectiveLineStart) +
          newPrefix +
          text.substring(effectiveLineStart);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: cursorPos + newPrefix.length,
      );
      onChanged(newText);
    }
  }

  /// Inserts a link template. If text is selected, uses it as the link text.
  static void insertLink(
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);
    final start = selection.start;
    final end = selection.end;

    if (selectedText.isEmpty) {
      const linkTemplate = '[link text](url)';
      final newText = text.substring(0, start) + linkTemplate + text.substring(end);
      controller.text = newText;
      // Select "link text" for easy replacement
      controller.selection = TextSelection(
        baseOffset: start + 1,
        extentOffset: start + 10,
      );
      onChanged(newText);
    } else {
      final linkText = '[$selectedText](url)';  // ignore: prefer_const_declarations
      final newText = text.substring(0, start) + linkText + text.substring(end);
      controller.text = newText;
      // Select "url" for easy replacement
      controller.selection = TextSelection(
        baseOffset: start + selectedText.length + 3,
        extentOffset: start + selectedText.length + 6,
      );
      onChanged(newText);
    }
  }

  /// Inserts a fenced code block. If text is selected, wraps it.
  static void insertCodeBlock(
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
  }) {
    wrapSelection(
      controller,
      prefix: '\n```\n',
      suffix: '\n```\n',
      onChanged: onChanged,
    );
  }

  /// Inserts a horizontal rule at the current cursor position.
  static void insertHorizontalRule(
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final pos = selection.baseOffset;
    const hr = '\n\n---\n\n';
    final newText = text.substring(0, pos) + hr + text.substring(pos);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: pos + hr.length);
    onChanged(newText);
  }
}
