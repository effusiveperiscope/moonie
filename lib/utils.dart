import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'dart:io';
import 'dart:convert';
import 'package:png_chunks_extract/png_chunks_extract.dart' as png_extract;
import 'package:flutter/foundation.dart';

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

String cleanHtml(String rawPage) {
  final soup = BeautifulSoup(rawPage);

  final tagsToPrune = [
    'script',
    'style',
    'noscript',
    'meta',
    'link',
    'form',
    'iframe',
    'button',
    'input',
    'textarea',
    'nav',
    'footer',
    'aside',
    'svg',
  ];
  for (final tag in tagsToPrune) {
    soup.findAll(tag).forEach((e) => e.decompose());
  }
  return soup.getText();
}

String cleanPlainText(String input) {
  // Remove consecutive newlines
  input = input.replaceAll(RegExp(r'\n\s*\n+'), '\n');

  // Trim leading and trailing spaces
  return input.trim();
}

bool isPNG(Uint8List data) {
  const List<int> pngMagicNumber = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A
  ];
  return data.length >= pngMagicNumber.length &&
      listEquals(data.sublist(0, pngMagicNumber.length), pngMagicNumber);
}

Map<String, dynamic> _readTavernCardFromPNG(Uint8List fileBytes) {
  final chunks = png_extract.extractChunks(fileBytes);
  for (var chunk in chunks) {
    if (chunk['name'] == 'tEXt') {
      Uint8List data = chunk['data'];
      int nullSeparatorIndex = data.indexOf(0);
      String keyword = utf8.decode(data.sublist(0, nullSeparatorIndex));
      if (keyword.toLowerCase() == 'chara') {
        String text = utf8.decode(data.sublist(nullSeparatorIndex + 1));
        text = utf8.decode(base64.decode(text));
        return jsonDecode(text);
      }
    }
  }
  throw Exception('Could not find Tavern data in image');
}

Map<String, dynamic> _readTavernCard(String path) {
  final fileBytes = File(path).readAsBytesSync();
  Map<String, dynamic> tempData;
  if (isPNG(fileBytes)) {
    tempData = _readTavernCardFromPNG(fileBytes);
  } else {
    // Assume it's a JSON.
    tempData = jsonDecode(utf8.decode(fileBytes));
  }
  Map<String, dynamic> data;
  if (tempData.containsKey('spec_version')) {
    if (tempData['spec_version'] == '2.0') {
      data = tempData['data'];
      data['spec_version'] = '2.0';
    } else {
      throw Exception('Unknown spec version ${tempData['spec_version']}');
    }
  } else {
    // Assume 1.0 if version is not specified
    data = tempData;
    data['spec_version'] = '1.0';
  }
  return data;
}

class TavernCard {
  String name = '',
      description = '',
      personality = '',
      scenario = '',
      firstMes = '',
      mesExample = '',
      creatorNotes = '',
      systemPrompt = '',
      postHistoryInstructions = '',
      creator = '',
      characterVersion = '',
      specVersion = '';
  File? imageFile;
  List<String> alternateGreetings = [];
  List<String> tags = [];
  // Character lorebooks currently considered out of scope.

  String replaceCharName(String input) {
    return input.replaceAll('{{char}}', name);
  }

  String cardSummary() {
    int maxChars = 300;
    String descriptionTrunc = description.length > maxChars
        ? description.substring(0, maxChars) + '...'
        : description;
    return 'Name: $name\nDescription: ${replaceCharName(descriptionTrunc)}';
  }

  String cardBody() {
    return 'Name: $name\nDescription: ${replaceCharName(description)}'
        '\nPersonality: ${replaceCharName(personality)}'
        '\nScenario: ${replaceCharName(scenario)}'
        '\nExample messages: ${replaceCharName(mesExample)}';
  }

  static TavernCard fromTavernPath(String path) {
    var tavernData = _readTavernCard(path);
    TavernCard ret = TavernCard();
    ret.name = tavernData['name'];
    ret.description = tavernData['description'];
    ret.personality = tavernData['personality'];
    ret.scenario = tavernData['scenario'];
    ret.firstMes = tavernData['first_mes'];
    ret.mesExample = tavernData['mes_example'];
    ret.specVersion = tavernData['spec_version'];
    ret.imageFile = File(path);
    if (tavernData['spec_version'] == '2.0') {
      ret.creatorNotes = tavernData['creator_notes'];
      ret.systemPrompt = tavernData['system_prompt'];
      ret.postHistoryInstructions = tavernData['post_history_instructions'];
      ret.creator = tavernData['creator'];
      ret.characterVersion = tavernData['character_version'];
      for (String s in tavernData['alternate_greetings']) {
        ret.alternateGreetings.add(s);
      }
      for (String s in tavernData['tags']) {
        ret.tags.add(s);
      }
    }
    return ret;
  }
}

String sanitizeTagName(String input) {
  String ret = input.replaceAll(' ', '_');
  ret = ret.replaceAll('/', '_');
  ret = ret.replaceAll('\\', '_');
  ret = ret.replaceAll('.', '_');
  ret = ret.replaceAll(',', '_');
  ret = ret.replaceAll('?', '_');
  ret = ret.replaceAll('!', '_');
  ret = ret.replaceAll('*', '_');
  ret = ret.replaceAll('\\(', '_');
  ret = ret.replaceAll('\\)', '_');
  ret = ret.replaceAll('[', '_');
  ret = ret.replaceAll(']', '_');
  ret = ret.replaceAll('{', '_');
  ret = ret.replaceAll('}', '_');
  ret = ret.replaceAll('\\|', '_');
  ret = ret.replaceAll('\\<', '_');
  ret = ret.replaceAll('\\>', '_');

  if (ret.startsWith('_')) {
    ret = ret.substring(1);
  }

  if (ret.startsWith('0-9')) {
    ret = 'x$ret';
  }

  return ret;
}

bool testXMLTagName(String tag) {
  RegExp tagExp = RegExp(r'^[A-Za-z_][A-Za-z0-9._-]*$');
  return tagExp.hasMatch(tag);
}
