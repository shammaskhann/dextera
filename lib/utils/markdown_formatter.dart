import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Markdown-to-Widget Formatting Engine
//
// Converts markdown-style text into Flutter widgets.
// Supports: **bold**, *italic*, section headers (**Title:**), bullet lists,
//           numbered lists, and paragraph text.
// ─────────────────────────────────────────────────────────────────────────────

/// Parses a markdown string and returns a list of Flutter widgets.
/// Used by the message bubble to render formatted assistant messages.
List<Widget> formatMarkdownToWidgets(String text) {
  if (text.trim().isEmpty) return [];

  final lines = text.split('\n');
  final widgets = <Widget>[];
  final currentListItems = <Widget>[];

  void flushList() {
    if (currentListItems.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.from(currentListItems),
          ),
        ),
      );
      currentListItems.clear();
    }
  }

  for (final rawLine in lines) {
    final line = rawLine.trim();

    // ── Empty line → terminate any open list ──
    if (line.isEmpty) {
      flushList();
      continue;
    }

    // ── Section header:  **Title:** at start of line ──
    final sectionHeaderMatch = RegExp(r'^\*\*(.+?):\*\*(.*)$').firstMatch(line);
    if (sectionHeaderMatch != null) {
      flushList();
      final title = sectionHeaderMatch.group(1)!;
      final trailingText = sectionHeaderMatch.group(2)?.trim() ?? '';

      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: whiteClr.withOpacity(0.12),
                width: 1,
              ),
            ),
          ),
          child: Text(
            '$title:',
            style: TextStyle(
              color: whiteClr,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );

      if (trailingText.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildInlineFormattedText(trailingText),
          ),
        );
      }
      continue;
    }

    // ── Bullet list item:  * item  or  - item ──
    final bulletMatch = RegExp(r'^[\*\-]\s+(.+)$').firstMatch(line);
    if (bulletMatch != null) {

      final itemText = bulletMatch.group(1)!;
      currentListItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10, left: 4),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: whiteClr.withOpacity(0.60),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _buildInlineFormattedText(itemText)),
            ],
          ),
        ),
      );
      continue;
    }

    // ── Numbered list item: 1. item ──
    final numberedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line);
    if (numberedMatch != null) {
      flushList();
      final number = numberedMatch.group(1)!;
      final itemText = numberedMatch.group(2)!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$number.',
                  style: TextStyle(
                    color: whiteClr.withOpacity(0.70),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              Expanded(child: _buildInlineFormattedText(itemText)),
            ],
          ),
        ),
      );
      continue;
    }

    // ── Horizontal rule: --- ──
    if (RegExp(r'^-{3,}$').hasMatch(line)) {
      flushList();
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: whiteClr.withOpacity(0.15), thickness: 1),
        ),
      );
      continue;
    }

    // ── Regular paragraph ──
    flushList();
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _buildInlineFormattedText(line),
      ),
    );
  }

  // Flush any remaining list
  flushList();

  return widgets;
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Formatting: **bold** and *italic*
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a [RichText] widget with inline **bold** and *italic* formatting.
Widget _buildInlineFormattedText(String text) {
  final spans = _parseInlineMarkdown(text);
  return RichText(
    softWrap: true,
    text: TextSpan(children: spans),
  );
}

/// Parses inline markdown and returns a flat list of [TextSpan]s.
/// Supports **bold** and *italic* (non-greedy, non-overlapping).
List<TextSpan> _parseInlineMarkdown(String text) {
  final spans = <TextSpan>[];
  // Pattern: **bold** first, then *italic*
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
  int lastIndex = 0;

  for (final match in pattern.allMatches(text)) {
    // Text before this match
    if (match.start > lastIndex) {
      spans.add(_normalSpan(text.substring(lastIndex, match.start)));
    }

    if (match.group(1) != null) {
      // **bold**
      spans.add(_boldSpan(match.group(1)!));
    } else if (match.group(2) != null) {
      // *italic*
      spans.add(_italicSpan(match.group(2)!));
    }

    lastIndex = match.end;
  }

  // Remaining text
  if (lastIndex < text.length) {
    spans.add(_normalSpan(text.substring(lastIndex)));
  }

  // If no spans were created, add the full text as normal
  if (spans.isEmpty) {
    spans.add(_normalSpan(text));
  }

  return spans;
}

TextSpan _normalSpan(String text) => TextSpan(
      text: text,
      style: TextStyle(
        color: whiteClr.withOpacity(0.78),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
    );

TextSpan _boldSpan(String text) => TextSpan(
      text: text,
      style: TextStyle(
        color: whiteClr.withOpacity(0.92),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.6,
      ),
    );

TextSpan _italicSpan(String text) => TextSpan(
      text: text,
      style: TextStyle(
        color: whiteClr.withOpacity(0.68),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
    );
