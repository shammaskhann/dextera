import 'dart:async';
import 'dart:developer';

import 'package:dextera/core/app_theme.dart';
import 'package:dextera/models/chat_message.dart';
import 'package:dextera/repository/chat_repository.dart';
import 'package:dextera/screens/components/message_bubble.dart';
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
  StreamSubscription<String>? _chatSub;
  bool _isStreaming = false;

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

  void _sendMessage() {
    if (_isStreaming) return; // prevent overlapping requests

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // If this is the first prompt (no messages yet), we want to open the
    // drawer so the user can see topics/controls. Capture state before
    // mutating _messages.
    final wasEmpty = _messages.isEmpty;

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
        .streamChat(prompt)
        .listen(
          (chunk) {
            setState(() {
              _messages[assistantIndex].text += chunk;
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
                child: _messages.isEmpty
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
                const SizedBox(width: 12),
                _roundIconButton(Icons.add, () {
                  // your extra action
                }),

                const SizedBox(width: 10),
                _roundIconButton(Icons.send, _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Active Chat State
  // ----------------------------
  Widget _buildActiveChatState(bool isMobile, bool isTablet, bool isDesktop) {
    // On desktop, allow a slightly larger content width
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 24.0 : 40.0);

    return Column(
      children: [
        // Header area
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF12151A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/logo-D.svg',
                color: Colors.white,
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 12),
              const Text(
                'Penalties for Theft Under PPC', // Replace with dynamic title
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              // on mobile, show a compact button to open drawer
              if (isMobile || isTablet)
                IconButton(
                  onPressed: _openDrawer,
                  icon: const Icon(Icons.menu, color: Colors.white),
                ),
            ],
          ),
        ),

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
                  final bg = m.isUser ? Colors.white : const Color(0xFF2B3540);
                  final textColor = m.isUser ? Colors.black : Colors.white;
                  final bubbleRadius = BorderRadius.circular(12);
                  return BuildMessageBubble(m, context);
                  // return Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 8),
                  //   child: Row(
                  //     mainAxisAlignment: m.isUser
                  //         ? MainAxisAlignment.end
                  //         : MainAxisAlignment.start,
                  //     children: [
                  //       ConstrainedBox(
                  //         constraints: BoxConstraints(
                  //           maxWidth: MediaQuery.of(context).size.width * 0.62,
                  //         ),
                  //         child: Container(
                  //           padding: const EdgeInsets.symmetric(
                  //             horizontal: 16,
                  //             vertical: 14,
                  //           ),
                  //           decoration: BoxDecoration(
                  //             color: bg,
                  //             borderRadius: bubbleRadius,
                  //           ),
                  //           child: Text(
                  //             m.text,
                  //             style: TextStyle(color: textColor),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // );
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
                  const SizedBox(width: 12),
                  _roundIconButton(Icons.add, () {}),
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

            // Topics list (sample static items)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _drawerTopic('Penalties for Theft under PPC'),
                  _drawerTopic('Defenses Against a Theft Charge'),
                  _drawerTopic('Bail Procedure'),
                  _drawerTopic('Precedents on False Theft Claims'),
                  _drawerTopic('Theft Case 01'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTopic(String title) {
    return GestureDetector(
      onTap: () {
        // Open topic as a message (simulate)
        setState(() {
          _messages.add(ChatMessage(text: title, isUser: false));
        });
        // close drawer on tablet/mobile
        if (!_isDesktop(MediaQuery.of(context).size.width)) {
          _closeDrawer();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2F3B48),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(title, style: const TextStyle(color: Colors.white)),
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
