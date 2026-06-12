import 'package:flutter/material.dart';
import '../../socket/socket_service.dart';

class CallScreen extends StatefulWidget {
  final String callerName;
  final bool isIncoming;
  final String picture;
  final String callerId;
  final String currentUserId;

  const CallScreen({
    super.key,
    required this.callerName,
    required this.isIncoming,
    required this.picture,
    required this.callerId,
    required this.currentUserId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  String picture = "";
  String callerId = "";
  String currentUserId = "";
  bool callConnected = false;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();

    picture = widget.picture;
    callerId = widget.callerId;
    currentUserId = widget.currentUserId;

    // Both incoming and outgoing screens need to know if the other
    // side hangs up / rejects, and the outgoing side needs to know
    // when the call is accepted.

    SocketService.socket.off("call-accepted");
    SocketService.socket.off("call-rejected");
    SocketService.socket.off("call-ended");

    if (!widget.isIncoming) {
      SocketService.socket.on("call-accepted", (_) {
        if (!mounted) return;

        setState(() {
          callConnected = true;
        });
      });
    }

    SocketService.socket.on("call-rejected", (_) {
      _safePop();
    });

    SocketService.socket.on("call-ended", (_) {
      _safePop();
    });
  }

  void _safePop() {
    if (!mounted || _isPopping) return;
    _isPopping = true;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    SocketService.socket.off("call-accepted");
    SocketService.socket.off("call-rejected");
    SocketService.socket.off("call-ended");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: picture.isNotEmpty ? NetworkImage(picture) : null,
                child: picture.isEmpty
                    ? const Icon(
                  Icons.person,
                  size: 60,
                )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                callConnected
                    ? "Connected"
                    : widget.isIncoming
                    ? "Incoming Call..."
                    : "Calling...",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              if (widget.isIncoming && !callConnected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: "reject",
                      backgroundColor: Colors.red,
                      onPressed: () {
                        SocketService.socket.emit("reject-call", {
                          "callerId": callerId,
                          "receiverId": currentUserId,
                        });

                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.call_end),
                    ),
                    FloatingActionButton(
                      heroTag: "accept",
                      backgroundColor: Colors.green,
                      onPressed: () {
                        SocketService.socket.emit("answer-call", {
                          "callerId": callerId,
                          "receiverId": currentUserId,
                        });

                        setState(() {
                          callConnected = true;
                        });
                      },
                      child: const Icon(Icons.call),
                    ),
                  ],
                )
              else
                FloatingActionButton(
                  heroTag: "end",
                  backgroundColor: Colors.red,
                  onPressed: () {
                    // End / hang up the call and notify the other side.
                    SocketService.socket.emit("end-call", {
                      "callerId": currentUserId,
                      "receiverId": callerId,
                    });

                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.call_end),
                ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}