import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders text that may contain inline LaTeX segments delimited by
/// unescaped `$...$` (the content pipeline's math delimiter convention —
/// see `content/pipeline/types/base.py::check_latex`). Plain runs render as
/// normal text; `$...$` runs render via KaTeX. A lone unmatched `$` (e.g. a
/// trailing currency sign) falls back to literal text for that segment.
class MathText extends StatelessWidget {
  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  static final RegExp _segmentPattern = RegExp(r'\$([^$]+)\$');

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;

    if (!_segmentPattern.hasMatch(text)) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _segmentPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final latex = match.group(1)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            latex,
            mathStyle: MathStyle.text,
            textStyle: effectiveStyle,
            onErrorFallback: (_) => Text(match.group(0)!, style: effectiveStyle),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(style: effectiveStyle, children: spans),
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
