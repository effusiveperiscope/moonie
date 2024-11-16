import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';

String formatDateTime1(DateTime dateTime) {
  return '${dateTime.year % 100}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String imageMimeFromFilePath(String filePath) {
  return {
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'bmp': 'image/bmp',
        'tiff': 'image/tiff',
      }[filePath.split('.').last.toLowerCase()] ??
      'image/unknown';
}

MarkdownStyleSheet fromThemeWithBaseFontSize(
    BuildContext context, double baseFontSize) {
  final theme = Theme.of(context);
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyLarge!.copyWith(fontSize: baseFontSize),
    h1: theme.textTheme.headlineLarge!.copyWith(fontSize: baseFontSize * 2.5),
    h2: theme.textTheme.headlineMedium!.copyWith(fontSize: baseFontSize * 2),
    h3: theme.textTheme.headlineSmall!.copyWith(fontSize: baseFontSize * 1.75),
    h4: theme.textTheme.titleLarge!.copyWith(fontSize: baseFontSize * 1.5),
    h5: theme.textTheme.titleMedium!.copyWith(fontSize: baseFontSize * 1.25),
    h6: theme.textTheme.titleSmall!.copyWith(fontSize: baseFontSize * 1),
    blockquote: theme.textTheme.bodyLarge!
        .copyWith(fontSize: baseFontSize, fontStyle: FontStyle.italic),
    code: theme.textTheme.bodyLarge!
        .copyWith(fontSize: baseFontSize, fontFamily: 'monospace'),
  );
}
