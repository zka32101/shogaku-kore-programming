import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/glossary_data.dart';
import '../models/glossary_term.dart';

class _TermMatch {
  final int start;
  final int end;
  final GlossaryTerm term;
  _TermMatch(this.start, this.end, this.term);
}

/// 専門用語をタップ可能にして、やさしい解説をポップアップ表示するテキスト。
/// テキスト中に kGlossaryTerms の用語が含まれていれば、その部分だけ
/// 下線付きハイライトになり、タップで解説シートが開く。
class GlossaryText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GlossaryText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  final List<TapGestureRecognizer> _recognizers = [];

  List<_TermMatch> _findMatches() {
    final text = widget.text;
    final candidates = kGlossaryTerms.where((t) => text.contains(t.term)).toList()
      ..sort((a, b) => b.term.length.compareTo(a.term.length));

    final matches = <_TermMatch>[];
    for (final term in candidates) {
      int start = 0;
      while (true) {
        final idx = text.indexOf(term.term, start);
        if (idx == -1) break;
        final end = idx + term.term.length;
        final overlaps = matches.any((m) => idx < m.end && end > m.start);
        if (!overlaps) {
          matches.add(_TermMatch(idx, end, term));
        }
        start = idx + term.term.length;
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final text = widget.text;
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final matches = _findMatches();

    if (matches.isEmpty) {
      return Text(text, style: baseStyle, textAlign: widget.textAlign);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => showGlossaryPopup(context, m.term);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: baseStyle.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: kPrimaryColor,
        ),
        recognizer: recognizer,
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }
}

void showGlossaryPopup(BuildContext context, GlossaryTerm term) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GlossaryPopupSheet(term: term),
  );
}

class _GlossaryPopupSheet extends StatelessWidget {
  final GlossaryTerm term;
  const _GlossaryPopupSheet({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(term.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.term,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      term.friendlyName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            term.explanation,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    term.example,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('わかった！'),
            ),
          ),
        ],
      ),
    );
  }
}
