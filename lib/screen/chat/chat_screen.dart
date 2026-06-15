import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../authService/auth_service.dart';
import '../../socket/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>   with WidgetsBindingObserver{
  bool isLoading = true;
  String conversationId = "";
  List<dynamic> messages = [];
  bool isReceiverOnline = false;

  final TextEditingController messageController = TextEditingController();

  late Function(dynamic) _onNewMessage;
  late Function(dynamic) _onMessageSent;
  late Function(dynamic) _onMessagesSeen;
  late Function(dynamic) _onOnlineUsers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadConversation();
    listenMessages();
    isReceiverOnline = SocketService.onlineUsers.contains(widget.receiverId);
    listenOnlineStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      SocketService.reconnectIfNeeded();
    }
  }

  Future<void> loadConversation() async {
    final response = await AuthService.openConversation(widget.receiverId);

    if (!mounted) return;

    if (response["success"] == true) {
      final conversation = response["conversation"];

      setState(() {
        conversationId = conversation["_id"];
        messages = List.from(conversation["messages"] ?? []).reversed.toList();
        isLoading = false;
      });

      SocketService.markSeen(
        conversationId: conversation["_id"],
        userId: widget.currentUserId,
      );
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void listenOnlineStatus() {

    _onOnlineUsers = (data) {

      if (!mounted) return;

      final onlineList = Set<String>.from(data);

      SocketService.onlineUsers = onlineList;

      setState(() {
        isReceiverOnline =
            onlineList.contains(widget.receiverId);
      });
    };

    SocketService.socket.off("online-users");
    SocketService.socket.on("online-users", _onOnlineUsers);
  }

  void listenMessages() {
    _onNewMessage = (data) {
      if (!mounted) return;

      final message = data["message"];
      final incomingConversationId = data["conversationId"];


      if (incomingConversationId != conversationId) return;

      setState(() {
        messages.insert(0, message);
      });

      SocketService.markSeen(
        conversationId: conversationId,
        userId: widget.currentUserId,
      );
    };

    _onMessageSent = (data) {
      if (!mounted) return;

      final message = data["message"];
      final incomingConversationId = data["conversationId"];

      if (incomingConversationId != conversationId) return;

      setState(() {
        messages.insert(0, message);
      });
    };

    _onMessagesSeen = (data) {
      if (!mounted) return;

      final seenBy = data["seenBy"];
      final incomingConversationId = data["conversationId"];

      if (incomingConversationId != conversationId) return;
      if (seenBy == widget.currentUserId) return;

      setState(() {
        for (int i = 0; i < messages.length; i++) {
          if (messages[i]["senderId"] == widget.currentUserId) {
            messages[i]["seen"] = true;
          }
        }
      });
    };

    SocketService.socket.on("new-message", _onNewMessage);
    SocketService.socket.on("message-sent", _onMessageSent);
    SocketService.socket.on("messages-seen", _onMessagesSeen);
  }

  @override
  void dispose() {
    SocketService.socket.off("new-message", _onNewMessage);
    SocketService.socket.off("message-sent", _onMessageSent);
    SocketService.socket.off("messages-seen", _onMessagesSeen);
    SocketService.socket.off("online-users", _onOnlineUsers);

    messageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _hasCodeBlock(String text) {
    return text.contains("```");
  }

  // Background colors
  Color _bgColor(bool isDark) =>
      isDark ? const Color(0xFF1F1E1D) : const Color(0xFFFAFAFA);

  Color _appBarColor(bool isDark) =>
      isDark ? const Color(0xFF262624) : Colors.white;

  Color _inputBarColor(bool isDark) =>
      isDark ? const Color(0xFF262624) : Colors.white;

  Color _inputFieldColor(bool isDark) =>
      isDark ? const Color(0xFF3A3935) : const Color(0xFFF4F4F4);

  Color _borderColor(bool isDark) =>
      isDark ? const Color(0xFF3A3935) : const Color(0xFFE5E5E5);

  // Bubble colors
  Color _myBubbleColor(bool isDark) =>
      isDark ? const Color(0xFF3A4B66) : const Color(0xFFDAE8FF);

  Color _otherBubbleColor(bool isDark) =>
      isDark ? const Color(0xFF2E2D2B) : const Color(0xFFF4F4F4);

  Color _bubbleBorderColor(bool isDark) =>
      isDark ? const Color(0xFF3A3935) : const Color(0xFFE5E5E5);

  // Text colors
  Color _primaryTextColor(bool isDark) =>
      isDark ? const Color(0xFFECECEC) : const Color(0xFF2D2D2D);

  Color _secondaryTextColor(bool isDark) =>
      isDark ? const Color(0xFFB0AEA9) : Colors.grey;

  // Code block colors
  Color _inlineCodeBg(bool isDark) =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEAEAEA);

  Color _inlineCodeFg(bool isDark) =>
      isDark ? const Color(0xFFFF8080) : const Color(0xFF000000);

  Color _codeBlockBg(bool isDark) =>
      isDark ? const Color(0xFF141414) : const Color(0xFF1E1E2E);

  Color _blockquoteBg(bool isDark) =>
      isDark ? const Color(0xFF2E2D2B) : const Color(0xFFF0F0F0);

  // Send button
  Color _sendButtonColor(bool isDark) =>
      isDark ? const Color(0xFFECECEC) : Colors.black;

  Color _sendIconColor(bool isDark) =>
      isDark ? Colors.black : Colors.white;


  Widget buildMessage(dynamic message, bool isDark) {
    final isMe = message["senderId"] == widget.currentUserId;
    final text = message["text"] ?? "";
    final hasCode = _hasCodeBlock(text);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: hasCode
            ? const EdgeInsets.all(10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _myBubbleColor(isDark) : _otherBubbleColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _bubbleBorderColor(isDark),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: _primaryTextColor(isDark),
                  fontSize: 15,
                  height: 1.4,
                ),
                code: TextStyle(
                  backgroundColor: _inlineCodeBg(isDark),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: _inlineCodeFg(isDark),
                ),
                codeblockDecoration: BoxDecoration(
                  color: _codeBlockBg(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                codeblockPadding: const EdgeInsets.all(12),
                blockquoteDecoration: BoxDecoration(
                  color: _blockquoteBg(isDark),
                  borderRadius: BorderRadius.circular(6),
                ),
                h1: TextStyle(
                  color: _primaryTextColor(isDark),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h2: TextStyle(
                  color: _primaryTextColor(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: _primaryTextColor(isDark),
                ),
                strong: TextStyle(
                  color: _primaryTextColor(isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
              builders: {
                'code': CodeBlockBuilder(),
              },
            ),
            const SizedBox(height: 2),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  message["seen"] == true ? Icons.done_all : Icons.done,
                  size: 15,
                  color: message["seen"] == true
                      ? Colors.blue
                      : _secondaryTextColor(isDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bgColor(isDark),
      appBar: AppBar(
        backgroundColor: _appBarColor(isDark),
        foregroundColor: _primaryTextColor(isDark),
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
              isDark ? const Color(0xFF3A3935) : const Color(0xFFE5E5E5),
              backgroundImage: widget.receiverAvatar.isNotEmpty
                  ? NetworkImage(widget.receiverAvatar)
                  : null,
              child: widget.receiverAvatar.isEmpty
                  ? Icon(Icons.person, color: _secondaryTextColor(isDark))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.receiverName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white70 : Colors.black,
        ),
      )
          : Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                "Start chatting 👋",
                style: TextStyle(
                  color: _secondaryTextColor(isDark),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index], isDark);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: _inputBarColor(isDark),
                border: Border(
                  top: BorderSide(
                    color: _borderColor(isDark),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      maxLines: 5,
                      minLines: 1,
                      style: TextStyle(
                        color: _primaryTextColor(isDark),
                      ),
                      decoration: InputDecoration(
                        hintText: "Message...",
                        hintStyle: TextStyle(
                          color: _secondaryTextColor(isDark),
                        ),
                        filled: true,
                        fillColor: _inputFieldColor(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _sendButtonColor(isDark),
                    child: IconButton(
                      onPressed: () {
                        final text = messageController.text.trim();

                        if (text.isEmpty) return;

                        SocketService.sendMessage(
                          conversationId: conversationId,
                          senderId: widget.currentUserId,
                          receiverId: widget.receiverId,
                          text: text,
                        );

                        messageController.clear();
                      },
                      icon: Icon(
                        Icons.arrow_upward,
                        color: _sendIconColor(isDark),
                        size: 20,
                      ),
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
}


class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(element, preferredStyle) {
    return null;
  }
}