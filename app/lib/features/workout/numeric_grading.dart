import '../../data/models.dart';

/// Grades a typed numeric answer against [question]'s `numericAnswer`.
///
/// Whitespace is ignored. When the question carries no `tolerance`, this is
/// an exact string match — unchanged from the original behaviour, so levels
/// that don't need tolerance grade exactly as before. When it does, both
/// sides are parsed as numbers (a plain decimal like `85.33`, or a simple
/// fraction like `256/3`) and accepted if `|input - answer| <= tolerance`;
/// if either side can't be parsed, it falls back to the exact match.
bool isNumericAnswerCorrect(Question question, String rawInput) {
  final input = rawInput.trim().replaceAll(' ', '');
  final answer = question.numericAnswer;
  if (answer == null || input.isEmpty) return false;

  final tolerance = question.tolerance;
  if (tolerance == null) return input == answer;

  final inputValue = parseNumericInput(input);
  final answerValue = parseNumericInput(answer.replaceAll(' ', ''));
  if (inputValue == null || answerValue == null) return input == answer;
  // A tiny epsilon absorbs binary floating-point noise at the boundary
  // (e.g. 487.77 - 487.67 evaluates to 0.10000000000002274).
  return (inputValue - answerValue).abs() <= tolerance + 1e-9;
}

/// Parses `12`, `-3.5`, `.5`, or a simple fraction `256/3`. Returns null for
/// anything else (including division by zero).
double? parseNumericInput(String s) {
  final slash = s.indexOf('/');
  if (slash == -1) return double.tryParse(s);
  if (s.indexOf('/', slash + 1) != -1) return null;
  final numerator = double.tryParse(s.substring(0, slash));
  final denominator = double.tryParse(s.substring(slash + 1));
  if (numerator == null || denominator == null || denominator == 0) return null;
  return numerator / denominator;
}
