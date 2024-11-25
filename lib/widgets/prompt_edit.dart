import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:moonie/utils.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart' as se;

String wrapPrompt(String prompt) {
  if (!prompt.trim().startsWith('<prompt>')) {
    return '<prompt>$prompt</prompt>';
  }
  return prompt;
}

class PromptEditingController extends TextEditingController {
  final TextStyle? matchedTagStyle, unmatchedTagStyle, reservedTagStyle;
  late final List<String> reservedTags;
  final List<String> knownTags;
  final List<String> unmatchedTags = [];
  String errorMessage = '';
  PromptEditingController({
    super.text,
    this.knownTags = const [],
    this.matchedTagStyle,
    this.unmatchedTagStyle,
    this.reservedTagStyle,
  }) {
    reservedTags = List.from(se.reservedTags);
    _parseXML(text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(style: style, children: _parseXML(text));
  }

  List<TextSpan> _parseXML(String promptText) {
    List<TextSpan> spans = [];
    unmatchedTags.clear();

    void parseNode(XmlNode node) {
      if (node is XmlElement) {
        if (node.children.isEmpty) {
          if (knownTags.contains(node.name.local)) {
            spans.add(TextSpan(style: matchedTagStyle, text: node.outerXml));
          } else if (reservedTags.contains(node.name.local)) {
            spans.add(TextSpan(style: reservedTagStyle, text: node.outerXml));
          } else {
            spans.add(TextSpan(style: unmatchedTagStyle, text: node.outerXml));
            unmatchedTags.add(node.name.local);
          }
        } else {
          final split = splitXml(node);
          if (knownTags.contains(node.name.local)) {
            spans.add(TextSpan(style: matchedTagStyle, text: split[0]));
          } else if (reservedTags.contains(node.name.local)) {
            spans.add(TextSpan(style: reservedTagStyle, text: split[0]));
          } else {
            spans.add(TextSpan(style: unmatchedTagStyle, text: split[0]));
            unmatchedTags.add(node.name.local);
          }
          for (final child in node.children) {
            parseNode(child);
          }
          if (knownTags.contains(node.name.local)) {
            spans.add(TextSpan(style: matchedTagStyle, text: split[2]));
          } else if (reservedTags.contains(node.name.local)) {
            spans.add(TextSpan(style: reservedTagStyle, text: split[2]));
          } else {
            spans.add(TextSpan(style: unmatchedTagStyle, text: split[2]));
          }
        }
      } else {
        spans.add(TextSpan(text: node.toXmlString()));
      }
    }

    try {
      final wrappedPrompt = wrapPrompt(promptText);
      final document = XmlDocument.parse(wrappedPrompt);
      final prompt = document.rootElement;
      for (final child in prompt.children.toList()) {
        parseNode(child);
      }
      // Problem: This is executed during building
      // So computing the error message now won't display anything until the user edits the prompt
      //errorMessage = '';
    } catch (e) {
      //errorMessage = e.toString();
      return [TextSpan(style: null, text: promptText)];
    }

    return spans;
  }
}
