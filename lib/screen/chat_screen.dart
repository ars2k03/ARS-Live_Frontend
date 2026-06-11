import 'package:flutter/material.dart';
import '../authService/auth_service.dart';
import '../mediaSize/size.dart';
import '../model/message.model.dart';
import '../socket/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.senderId, required this.receiverAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  String profilePicture = "";

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();

    profilePicture = widget.receiverAvatar;

    loadMessages();

    SocketService.listenMessage((data) {

      final msg =  ChatMessage.fromJson(data);

      setState(() {

        final exists = messages.any(
              (m) => m.id == msg.id,
        );

        if (!exists) {
          messages.add(msg);
        }

      });

      scrollToBottom();

    });
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    String text = controller.text.trim();

    setState(() {
      messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: widget.senderId,
          message: text,
          createdAt: DateTime.now(),
        ),
      );
    });

    SocketService.sendMessage(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      message: text,
    );

    controller.clear();

    scrollToBottom();
  }

  Future<void> loadMessages() async {

    final response = await AuthService.getMessages(widget.receiverId);

    if (response["success"] == true) {

      final history = response["messages"];

      setState(() {

        messages = history
            .map<ChatMessage>(
              (e) => ChatMessage.fromJson(e),
        )
            .toList();
      });

      scrollToBottom();

    }

  }

  @override
  void dispose() {

    SocketService.removeMessageListener();

    controller.dispose();

    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xff1E1E1E)
          : const Color(0xffF7F7F8),

      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xff1E1E1E) : Colors.white,
        elevation: 0,

        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),

        titleSpacing: 10,

        title: Row(
          children: [
            CircleAvatar(
              radius: context.w * .055,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.black12,
              child: profilePicture.isNotEmpty? CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(profilePicture),
              ) : Text(
                widget.receiverName[0].toUpperCase(),
                style: TextStyle(
                  color:
                  isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(width: context.w * .03),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : Colors.black,
                      fontSize: context.w * .042,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Text(
                    "Online",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// CHAT LIST
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  bool isMe =
                      messages[index].senderId ==
                          widget.senderId;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),

                      constraints: BoxConstraints(
                        maxWidth: context.w * .75,
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      decoration: BoxDecoration(
                        color: isMe
                            ? (isDark
                            ? const Color(
                            0xff3B82F6)
                            : const Color(
                            0xff1F1F1F))
                            : (isDark
                            ? const Color(
                            0xff2A2A2A)
                            : Colors.white),

                        borderRadius: BorderRadius.only(
                          topLeft:
                          const Radius.circular(22),
                          topRight:
                          const Radius.circular(22),
                          bottomLeft: Radius.circular(
                            isMe ? 22 : 6,
                          ),
                          bottomRight: Radius.circular(
                            isMe ? 6 : 22,
                          ),
                        ),

                        boxShadow: isDark
                            ? []
                            : [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(.04),
                            blurRadius: 10,
                            offset:
                            const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Text(
                        messages[index].message,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : (isDark
                              ? Colors.white70
                              : Colors.black87),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// INPUT BAR
            Container(
              color: isDark
                  ? const Color(0xff1E1E1E)
                  : const Color(0xffF7F7F8),

              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                20,
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xff2A2A2A)
                            : Colors.white,

                        borderRadius:
                        BorderRadius.circular(28),

                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                      ),

                      child: TextField(
                        controller: controller,

                        minLines: 1,
                        maxLines: 5,

                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.black,
                        ),

                        decoration: InputDecoration(
                          hintText: "Message",

                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.black54,
                          ),

                          border: InputBorder.none,

                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),

                        onSubmitted: (_) =>
                            sendMessage(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: sendMessage,

                    child: Container(
                      height: 52,
                      width: 52,

                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xff3B82F6)
                            : const Color(0xff1F1F1F),

                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}