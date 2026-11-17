import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Renderizador mínimo de Markdown para os artigos: parágrafos, títulos,
/// listas, listas numeradas e **negrito**. Não depende de pacote externo e
/// funciona no modo offline como qualquer outro texto.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.color = Colors.white,
    this.lineHeight = 1.65,
  });

  final String text;
  final double fontSize;
  final Color color;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: color, fontSize: fontSize, height: lineHeight);
    final blocks = <Widget>[];
    final paragraph = <String>[];
    var lastWasList = false;

    void addBlock(Widget widget, {required bool listItem}) {
      if (blocks.isNotEmpty) {
        blocks.add(SizedBox(height: listItem && lastWasList ? 8 : 16));
      }
      blocks.add(widget);
      lastWasList = listItem;
    }

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      addBlock(Text.rich(_inline(paragraph.join(' '), base)), listItem: false);
      paragraph.clear();
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        flushParagraph();
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        flushParagraph();
        final level = heading.group(1)!.length;
        final size = switch (level) {
          1 => fontSize * 1.5,
          2 => fontSize * 1.3,
          _ => fontSize * 1.15,
        };
        addBlock(
          Text(
            heading.group(2)!.trim(),
            style: TextStyle(
              color: level <= 2 ? AppColors.yellow : color,
              fontSize: size,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          listItem: false,
        );
        continue;
      }

      final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        addBlock(_listItem('•', bullet.group(1)!, base), listItem: true);
        continue;
      }

      final numbered = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (numbered != null) {
        flushParagraph();
        addBlock(_listItem('${numbered.group(1)}.', numbered.group(2)!, base), listItem: true);
        continue;
      }

      paragraph.add(line);
    }
    flushParagraph();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  Widget _listItem(String marker, String text, TextStyle base) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(marker, style: base.copyWith(fontWeight: FontWeight.w800, color: AppColors.yellow)),
        ),
        Expanded(child: Text.rich(_inline(text, base))),
      ],
    );
  }

  TextSpan _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: base.copyWith(fontWeight: FontWeight.w800),
      ));
      start = match.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(style: base, children: spans);
  }
}
