/// Utilities for sanitising teacher-supplied text before it is sent to an AI
/// model or stored in the database.
class InputSanitiser {
  const InputSanitiser._();

  static final _htmlTagPattern = RegExp(r'<[^>]*>', multiLine: true);
  static final _scriptPattern =
      RegExp(r'<script[\s\S]*?</script>', caseSensitive: false);
  static final _controlCharsPattern =
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  /// Strips HTML tags, script blocks, and control characters from [input].
  /// Safe to call on any user-facing text field before AI submission.
  static String sanitise(String input) {
    var result = input;
    result = result.replaceAll(_scriptPattern, '');
    result = result.replaceAll(_htmlTagPattern, '');
    result = result.replaceAll(_controlCharsPattern, '');
    return result.trim();
  }

  /// Truncates [input] to [maxLength] characters, appending '[Truncated]' if
  /// the text was cut. Prevents oversized payloads to the AI endpoint.
  static String truncate(String input, {int maxLength = 8000}) {
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength)}\n[Truncated]';
  }

  /// Convenience method: sanitise then truncate.
  static String sanitiseAndTruncate(String input, {int maxLength = 8000}) =>
      truncate(sanitise(input), maxLength: maxLength);
}
