import 'dart:async';
import 'dart:developer';

import 'package:dextera/core/app_theme.dart';
import 'package:dextera/models/chat_message.dart';
import 'package:dextera/models/conversation.dart';
import 'package:dextera/models/local_conversation.dart';
import 'package:dextera/repository/chat_repository.dart';
import 'package:dextera/repository/convo_repository.dart';
import 'package:dextera/screens/components/message_bubble.dart';
import 'package:dextera/screens/components/gradient_text.dart';
import 'package:dextera/screens/login_screen.dart';
import 'package:dextera/utils/html_escape.dart';
import 'package:dextera/utils/markdown_formatter.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:dextera/utils/user_store.dart';
import 'package:dextera/utils/snackbar_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Responsive Chat Screen (Option A, Tablet = T2 Slide-in Drawer)
/// Breakpoints:
///  - Mobile: width < 700
///  - Tablet: 700 <= width < 1024 -> uses slide-in drawer
///  - Desktop: width >= 1024 -> persistent left drawer
class HomeChatScreen extends StatefulWidget {
  const HomeChatScreen({super.key});

  @override
  State<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends State<HomeChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatRepository _chatRepository = ChatRepository();
  final ConvoRepository _convoRepository = ConvoRepository();
  StreamSubscription<String>? _chatSub;
  bool _isStreaming = false;

  // Conversation state
  String? _currentConversationId;
  final List<ConversationSummary> _conversations = [];
  List<ConversationSummary> _filteredConversations = [];
  bool _isLoadingConversations = false;
  bool _isLoadingChat = false;
  String? _deletingConversationId;
  String? _loadingConversationId;
  String? _renamingConversationId;

  // Document mode state – per-conversation context storage (Task 9)
  final Map<String, _DocumentContext> _conversationDocContexts = {};
  bool _isDocumentMode = false;
  String? _documentContext;

  bool _isSummarizing = false;
  String? _pendingDocumentSummary;
  String? _pendingDocumentName;

  // Drawer open state (for mobile/tablet). On desktop, we force it open.
  bool _drawerOpen = false;

  // Controls overlay drawer animation on tablet/mobile
  late final AnimationController _drawerAnimController;
  late final Animation<double> _drawerOpacity;

  // Alert state (Task 10)
  String? _alertMessage;
  ChatAlertType _alertType = ChatAlertType.error;

  @override
  void initState() {
    super.initState();
    _drawerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _drawerOpacity = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _drawerAnimController, curve: Curves.easeInOut),
    );

    _searchController.addListener(_filterConversations);
    _refreshConversations();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _drawerAnimController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() {
      _drawerOpen = true;
    });
    _drawerAnimController.forward();
  }

  void _closeDrawer() {
    log('Closing drawer');
    _drawerAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _drawerOpen = false;
        });
      }
    });
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredConversations = _conversations;
      });
    } else {
      setState(() {
        _filteredConversations = _conversations
            .where((conv) => conv.title.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Alert Helpers (Task 10)
  // ─────────────────────────────────────────────────────────────────────────

  void _showAlert(String message, {ChatAlertType type = ChatAlertType.error}) {
    if (mounted) {
      if (type == ChatAlertType.error) {
        CustomSnackBar.showError(context, error: message);
      } else {
        CustomSnackBar.show(context, message: message, type: SnackBarType.info);
      }
    }
  }

  void _dismissAlert() {
    if (mounted) {
      setState(() {
        _alertMessage = null;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Send Message (Task 11)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    if (_isStreaming) return; // prevent overlapping requests

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // If this is the first prompt (no messages yet), we want to open the
    // drawer so the user can see topics/controls.
    final wasEmpty = _messages.isEmpty;

    // Ensure we have an active conversation id (from localhost convo API)
    await _ensureActiveConversationInitialized(initialMessage: text);

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      // Placeholder assistant message that will be populated by stream
      _messages.add(ChatMessage(text: '', isUser: false));
    });

    _inputController.clear();

    // Open the drawer when the user writes the first prompt.
    if (wasEmpty) {
      _openDrawer();
    }

    _scrollToBottom();

    _startStreamResponse(text);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SSE Streaming (Task 5 & 11)
  // ─────────────────────────────────────────────────────────────────────────

  void _startStreamResponse(String prompt) {
    _chatSub?.cancel();
    setState(() {
      _isStreaming = true;
    });

    // Index of the assistant message we just added
    final assistantIndex = _messages.length - 1;

    _chatSub = _chatRepository
        .streamChat(
          prompt,
          conversationId: _currentConversationId!,
          useRag: !_isDocumentMode,
          documentContext: _documentContext,
        )
        .listen(
          (chunk) {
            log('Received chunk: $chunk');
            setState(() {
              // Content accumulation: add space before chunk if needed
              final current = _messages[assistantIndex].text;
              String newText;
              if (current.isNotEmpty &&
                  !current.endsWith(' ') &&
                  !current.endsWith('\n') &&
                  !chunk.startsWith(' ') &&
                  !chunk.startsWith('\n')) {
                newText = current + ' ' + chunk;
              } else {
                newText = current + chunk;
              }
              // Format points to ensure they are on a new line (helps markdown renderer)
              newText = newText.replaceAllMapped(
                RegExp(r'([^\n])\s+(\*\s*\*\*)'),
                (m) => '${m.group(1)}\n\n${m.group(2)}',
              );
              _messages[assistantIndex].text = newText;
            });
            // Update display on every chunk (visual streaming effect)
            _scrollToBottom();
          },
          onError: (err) {
            setState(() {
              _isStreaming = false;
              // If the stream failed before any chunks were received, remove the placeholder
              if (_messages.isNotEmpty &&
                  !_messages.last.isUser &&
                  _messages.last.text.isEmpty) {
                _messages.removeLast();
              }
            });
            if (!mounted) return;

            // Determine error message
            String errorMsg;
            if (err is ChatException) {
              if (err.isTimeout) {
                errorMsg = 'Request timed out. Please try again.';
              } else {
                errorMsg = err.displayMessage;
              }
            } else {
              errorMsg = err.toString();
            }
            _showAlert(errorMsg);
          },
          onDone: () {
            log('Chat stream done');
            log('Final message: ${_messages[assistantIndex].text}');
            setState(() {
              _isStreaming = false;
            });
          },
          cancelOnError: true,
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Conversation Management
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _ensureActiveConversationInitialized({
    String? initialMessage,
  }) async {
    if (_currentConversationId != null) {
      // Update title with first user message if it was placeholder before.
      if (initialMessage != null) {
        final idx = _conversations.indexWhere(
          (c) => c.id == _currentConversationId,
        );
        if (idx != -1 && _conversations[idx].title.isEmpty) {
          _conversations[idx] = _conversations[idx].copyWith(
            title: _buildTitle(initialMessage),
          );
        }
      }
      return;
    }

    final title = initialMessage != null ? _buildTitle(initialMessage) : '';

    try {
      final created = await _convoRepository.create(title: title);
      _upsertConversationSummary(created);
      _currentConversationId = created.id;
    } catch (e) {
      if (!mounted) return;
      _showAlert('Failed to create conversation: $e');
      rethrow;
    }
  }

  String _buildTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'New conversation';
    return trimmed.length <= 50 ? trimmed : '${trimmed.substring(0, 50)}...';
  }

  Future<void> _loadConversation(String conversationId) async {
    // Clear search when loading a conversation
    _searchController.clear();
    setState(() {
      _isLoadingChat = true;
      _loadingConversationId = conversationId;
    });
    try {
      final history = await _chatRepository.fetchConversation(conversationId);

      // Track the last document summary so we can restore document mode
      String? lastDocSummary;
      String? lastDocName;

      final loadedMessages = history.messages.map((m) {
        if (m.type == 'document_summary') {
          lastDocSummary = m.content;
          lastDocName = m.filename;
          return ChatMessage(
            text: m.content,
            isUser: false,
            messageType: 'document_summary',
            documentName: m.filename,
            metadata: m.metadata,
          );
        }
        return ChatMessage(
          text: m.content,
          isUser: m.role.toLowerCase() == 'user',
        );
      }).toList();

      setState(() {
        _currentConversationId = conversationId;
        _messages
          ..clear()
          ..addAll(loadedMessages);

        // Restore document context per conversation (Task 9)
        final savedCtx = _conversationDocContexts[conversationId];
        if (savedCtx != null) {
          _isDocumentMode = true;
          _documentContext = savedCtx.summary;
        } else if (lastDocSummary != null) {
          _isDocumentMode = true;
          _documentContext = lastDocSummary;
          // Store for future switches
          _conversationDocContexts[conversationId] = _DocumentContext(
            filename: lastDocName ?? 'Document',
            summary: lastDocSummary!,
          );
        } else {
          _isDocumentMode = false;
          _documentContext = null;
        }
        _isLoadingChat = false;
        _loadingConversationId = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingChat = false;
        _loadingConversationId = null;
      });
      _showAlert('Failed to load conversation: $e');
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    setState(() {
      _deletingConversationId = conversationId;
    });
    try {
      await _convoRepository.delete(conversationId: conversationId);
      if (!mounted) return;
      setState(() {
        _deletingConversationId = null;
        _conversations.removeWhere((c) => c.id == conversationId);
        _filterConversations();
        _conversationDocContexts.remove(conversationId);
        if (_currentConversationId == conversationId) {
          _currentConversationId = null;
          _isDocumentMode = false;
          _documentContext = null;
          _messages.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deletingConversationId = null;
      });
      _showAlert('Failed to delete conversation: $e');
    }
  }

  Future<void> _renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    if (newTitle.trim().isEmpty) return;
    setState(() {
      _renamingConversationId = conversationId;
    });
    try {
      final updatedConvo = await _convoRepository.rename(
        conversationId: conversationId,
        title: newTitle,
      );
      if (!mounted) return;
      setState(() {
        _renamingConversationId = null;
        final idx = _conversations.indexWhere((c) => c.id == conversationId);
        if (idx != -1) {
          _conversations[idx] = _conversations[idx].copyWith(
            title: updatedConvo.title,
          );
          _filterConversations();
        }
      });
      _showAlert('Conversation renamed successfully', type: ChatAlertType.info);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _renamingConversationId = null;
      });
      _showAlert('Failed to rename conversation: $e');
    }
  }

  void _showDeleteConfirmationDialog(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.drawerClr,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Chat?', style: TextStyle(color: whiteClr)),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: TextStyle(color: whiteClr.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: whiteClr.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversationId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String conversationId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.drawerClr,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename Chat', style: TextStyle(color: whiteClr)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: whiteClr),
          decoration: InputDecoration(
            hintText: 'Enter new title',
            hintStyle: TextStyle(color: whiteClr.withOpacity(0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: whiteClr.withOpacity(0.1)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ThemeHelper.lightBlueClr),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: whiteClr.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.pop(context);
                _renameConversation(conversationId, newTitle);
              }
            },
            child: Text(
              'Rename',
              style: TextStyle(color: ThemeHelper.lightBlueClr),
            ),
          ),
        ],
      ),
    );
  }

  void _upsertConversationSummary(LocalConversation c) {
    final summary = ConversationSummary(
      id: c.id,
      title: c.title,
      lastUpdated: DateTime.now(),
      messageCount: 0,
    );

    setState(() {
      final existingIdx = _conversations.indexWhere((x) => x.id == c.id);
      if (existingIdx == -1) {
        _conversations.insert(0, summary);
      } else {
        _conversations[existingIdx] = summary;
      }
      _filterConversations();
    });
  }

  Future<void> _refreshConversations() async {
    setState(() {
      _isLoadingConversations = true;
    });

    try {
      final list = await _convoRepository.fetchAll();
      setState(() {
        _conversations
          ..clear()
          ..addAll(
            list.map(
              (c) => ConversationSummary(
                id: c.id,
                title: c.title,
                lastUpdated: null,
                messageCount: 0,
              ),
            ),
          );
        _filterConversations();
      });
    } catch (e) {
      if (!mounted) return;
      _showAlert('Failed to fetch conversations: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          if (_isStreaming) {
            _scrollController.jumpTo(maxScroll);
          } else {
            _scrollController.animateTo(
              maxScroll,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PDF Upload & Document Context (Task 9)
  // ─────────────────────────────────────────────────────────────────────────

  /// Activates document mode for the current conversation.
  void _activateDocumentContext(ChatMessage m) {
    setState(() {
      _isDocumentMode = true;
      _documentContext = m.text;
      if (_currentConversationId != null) {
        _conversationDocContexts[_currentConversationId!] = _DocumentContext(
          filename: m.documentName ?? 'Document',
          summary: m.text,
        );
      }
      _messages.add(
        ChatMessage(
          text:
              'Now discussing: ${m.documentName ?? "Document"}. Your follow-up questions will be answered based on this document.',
          isUser: false,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _uploadPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        withReadStream: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bool isOngoingConversation =
          _messages.isNotEmpty && _currentConversationId != null;

      if (isOngoingConversation) {
        // ── In-conversation flow: inline summary ──
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Summarizing ${file.name}...',
              isUser: false,
              messageType: 'loading',
              documentName: file.name,
            ),
          );
        });
        _scrollToBottom();

        final response = await _chatRepository.summarizePdf(
          _currentConversationId!,
          file,
        );
        final summary = response['summary'] ?? 'No summary returned';

        if (!mounted) return;
        setState(() {
          // Replace the loading placeholder with the real summary card
          final loadingIdx = _messages.lastIndexWhere(
            (m) => m.messageType == 'loading',
          );
          if (loadingIdx != -1) {
            _messages[loadingIdx] = ChatMessage(
              text: summary,
              isUser: false,
              messageType: 'document_summary',
              documentName: file.name,
            );
          }
        });
        _scrollToBottom();
      } else {
        // ── Standalone flow (empty state): full-screen summary view ──
        setState(() {
          _isSummarizing = true;
          _pendingDocumentSummary = null;
          _pendingDocumentName = file.name;
        });

        await _ensureActiveConversationInitialized(
          initialMessage: 'Document: ${file.name}',
        );
        if (_currentConversationId == null) {
          setState(() {
            _isSummarizing = false;
          });
          return;
        }

        final response = await _chatRepository.summarizePdf(
          _currentConversationId!,
          file,
        );
        final summary = response['summary'] ?? 'No summary returned';

        if (!mounted) return;
        setState(() {
          _isSummarizing = false;
          _pendingDocumentSummary = summary;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
          _pendingDocumentSummary = null;
          _pendingDocumentName = null;
          // Remove any loading placeholders on error
          _messages.removeWhere((m) => m.messageType == 'loading');
        });

        // Extract meaningful error message
        String errorMsg;
        if (e is ChatException) {
          errorMsg = e.displayMessage;
        } else {
          errorMsg = e.toString();
        }
        _showAlert('Error uploading PDF: $errorMsg');
      }
    }
  }

  // Use these breakpoints consistently
  bool _isMobile(double w) => w < 700;
  bool _isTablet(double w) => w >= 700 && w < 1024;
  bool _isDesktop(double w) => w >= 1024;

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeHelper.isDarkModeNotifier,
      builder: (context, isDark, child) {
        final w = MediaQuery.of(context).size.width;
        final isMobile = _isMobile(w);
        final isTablet = _isTablet(w);
        final isDesktop = _isDesktop(w);

        final leftPanelVisible = _drawerOpen;

        return Scaffold(
          backgroundColor: primaryClr,
          // Top AppBar for mobile/tablet only
          appBar: isDesktop
              ? null
              : AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: whiteClr,
                  leading: IconButton(
                    icon: SvgPicture.asset(
                      "assets/icons/drawer.svg",
                      colorFilter: ColorFilter.mode(whiteClr, BlendMode.srcIn),
                    ),
                    onPressed: () {
                      if (_drawerOpen) {
                        _closeDrawer();
                      } else {
                        _openDrawer();
                      }
                    },
                  ),
                  // actions: [
                  //   IconButton(
                  //     icon: Icon(
                  //       isDark ? Icons.light_mode : Icons.dark_mode,
                  //       color: whiteClr,
                  //     ),
                  //     onPressed: ThemeHelper.toggleTheme,
                  //   ),
                  //   const SizedBox(width: 8),
                  // ],
                ),
          body: Stack(
            children: [
              // 1. Content Area (Desktop Row or Mobile/Tablet Single Column)
              if (isDesktop)
                Row(
                  children: [
                    if (leftPanelVisible)
                      SizedBox(width: 320, child: _buildDrawerColumn()),
                    Expanded(
                      child: _buildMainContentColumn(
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                    ),
                  ],
                )
              else
                _buildMainContentColumn(isMobile, isTablet, isDesktop),

              // 2. OVERLAY SLIDE-IN DRAWER (mobile/tablet T2)
              if (!isDesktop && leftPanelVisible)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeDrawer,
                    child: FadeTransition(
                      opacity: _drawerOpacity,
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                  ),
                ),
              if (!isDesktop && leftPanelVisible)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 360 : 300,
                      minWidth: 260,
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(-1.0, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _drawerAnimController,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: Container(
                        color: const Color(0xFF1A1F28),
                        height: double.infinity,
                        child: _buildDrawerColumn(),
                      ),
                    ),
                  ),
                ),

              // 3. Desktop toggle button
              if (isDesktop && !leftPanelVisible)
                Positioned(
                  top:
                      (_isDocumentMode &&
                          _currentConversationId != null &&
                          _messages.isNotEmpty)
                      ? 45
                      : 12,
                  left: 12,
                  child: SafeArea(
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: _drawerOpen
                            ? const SizedBox.shrink()
                            : SvgPicture.asset('assets/icons/drawer.svg'),
                        onPressed: () {
                          if (_drawerOpen) {
                            _closeDrawer();
                          } else {
                            _openDrawer();
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Helpers (Consolidated)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMainContentColumn(bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      children: [
        // Document mode banner (Task 9)
        if (_isDocumentMode &&
            _currentConversationId != null &&
            _messages.isNotEmpty)
          _buildDocumentModeBanner(),

        // Alert display (Task 10)
        if (_alertMessage != null)
          ChatAlert(
            message: _alertMessage!,
            type: _alertType,
            onDismiss: _dismissAlert,
          ),

        // Main content area
        Expanded(
          child: _isLoadingChat
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : (_isSummarizing || _pendingDocumentSummary != null)
              ? _buildSummaryState(isMobile, isTablet, isDesktop)
              : _messages.isEmpty
              ? _buildInitialCenteredState(isMobile, isTablet, isDesktop)
              : _buildActiveChatState(isMobile, isTablet, isDesktop),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Document Mode Banner (Task 9)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDocumentModeBanner() {
    final ctx = _conversationDocContexts[_currentConversationId];
    final filename = ctx?.filename ?? 'Document';
    final escapedName = HtmlEscape.escape(filename);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeHelper.yellowClr.withOpacity(0.12),
            ThemeHelper.yellowClr.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: ThemeHelper.yellowClr.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: ThemeHelper.yellowClr,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Answering based on $escapedName. RAG disabled.',
              style: TextStyle(
                color: ThemeHelper.yellowClr,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDocumentMode = false;
                _documentContext = null;
                if (_currentConversationId != null) {
                  _conversationDocContexts.remove(_currentConversationId);
                }
              });
            },
            child: Icon(
              Icons.close,
              color: ThemeHelper.yellowClr.withOpacity(0.6),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Initial centered state (GPT-like)
  // ----------------------------
  Widget _buildInitialCenteredState(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = isMobile
        ? screenWidth
        : isTablet
        ? 760.0
        : 900.0; // natural max width for center box

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / round icon
                    SvgPicture.asset(
                      ThemeHelper.logoUrl,
                      width: isMobile ? 70 : 86,
                      height: isMobile ? 70 : 86,
                    ),
                    const SizedBox(height: 26),
                    GradientText(
                      'How can I assist you?',
                      gradient: LinearGradient(
                        colors: [
                          ThemeHelper.textPrimaryClr,
                          ThemeHelper.textSecondaryClr,
                        ],
                      ),
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      height: isMobile ? 72 : width * 0.14,
                      width: width,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: drawerClr,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 36,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              style: TextStyle(color: whiteClr),
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: _isDocumentMode
                                    ? "Ask about '${_conversationDocContexts[_currentConversationId]?.filename ?? "document"}'..."
                                    : 'Write your legal query here',
                                hintStyle: TextStyle(
                                  color: whiteClr.withOpacity(0.54),
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _roundIconButton(Icons.send, _sendMessage),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 1,
                          width: 60,
                          color: whiteClr.withOpacity(0.24),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: whiteClr.withOpacity(0.54),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          height: 1,
                          width: 60,
                          color: whiteClr.withOpacity(0.24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _uploadPdf,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: drawerClr,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF455168),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.post_add, color: whiteClr),
                            const SizedBox(width: 12),
                            Text(
                              'Summarize a Document',
                              style: TextStyle(
                                color: whiteClr,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------
  // Summary view state
  // ----------------------------
  Widget _buildSummaryState(bool isMobile, bool isTablet, bool isDesktop) {
    if (_isSummarizing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: whiteClr),
            const SizedBox(height: 16),
            Text(
              'Summarizing ${_pendingDocumentName ?? "document"}...',
              style: TextStyle(color: whiteClr, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_pendingDocumentSummary != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary for ${HtmlEscape.escape(_pendingDocumentName ?? "Document")}',
                  style: TextStyle(
                    color: whiteClr,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: drawerClr,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: formatMarkdownToWidgets(_pendingDocumentSummary!),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _pendingDocumentSummary = null;
                          _pendingDocumentName = null;
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: whiteClr.withOpacity(0.54),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _ensureActiveConversationInitialized(
                          initialMessage: 'Document: ${_pendingDocumentName}',
                        );
                        setState(() {
                          _isDocumentMode = true;
                          _documentContext = _pendingDocumentSummary;

                          // Store document context
                          if (_currentConversationId != null) {
                            _conversationDocContexts[_currentConversationId!] =
                                _DocumentContext(
                                  filename: _pendingDocumentName ?? 'Document',
                                  summary: _pendingDocumentSummary!,
                                );
                          }

                          // Add document summary card (not plain text)
                          _messages.add(
                            ChatMessage(
                              text: _pendingDocumentSummary!,
                              isUser: false,
                              messageType: 'document_summary',
                              documentName: _pendingDocumentName,
                            ),
                          );
                          // Add follow-up message
                          _messages.add(
                            ChatMessage(
                              text:
                                  'Now discussing: $_pendingDocumentName. Your follow-up questions will be answered based on this document.',
                              isUser: false,
                            ),
                          );
                          _pendingDocumentSummary = null;
                          _pendingDocumentName = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeHelper.buttonBgClr,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: ThemeHelper.buttonTextClr,
                      ),
                      label: Text(
                        'Continue as Chat',
                        style: TextStyle(
                          color: ThemeHelper.buttonTextClr,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  // ----------------------------
  // Active Chat State
  // ----------------------------
  Widget _buildActiveChatState(bool isMobile, bool isTablet, bool isDesktop) {
    // On desktop, allow a slightly larger content width
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 24.0 : 40.0);
    final width =
        MediaQuery.of(context).size.width -
        (isDesktop ? 360 : 0) -
        horizontalPadding * 2;
    return Column(
      children: [
        // Messages list
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: _messages.length + (_isStreaming ? 0 : 0),
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  // Route to special widgets based on message type (Task 1)
                  switch (m.displayType) {
                    case MessageDisplayType.documentSummary:
                      return BuildDocumentSummaryCard(
                        message: m,
                        isDocumentModeActive:
                            _isDocumentMode && _documentContext == m.text,
                        onDiscuss: () => _activateDocumentContext(m),
                      );
                    case MessageDisplayType.loading:
                      return _buildLoadingBubble(m);
                    case MessageDisplayType.user:
                    case MessageDisplayType.assistant:
                      return BuildMessageBubble(m, context);
                  }
                },
              ),
            ),
          ),
        ),

        // Bottom input
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              12,
            ),
            child: Container(
              height: width * 0.12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: ThemeHelper.buttonBgClr.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
                color: ThemeHelper.queryBoxClr,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  // PDF attachment button
                  const SizedBox(width: 8),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: TextField(
                        controller: _inputController,
                        style: TextStyle(color: whiteClr),
                        minLines: 1,
                        maxLines: 6,
                        enabled: !_isStreaming,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isDocumentMode
                              ? "Ask about '${_conversationDocContexts[_currentConversationId]?.filename ?? "document"}'..."
                              : 'Write your legal query here',
                          hintStyle: TextStyle(
                            color: whiteClr.withOpacity(0.54),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          _roundIconButton(Icons.attach_file, _uploadPdf),
                          const SizedBox(width: 8),
                          _isStreaming
                              ? SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: whiteClr.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                )
                              : _roundIconButton(Icons.send, _sendMessage),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // Loading bubble (shown while summarizing in-conversation)
  // ----------------------------
  Widget _buildLoadingBubble(ChatMessage m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: drawerClr,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: whiteClr,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  m.text,
                  style: TextStyle(color: whiteClr.withOpacity(0.70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Left drawer content
  // ----------------------------
  Widget _buildDrawerColumn() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(color: drawerClr),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top logo row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    ThemeHelper.isDarkMode
                        ? "assets/icons/logo-full.svg"
                        : "assets/icons/logo-full-light.svg",
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconBoxClr,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.chevron_left, color: whiteClr),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // New Query button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ElevatedButton.icon(
                iconAlignment: IconAlignment.end,
                onPressed: () {
                  // reset state / new query
                  _searchController.clear();
                  setState(() {
                    _messages.clear();
                    _inputController.clear();
                    _currentConversationId = null;
                    _isDocumentMode = false;
                    _documentContext = null;
                    _isSummarizing = false;
                    _pendingDocumentSummary = null;
                    _pendingDocumentName = null;
                  });
                  if (!_isDesktop(MediaQuery.of(context).size.width)) {
                    _closeDrawer();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                  backgroundColor: ThemeHelper.buttonBgClr,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.edit, color: ThemeHelper.buttonTextClr),
                label: Row(
                  children: [
                    Text(
                      'New Query',
                      style: TextStyle(color: ThemeHelper.buttonTextClr),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.queryBoxClr,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: whiteClr),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: whiteClr.withOpacity(0.54),
                    ),
                    hintText: 'Search',
                    hintStyle: TextStyle(color: whiteClr.withOpacity(0.54)),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Conversation history list (Task 7)
            Expanded(
              child: _isLoadingConversations
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _filteredConversations.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isNotEmpty
                            ? 'No conversations found'
                            : 'No conversations yet',
                        style: TextStyle(color: whiteClr.withOpacity(0.54)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conv = _filteredConversations[index];
                        final isActive = conv.id == _currentConversationId;
                        final hasDocCtx = _conversationDocContexts.containsKey(
                          conv.id,
                        );

                        // Escaped title for safe display
                        final displayTitle = conv.title.isEmpty
                            ? 'Conversation'
                            : HtmlEscape.truncate(conv.title, maxLength: 60);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? ThemeHelper.buttonBgClr
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            leading: hasDocCtx
                                ? const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFFD4A843),
                                    size: 18,
                                  )
                                : null,
                            title: Text(
                              displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: whiteClr, fontSize: 13),
                            ),
                            onTap: () => _loadConversation(conv.id),
                            trailing: _loadingConversationId == conv.id
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: whiteClr,
                                    ),
                                  )
                                : (_deletingConversationId == conv.id ||
                                      _renamingConversationId == conv.id)
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _deletingConversationId == conv.id
                                          ? Colors.redAccent
                                          : ThemeHelper.lightBlueClr,
                                    ),
                                  )
                                : PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: whiteClr.withOpacity(0.5),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeleteConfirmationDialog(conv.id);
                                      } else if (value == 'rename') {
                                        _showRenameDialog(conv.id, conv.title);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: whiteClr,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Rename',
                                              style: TextStyle(color: whiteClr),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.redAccent,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    color: ThemeHelper.drawerClr,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            // User Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/user-info');
                },
                icon: Icon(Icons.person_outline, color: whiteClr),
                label: Text(
                  'Profile Settings',
                  style: TextStyle(
                    color: whiteClr,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  backgroundColor: ThemeHelper.buttonBgClr,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            //Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ElevatedButton.icon(
                onPressed: () {
                  TokenStore.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  backgroundColor: ThemeHelper.buttonBgClr,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Small round icon used in input area
  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ThemeHelper.buttonBgClr,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ThemeHelper.buttonTextClr),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Document Context storage model (Task 9)
// ═════════════════════════════════════════════════════════════════════════════

class _DocumentContext {
  final String filename;
  final String summary;

  const _DocumentContext({required this.filename, required this.summary});
}
