// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble – Rendering System
//
// Handles:
//  • User messages (plain text, navy bg, sharp right corner)
//  • Assistant messages (formatted markdown, white/transparent bg, sharp left)
//  • Delimiter splitting for --RELEVANT JUDICIAL PRECEDENT--
//  • Document summary cards with discuss button state management
//  • Entry animations
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as Math;

import 'package:dextera/models/chat_message.dart';
import 'package:dextera/utils/markdown_formatter.dart';
import 'package:dextera/utils/html_escape.dart';
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';

/// The delimiter that separates main content from legal case references.
const String _judicialPrecedentDelimiter = '--RELEVANT JUDICIAL PRECEDENT--';

// ═════════════════════════════════════════════════════════════════════════════
// PUBLIC API
// ═════════════════════════════════════════════════════════════════════════════

/// Main entry: builds the correct bubble based on [ChatMessage.displayType].
Widget BuildMessageBubble(ChatMessage m, BuildContext context) {
  switch (m.displayType) {
    case MessageDisplayType.user:
      return _UserMessageBubble(message: m);
    case MessageDisplayType.assistant:
      return _AssistantMessageBubble(message: m);
    case MessageDisplayType.documentSummary:
    case MessageDisplayType.loading:
      // Document summaries and loading bubbles are handled externally
      // in home_chat_screen.dart via dedicated widgets.
      return _AssistantMessageBubble(message: m);
  }
}

/// Builds a document summary card with discuss button.
/// [onDiscuss] is called when the user taps "Discuss this Document".
Widget BuildDocumentSummaryCard({
  required ChatMessage message,
  required bool isDocumentModeActive,
  required VoidCallback onDiscuss,
}) {
  return _DocumentSummaryCard(
    message: message,
    isActive: isDocumentModeActive,
    onDiscuss: onDiscuss,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// USER MESSAGE BUBBLE
// ═════════════════════════════════════════════════════════════════════════════

class _UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxW = screenWidth < 700 ? screenWidth * 0.85 : screenWidth * 0.65;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: Transform.scale(scale: 0.97 + 0.03 * value, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: ThemeHelper.myMessageBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4), // sharp right corner
                ),
              ),
              // textContent (NOT innerHTML) — user input is not parsed
              child: Text(
                message.text,
                style: TextStyle(
                  color: whiteClr,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ASSISTANT MESSAGE BUBBLE
// ═════════════════════════════════════════════════════════════════════════════

class _AssistantMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _AssistantMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    //final maxW = screenWidth < 600 ? screenWidth * 0.85 : screenWidth * 0.78;
    final content = message.text;

    // Check for the judicial precedent delimiter
    final hasDelimiter = content.toUpperCase().contains(
      _judicialPrecedentDelimiter.toUpperCase(),
    );

    String mainContent = content;
    String caseContent = '';

    if (hasDelimiter) {
      final idx = content.toUpperCase().indexOf(
        _judicialPrecedentDelimiter.toUpperCase(),
      );
      mainContent = content.substring(0, idx).trim();
      caseContent = content
          .substring(idx + _judicialPrecedentDelimiter.length)
          .trim();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: Transform.scale(scale: 0.97 + 0.03 * value, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main content bubble ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeHelper.messageBgClr,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4), // sharp left corner
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content.isEmpty
                          ? [const TypingIndicator()]
                          : formatMarkdownToWidgets(mainContent),
                    ),
                  ),

                  // ── Case block (gold border) ──
                  if (caseContent.isNotEmpty) _buildCaseBlock(caseContent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the judicial precedent case block with gold styling.
  Widget _buildCaseBlock(String caseText) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ThemeHelper.yellowClr, width: 3),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFD4A843).withOpacity(0.06),
            const Color(0xFFD4A843).withOpacity(0.02),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.gavel, color: ThemeHelper.yellowClr, size: 18),
              const SizedBox(width: 8),
              Text(
                'RELEVANT JUDICIAL PRECEDENT',
                style: TextStyle(
                  color: ThemeHelper.yellowClr,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Case content formatted with markdown
          ...formatMarkdownToWidgets(caseText),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DOCUMENT SUMMARY CARD
// ═════════════════════════════════════════════════════════════════════════════

class _DocumentSummaryCard extends StatelessWidget {
  final ChatMessage message;
  final bool isActive;
  final VoidCallback onDiscuss;

  const _DocumentSummaryCard({
    required this.message,
    required this.isActive,
    required this.onDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    final escapedFilename = HtmlEscape.escape(
      message.documentName ?? 'Document',
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: drawerClr,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF455168), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeHelper.lightPinkClr.withOpacity(0.1),
                      ThemeHelper.lightPinkClr.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Document icon
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ThemeHelper.yellowClr.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.description_outlined,
                          color: ThemeHelper.yellowClr,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            escapedFilename,
                            style: TextStyle(
                              color: whiteClr,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Legal Document Summary',
                            style: TextStyle(
                              color: whiteClr.withOpacity(0.50),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── BODY ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: formatMarkdownToWidgets(message.text),
                ),
              ),

              // ── FOOTER ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: whiteClr.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generated by Dextera AI',
                      style: TextStyle(
                        color: whiteClr.withOpacity(0.40),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    // Button with two states
                    isActive ? _buildActiveButton() : _buildDiscussButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// State B: Document Mode Active (disabled, green)
  Widget _buildActiveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.25),
            const Color(0xFF059669).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 6),
          const Text(
            'Document Mode Active',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// State A: "Discuss this Document" (gold, clickable)
  Widget _buildDiscussButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDiscuss,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A843), Color(0xFFB8912E)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Discuss this Document',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING INDICATOR BUBBLE
// ═════════════════════════════════════════════════════════════════════════════

/// Typing indicator with bouncing dots animation.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Increase duration slightly for a smoother "wave" feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Use a sine wave to create the "up and down" motion
                    // (i * 0.4) creates the offset delay between balls
                    double radians =
                        (_controller.value * 2 * 3.14159) - (i * 0.8);
                    double bounce = Math.sin(radians);

                    // We only want them to bounce "up", so we clamp the floor
                    // and amplify the height.
                    double yOffset = bounce < 0 ? bounce * 8 : 0;

                    return Transform.translate(
                      offset: Offset(0, yOffset),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          // Opacity also shifts with the bounce for depth
                          color: whiteClr.withOpacity(bounce < 0 ? 1.0 : 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ALERT WIDGET
// ═════════════════════════════════════════════════════════════════════════════

/// Displays an inline alert message in the chat container.
/// Types: error (red), success (green), info (gold).
class ChatAlert extends StatefulWidget {
  final String message;
  final ChatAlertType type;
  final VoidCallback? onDismiss;
  final Duration autoDismiss;

  const ChatAlert({
    super.key,
    required this.message,
    this.type = ChatAlertType.error,
    this.onDismiss,
    this.autoDismiss = const Duration(seconds: 6),
  });

  @override
  State<ChatAlert> createState() => _ChatAlertState();
}

class _ChatAlertState extends State<ChatAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.autoDismiss, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _alertColors;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.$1.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.$1.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(colors.$2, color: colors.$1, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(color: colors.$1, fontSize: 13),
              ),
            ),
            if (widget.onDismiss != null)
              GestureDetector(
                onTap: () {
                  _controller.reverse().then((_) {
                    widget.onDismiss?.call();
                  });
                },
                child: Icon(
                  Icons.close,
                  color: colors.$1.withOpacity(0.6),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) get _alertColors {
    switch (widget.type) {
      case ChatAlertType.error:
        return (const Color(0xFFEF4444), Icons.error_outline);
      case ChatAlertType.success:
        return (const Color(0xFF10B981), Icons.check_circle_outline);
      case ChatAlertType.info:
        return (const Color(0xFFD4A843), Icons.info_outline);
    }
  }
}

enum ChatAlertType { error, success, info }
