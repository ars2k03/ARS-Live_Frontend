import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;
  static String? currentUserId;
  static Set<String> onlineUsers = {};
  static bool isConnected = false;

  static void connect() {
    socket = IO.io(
      "http://10.146.174.92:8000",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.on("online-users", (data) {
      onlineUsers = Set<String>.from(data);
    });

    socket.onConnect((_) {
      isConnected = true;

      print("✅ Connected: ${socket.id}");

      if (currentUserId != null) {
        socket.emit("register", currentUserId);
      }
    });

    socket.onDisconnect((_) {
      isConnected = false;
      print("❌ Disconnected");
    });

    socket.onReconnect((_) {
      print("🔄 Reconnected");
      if (currentUserId != null) {
        socket.emit("register", currentUserId);
      }
    });
  }

  static void register(String userId) {
    currentUserId = userId;
    socket.emit("register", userId);
  }

  static void sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    socket.emit("send-message", {
      "conversationId": conversationId,
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
    });
  }

  static void markSeen({
    required String conversationId,
    required String userId,
  }) {
    socket.emit("mark-seen", {
      "conversationId": conversationId,
      "userId": userId,
    });
  }

  static void reconnectIfNeeded() {

    if (!socket.connected) {
      socket.connect();
    }

    if (currentUserId != null) {
      socket.emit("register", currentUserId);
    }
  }
}