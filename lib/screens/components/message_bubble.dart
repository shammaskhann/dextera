// // ----------------------------
// // Message Content Parser
// // ----------------------------
// import 'package:dextera/models/chat_message.dart';
// import 'package:flutter/material.dart';

// Widget _buildMessageContent(String text) {
//   // Split the text into sections based on headings
//   final sections = _parseMessageSections(text);

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       // Main content sections
//       for (final section in sections) _buildMessageSection(section),

//       // Case examples if present
//       if (_hasCaseExamples(text)) _buildCaseExampleSection(text),
//     ],
//   );
// }

// // Parse the message into logical sections
// List<Map<String, dynamic>> _parseMessageSections(String text) {
//   final sections = <Map<String, dynamic>>[];
//   final lines = text.split('\n');
//   final sectionRegExp = RegExp(r'^[A-Z][a-zA-Z\s]+:$');

//   Map<String, dynamic>? currentSection;

//   for (final line in lines) {
//     final trimmedLine = line.trim();

//     // Skip empty lines at the start
//     if (trimmedLine.isEmpty && currentSection == null) continue;

//     // Check if line is a section header
//     if (sectionRegExp.hasMatch(trimmedLine) &&
//         !trimmedLine.startsWith('Example') &&
//         !trimmedLine.startsWith('Case')) {
//       // Save previous section if exists
//       if (currentSection != null) {
//         sections.add(currentSection);
//       }

//       // Start new section
//       currentSection = {
//         'title': trimmedLine.replaceAll(':', ''),
//         'content': '',
//         'items': [],
//       };
//     } else if (currentSection != null) {
//       // Check if line is a bullet point
//       if (trimmedLine.startsWith('* ')) {
//         final bulletText = trimmedLine.substring(2).trim();
//         final boldParts = _parseBoldText(bulletText);
//         currentSection['items'].add({
//           'text': bulletText,
//           'boldParts': boldParts,
//         });
//       } else if (trimmedLine.isNotEmpty) {
//         // Add to content
//         if (currentSection['content'].isNotEmpty) {
//           currentSection['content'] += '\n';
//         }
//         currentSection['content'] += trimmedLine;
//       }
//     } else {
//       // This is content before any section header
//       if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('---')) {
//         if (currentSection == null) {
//           currentSection = {'title': '', 'content': trimmedLine, 'items': []};
//         } else {
//           currentSection['content'] += '\n$trimmedLine';
//         }
//       }
//     }
//   }

//   // Add the last section
//   if (currentSection != null) {
//     sections.add(currentSection);
//   }

//   return sections;
// }

// // Parse bold text marked with *asterisks*
// List<Map<String, dynamic>> _parseBoldText(String text) {
//   final boldParts = <Map<String, dynamic>>[];
//   final boldPattern = RegExp(r'\*\s(.*?)\s\*');

//   int lastIndex = 0;
//   final matches = boldPattern.allMatches(text);

//   for (final match in matches) {
//     // Add text before bold
//     if (match.start > lastIndex) {
//       boldParts.add({
//         'text': text.substring(lastIndex, match.start),
//         'isBold': false,
//       });
//     }

//     // Add bold text
//     boldParts.add({'text': match.group(1)!, 'isBold': true});

//     lastIndex = match.end;
//   }

//   // Add remaining text
//   if (lastIndex < text.length) {
//     boldParts.add({'text': text.substring(lastIndex), 'isBold': false});
//   }

//   return boldParts;
// }

// // Check if text contains case examples
// bool _hasCaseExamples(String text) {
//   return text.contains('--RELEVANT JUDICIAL PRECEDENT') ||
//       text.contains('Case Name:');
// }

// // Build case example section
// Widget _buildCaseExampleSection(String text) {
//   final caseExamples = _extractCaseExamples(text);

//   if (caseExamples.isEmpty) return const SizedBox();

//   return Container(
//     margin: const EdgeInsets.only(top: 20),
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: const Color(0xFF1A1F27),
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: const Color(0xFF2B3540)),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.gavel, color: Colors.amber, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               'Case Examples',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         for (final example in caseExamples) _buildCaseExample(example),
//       ],
//     ),
//   );
// }

// // Extract case examples from text
// Set<Map<String, dynamic>> _extractCaseExamples(String text) {
//   final examples = <Map<String, dynamic>>{};
//   final lines = text.split('\n');
//   final exampleStartPattern = RegExp(
//     r'--*RELEVANT JUDICIAL PRECEDENT--*',
//     caseSensitive: false,
//   );
//   final caseNamePattern = RegExp(r'^Case Name:\s*(.+)$', caseSensitive: false);

//   Map<String, dynamic>? currentExample;

//   for (int i = 0; i < lines.length; i++) {
//     final line = lines[i].trim();

//     // Check for example start
//     if (exampleStartPattern.hasMatch(line)) {
//       if (currentExample != null) {
//         examples.add(currentExample);
//       }
//       currentExample = {'caseName': '', 'content': ''};
//     } else if (currentExample != null) {
//       // Check for case name
//       final caseNameMatch = caseNamePattern.firstMatch(line);
//       if (caseNameMatch != null) {
//         currentExample['caseName'] = caseNameMatch.group(1)!.trim();
//       } else if (line.isNotEmpty && !line.startsWith('---')) {
//         // Add to content
//         if (currentExample['content'].isNotEmpty) {
//           currentExample['content'] += '\n';
//         }
//         currentExample['content'] += line;
//       }
//     }
//   }

//   // Add the last example
//   if (currentExample != null && currentExample['caseName'].isNotEmpty) {
//     examples.add(currentExample);
//   }

//   // Fallback: Extract any case-like structure
//   if (examples.isEmpty) {
//     final fallbackExamples = _extractFallbackCaseExamples(text);
//     examples.addAll(fallbackExamples);
//   }

//   return examples;
// }

// // Fallback extraction for case examples
// List<Map<String, dynamic>> _extractFallbackCaseExamples(String text) {
//   final examples = <Map<String, dynamic>>[];
//   final casePattern = RegExp(
//     r'Case[:\s]+([^\.]+)\.?\s*(.+?)(?=(Case|$))',
//     caseSensitive: true,
//     dotAll: true,
//   );

//   final matches = casePattern.allMatches(text);

//   for (final match in matches) {
//     if (match.groupCount >= 2) {
//       examples.add({
//         'caseName': match.group(1)!.trim(),
//         'content': match.group(2)!.trim(),
//       });
//     }
//   }

//   return examples;
// }

// // Build individual case example
// Widget _buildCaseExample(Map<String, dynamic> example) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 16),
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       color: const Color(0xFF252D39),
//       borderRadius: BorderRadius.circular(8),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (example['caseName'].isNotEmpty)
//           Text(
//             example['caseName'],
//             style: TextStyle(
//               color: Colors.amber,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         if (example['content'].isNotEmpty) ...[
//           const SizedBox(height: 8),
//           Text(
//             example['content'],
//             style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
//           ),
//         ],
//       ],
//     ),
//   );
// }

// // Build a message section
// Widget _buildMessageSection(Map<String, dynamic> section) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 16),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section title
//         if (section['title'].isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: Text(
//               section['title'],
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 16,
//                 height: 1.3,
//               ),
//             ),
//           ),

//         // Section content
//         if (section['content'].isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: Text(
//               section['content'],
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//                 height: 1.5,
//               ),
//             ),
//           ),

//         // Bullet points
//         if ((section['items'] as List).isNotEmpty)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               for (final item in section['items'] as List)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(top: 1, right: 8),
//                         child: Icon(
//                           Icons.circle,
//                           size: 6,
//                           color: Colors.white70,
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildBoldText(
//                           item['boldParts'] as List<Map<String, dynamic>>,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//       ],
//     ),
//   );
// }

// // Build text with bold parts
// Widget _buildBoldText(List<Map<String, dynamic>> boldParts) {
//   return RichText(
//     text: TextSpan(
//       children: [
//         for (final part in boldParts)
//           TextSpan(
//             text: part['text'],
//             style: TextStyle(
//               color: Colors.white70,
//               fontWeight: part['isBold'] ? FontWeight.w700 : FontWeight.normal,
//               fontSize: 14,
//               height: 1.5,
//             ),
//           ),
//       ],
//     ),
//   );
// }

// // Update the message bubble to use the parser
// Widget BuildMessageBubble(ChatMessage m, BuildContext context) {
//   final bg = m.isUser ? Colors.white : const Color(0xFF2B3540);
//   final textColor = m.isUser ? Colors.black : Colors.white;
//   final bubbleRadius = BorderRadius.circular(12);

//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8),
//     child: Row(
//       mainAxisAlignment: m.isUser
//           ? MainAxisAlignment.end
//           : MainAxisAlignment.start,
//       children: [
//         ConstrainedBox(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.62,
//           ),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(color: bg, borderRadius: bubbleRadius),
//             child: m.isUser
//                 ? Text(m.text, style: TextStyle(color: textColor))
//                 : _buildMessageContent(m.text),
//           ),
//         ),
//       ],
//     ),
//   );
// }
// ----------------------------
// Message Content Parser
// ----------------------------
import 'package:dextera/models/chat_message.dart';
import 'package:flutter/material.dart';

Widget _buildMessageContent(String text) {
  // 1. Split the text to prevent duplicate Case Examples
  // Find the separator for case examples
  final separatorIndex = text.toUpperCase().indexOf(
    '--RELEVANT JUDICIAL PRECEDENT',
  );

  String mainContent = text;
  String caseContent = "";

  if (separatorIndex != -1) {
    mainContent = text.substring(0, separatorIndex).trim();
    caseContent = text.substring(
      separatorIndex,
    ); // Keep separator for extraction logic
  }

  final sections = _parseMessageSections(mainContent);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Main content sections
      for (final section in sections) _buildMessageSection(section),

      // Case examples if present (Only from the extracted part)
      if (caseContent.isNotEmpty) _buildCaseExampleSection(caseContent),
    ],
  );
}

// Parse the message into logical sections
List<Map<String, dynamic>> _parseMessageSections(String text) {
  final sections = <Map<String, dynamic>>[];
  final lines = text.split('\n');
  // Regex to detect headers like "Header:" or "HEADER:"
  final sectionRegExp = RegExp(r'^[A-Z][a-zA-Z\s]+:$');

  Map<String, dynamic>? currentSection;

  for (final line in lines) {
    final trimmedLine = line.trim();

    // Skip empty lines at the start
    if (trimmedLine.isEmpty && currentSection == null) continue;

    // Check if line is a section header (excluding 'Case' or 'Example' keywords to avoid conflicts)
    if (sectionRegExp.hasMatch(trimmedLine) &&
        !trimmedLine.contains('Case') &&
        !trimmedLine.contains('Example')) {
      // Save previous section if exists
      if (currentSection != null) {
        sections.add(currentSection);
      }

      // Start new section
      currentSection = {
        'title': trimmedLine.replaceAll(':', ''),
        'content': '',
        'items': [],
      };
    } else if (currentSection != null) {
      // Check if line is a bullet point
      if (trimmedLine.startsWith('* ')) {
        final bulletText = trimmedLine.substring(2).trim();
        // Parse bold text within the bullet point
        final boldParts = _parseBoldText(bulletText);
        currentSection['items'].add({
          'text': bulletText,
          'boldParts': boldParts,
        });
      } else if (trimmedLine.isNotEmpty) {
        // Add to content
        if (currentSection['content'].isNotEmpty) {
          currentSection['content'] += '\n';
        }
        currentSection['content'] += trimmedLine;
      }
    } else {
      // This is content before any section header
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('---')) {
        if (currentSection == null) {
          currentSection = {'title': '', 'content': trimmedLine, 'items': []};
        } else {
          currentSection['content'] += '\n$trimmedLine';
        }
      }
    }
  }

  // Add the last section
  if (currentSection != null) {
    sections.add(currentSection);
  }

  return sections;
}

// Parse bold text marked with *asterisks*
// Updated Regex to support *Word*, * Word *, and *Word *
List<Map<String, dynamic>> _parseBoldText(String text) {
  final boldParts = <Map<String, dynamic>>[];
  // Updated pattern: Matches *text* non-greedily
  final boldPattern = RegExp(r'\*(.*?)\*');

  int lastIndex = 0;
  final matches = boldPattern.allMatches(text);

  for (final match in matches) {
    // Add text before bold
    if (match.start > lastIndex) {
      boldParts.add({
        'text': text.substring(lastIndex, match.start),
        'isBold': false,
      });
    }

    // Add bold text
    boldParts.add({'text': match.group(1)!, 'isBold': true});

    lastIndex = match.end;
  }

  // Add remaining text
  if (lastIndex < text.length) {
    boldParts.add({'text': text.substring(lastIndex), 'isBold': false});
  }

  return boldParts;
}

// Build case example section
Widget _buildCaseExampleSection(String text) {
  final caseExamples = _extractCaseExamples(text);

  if (caseExamples.isEmpty) return const SizedBox();

  return Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1F27),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2B3540)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.gavel, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Case Examples',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final example in caseExamples) _buildCaseExample(example),
      ],
    ),
  );
}

// Extract case examples from text
Set<Map<String, dynamic>> _extractCaseExamples(String text) {
  final examples = <Map<String, dynamic>>{};

  // 1. Clean up the header if it's still stuck to the start (e.g., --PRESEDENT--Case Name...)
  String cleanText = text
      .replaceFirst(
        RegExp(r'--*RELEVANT JUDICIAL PRECEDENT--*', caseSensitive: false),
        '',
      )
      .trim();

  // 2. Regex to find blocks formatted as: Case Name: [Name] Summary: [Summary]
  // Pattern Breakdown:
  // Case Name:\s*       -> Matches "Case Name:" followed by optional whitespace
  // (.+?)               -> Capture Group 1: The Case Name (non-greedy, stops at "Summary:")
  // \s*Summary:\s*      -> Matches "Summary:" with optional surrounding whitespace
  // (.+?)               -> Capture Group 2: The Summary content (non-greedy)
  // (?=Case Name:|$)    -> Lookahead: Stop when hitting the next "Case Name:" or the End of String
  final pattern = RegExp(
    r'Case Name:\s*(.+?)\s*Summary:\s*(.+?)(?=Case Name:|$)',
    caseSensitive: false,
    dotAll: true, // Ensures newlines inside the summary are captured correctly
  );

  final matches = pattern.allMatches(cleanText);

  for (final match in matches) {
    // Group 1 is the Case Name
    final caseName = match.group(1)?.trim() ?? '';
    // Group 2 is the Summary
    final summary = match.group(2)?.trim() ?? '';

    if (caseName.isNotEmpty) {
      examples.add({
        'caseName': caseName,
        // Mapping the summary to 'content' so the existing widget displays it
        'content': summary,
      });
    }
  }

  // Fallback: If the new format isn't found, you could keep the old logic here,
  // but based on your log, the pattern above should cover it.

  return examples;
}

// Build individual case example
// (Updated slightly to ensure clean rendering of the Summary text)
Widget _buildCaseExample(Map<String, dynamic> example) {
  final contentText = example['content'] as String;
  final boldContentParts = _parseBoldText(contentText);

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF252D39),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Case Name Section
        if (example['caseName'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              example['caseName'],
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

        // 2. Summary/Content Section
        if (contentText.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Optional: Add a small "Summary:" label if you want it visually
              // Text(
              //   "Summary:",
              //   style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              // ),
              // SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    for (final part in boldContentParts)
                      TextSpan(
                        text: part['text'],
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: part['isBold']
                              ? FontWeight.w700
                              : FontWeight.normal,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

// Build a message section
Widget _buildMessageSection(Map<String, dynamic> section) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        if (section['title'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              section['title'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 1.3,
              ),
            ),
          ),

        // Section content (Parse for bold text)
        if (section['content'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBoldText(_parseBoldText(section['content'])),
          ),

        // Bullet points
        if ((section['items'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in section['items'] as List)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          right: 8,
                        ), // Adjusted top for bullet alignment
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(
                            top: 5,
                          ), // Fine tune alignment
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildBoldText(
                          item['boldParts'] as List<Map<String, dynamic>>,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}

// Build text with bold parts (Helper)
Widget _buildBoldText(List<Map<String, dynamic>> boldParts) {
  return RichText(
    softWrap: true, // Ensure wrapping
    text: TextSpan(
      children: [
        for (final part in boldParts)
          TextSpan(
            text: part['text'],
            style: TextStyle(
              color: Colors.white70,
              fontWeight: part['isBold'] ? FontWeight.w700 : FontWeight.normal,
              fontSize: 14,
              height: 1.5,
            ),
          ),
      ],
    ),
  );
}

// Update the message bubble to use the parser
Widget BuildMessageBubble(ChatMessage m, BuildContext context) {
  final bg = m.isUser ? Colors.white : const Color(0xFF2B3540);
  final textColor = m.isUser ? Colors.black : Colors.white;
  final bubbleRadius = BorderRadius.circular(12);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: m.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          // Changed from ConstrainedBox to Flexible to prevent overflow issues
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width *
                  0.75, // Slightly increased width
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: bg, borderRadius: bubbleRadius),
            child: m.isUser
                ? Text(m.text, style: TextStyle(color: textColor))
                : _buildMessageContent(m.text),
          ),
        ),
      ],
    ),
  );
}
