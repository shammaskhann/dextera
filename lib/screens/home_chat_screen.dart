import 'dart:async';
import 'dart:developer';

import 'package:dextera/core/app_theme.dart';
import 'package:dextera/models/chat_message.dart';
import 'package:dextera/models/conversation.dart';
import 'package:dextera/models/local_conversation.dart';
import 'package:dextera/repository/chat_repository.dart';
import 'package:dextera/repository/convo_repository.dart';
import 'package:dextera/screens/components/message_bubble.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatRepository _chatRepository = ChatRepository();
  final ConvoRepository _convoRepository = ConvoRepository();
  StreamSubscription<String>? _chatSub;
  bool _isStreaming = false;

  // Conversation state
  String? _currentConversationId;
  final List<ConversationSummary> _conversations = [];
  bool _isLoadingConversations = false;

  // Document mode state
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

    _refreshConversations();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _inputController.dispose();
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

  Future<void> _sendMessage() async {
    if (_isStreaming) return; // prevent overlapping requests

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // If this is the first prompt (no messages yet), we want to open the
    // drawer so the user can see topics/controls. Capture state before
    // mutating _messages.
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

  void _startStreamResponse(String prompt) {
    _chatSub?.cancel();
    _isStreaming = true;

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
            setState(() {
              _messages[assistantIndex].text += chunk + " ";
            });
            _scrollToBottom();
          },
          onError: (err) {
            _isStreaming = false;
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Chat error: $err')));
          },
          onDone: () {
            log('Chat stream done');
            log('Final message: ${_messages[assistantIndex].text}');
            _isStreaming = false;
          },
          cancelOnError: true,
        );
  }

  // Ensure we have a conversation id (from localhost) and a corresponding summary entry.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create conversation: $e')),
      );
      rethrow;
    }
  }

  String _buildTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'New conversation';
    return trimmed.length <= 50 ? trimmed : '${trimmed.substring(0, 50)}...';
  }

  Future<void> _loadConversation(String conversationId) async {
    try {
      final history = await _chatRepository.fetchConversation(conversationId);
      setState(() {
        _currentConversationId = conversationId;
        _isDocumentMode = false;
        _documentContext = null;
        _messages
          ..clear()
          ..addAll(
            history.messages
                .map(
                  (m) => ChatMessage(
                    text: m.content,
                    isUser: m.role.toLowerCase() == 'user',
                  ),
                )
                .toList(),
          );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load conversation: $e')),
      );
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _convoRepository.delete(conversationId: conversationId);
      setState(() {
        _conversations.removeWhere((c) => c.id == conversationId);
        if (_currentConversationId == conversationId) {
          _currentConversationId = null;
          _isDocumentMode = false;
          _documentContext = null;
          _messages.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete conversation: $e')),
      );
    }
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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch conversations: $e')),
      );
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

      setState(() {
        _isSummarizing = true;
        _pendingDocumentSummary = null;
        _pendingDocumentName = file.name;
        _messages.clear(); // Ensure we don't show the chat view
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
          _pendingDocumentSummary = null;
          _pendingDocumentName = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading PDF: $e')));
      }
    }
  }

  // Use these breakpoints consistently
  bool _isMobile(double w) => w < 700;
  bool _isTablet(double w) => w >= 700 && w < 1024;
  bool _isDesktop(double w) => w >= 1024;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _isMobile(w);
    final isTablet = _isTablet(w);
    final isDesktop = _isDesktop(w);

    // Drawer visibility is controlled by `_drawerOpen` for all breakpoints.
    // Desktop no longer forces the drawer open — it starts closed until the
    // user opens it or sends the first prompt.
    final leftPanelVisible = _drawerOpen;

    return Scaffold(
      backgroundColor: primaryClr,
      // Top AppBar for mobile/tablet only
      appBar: isDesktop
          ? null
          : AppBar(
              elevation: 0,

              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: SvgPicture.asset("assets/icons/drawer.svg"),
                onPressed: () {
                  if (_drawerOpen) {
                    _closeDrawer();
                  } else {
                    _openDrawer();
                  }
                },
              ),
            ),
      body: Stack(
        children: [
          Row(
            children: [
              // ===========================
              // LEFT PERSISTENT DRAWER (desktop)
              // Only show when the drawer has been opened by the user
              // ===========================
              if (isDesktop && leftPanelVisible)
                SizedBox(width: 320, child: _buildDrawerColumn()),

              // ===========================
              // MAIN CONTENT AREA
              // - If no messages => centered initial state
              // - If messages => active chat layout
              // ===========================
              Expanded(
                child: (_isSummarizing || _pendingDocumentSummary != null)
                    ? _buildSummaryState(isMobile, isTablet, isDesktop)
                    : _messages.isEmpty
                    ? _buildInitialCenteredState(isMobile, isTablet, isDesktop)
                    : _buildActiveChatState(isMobile, isTablet, isDesktop),
              ),
            ],
          ),

          // ===========================
          // OVERLAY SLIDE-IN DRAWER (mobile/tablet T2)
          // Show when _drawerOpen && not desktop
          // ===========================
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
          // Desktop top-left menu icon to toggle drawer open/closed
          if (isDesktop)
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: _drawerOpen
                        ? SizedBox.shrink()
                        : SvgPicture.asset(
                            'assets/icons/drawer.svg',
                            //color: Colors.white,
                            //  width: 20,
                            // height: 20,
                          ),
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
  }

  // ----------------------------
  // Initial centered state (GPT-like)
  // ----------------------------
  Widget _buildInitialCenteredState(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final width = isMobile
        ? double.infinity
        : isTablet
        ? 760.0
        : 900.0; // natural max width for center box

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo / round icon
          SvgPicture.asset(
            'assets/icons/logo-D.svg',
            color: Colors.white,
            width: 86,
            height: 86,
          ),
          const SizedBox(height: 26),
          const Text(
            'How can I assist you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: width * 0.14,
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3340),
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
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your legal query here',
                      hintStyle: TextStyle(color: Colors.white54),
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
              Container(height: 1, width: 60, color: Colors.white24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(height: 1, width: 60, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _uploadPdf,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3340),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF455168), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.post_add, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Summarize a Document',
                    style: TextStyle(
                      color: Colors.white,
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
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Summarizing ${_pendingDocumentName ?? "document"}...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  'Summary for ${_pendingDocumentName ?? "Document"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3340),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _pendingDocumentSummary!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isDocumentMode = true;
                          _documentContext = _pendingDocumentSummary;
                          _messages.add(
                            ChatMessage(
                              text:
                                  '**Document Summary:**\n\n$_pendingDocumentSummary',
                              isUser: false,
                            ),
                          );
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
                        backgroundColor: const Color(0xFF455168),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Continue as Chat',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  log(m.text);
                  return BuildMessageBubble(m, context);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: lightPrimaryClr,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white),
                        minLines: 1,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Write your legal query here',
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _roundIconButton(Icons.send, _sendMessage),
                ],
              ),
            ),
          ),
        ),
      ],
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
                  SvgPicture.asset("assets/icons/logo-full.svg"),

                  GestureDetector(
                    onTap: _closeDrawer,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconBoxClr,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
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
                onPressed: () {
                  // reset state / new query
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
                  backgroundColor: const Color(0xFF2A3340),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'New Query',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3340),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.white54),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Conversation history list
            Expanded(
              child: _isLoadingConversations
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final isActive = conv.id == _currentConversationId;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF3A4656)
                                : const Color(0xFF2F3B48),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            title: Text(
                              conv.title.isEmpty ? 'Conversation' : conv.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () => _loadConversation(conv.id),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteConversation(conv.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            //Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A3340),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
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
        decoration: const BoxDecoration(
          color: Color(0xFF455168),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
