/// Utility for escaping user-controlled strings to prevent injection in
/// Flutter text rendering contexts. While Flutter's [Text] widget is safe,
/// this is used when constructing strings that might be displayed via
/// [RichText] / [TextSpan] or when dealing with filenames / external data.
class HtmlEscape {
  /// Escapes characters that could be problematic in display contexts.
  /// Replaces &, <, >, ", ' with safe equivalents.
  static String escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Safely truncates content to [maxLength] characters, appending "…" if
  /// truncated. The input is escaped before truncation check.
  static String truncate(String input, {int maxLength = 300}) {
    final escaped = escape(input);
    if (escaped.length <= maxLength) return escaped;
    return '${escaped.substring(0, maxLength)}…';
  }
}
