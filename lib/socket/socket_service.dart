import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;

  static void connect() {

    socket = IO.io(
      "http://10.146.174.92:8000",
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


}