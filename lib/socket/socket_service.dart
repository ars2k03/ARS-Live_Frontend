import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;

  static void connect() {

    socket = IO.io(
      "https://ars-live.onrender.com",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {

      print("✅ Connected: ${socket.id}");

    });

    socket.onDisconnect((_) {
      print("❌ Disconnected");
    });

    socket.onReconnect((_) {

      print("🔄 Reconnected");

    });

  }

  static void sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) {

    socket.emit( "send_message", {
        "senderId": senderId,
        "receiverId": receiverId,
        "message": message,
    });
  }

  static void listenMessage( Function(dynamic data) onMessage,) {

    socket.on("receive_message", (data) {
      onMessage(data);
    });

  }


  static void removeMessageListener() {
    socket.off("receive_message");
  }
}