class ChatMessage {

  final String id;
  final String senderId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(
      Map<String,dynamic> json) {

    return ChatMessage(
      id: json["_id"]?.toString() ?? "",
      senderId: json["senderId"] ?? "",
      message: json["message"] ?? "",
      createdAt: DateTime.tryParse(
        json["createdAt"] ?? "",
      ) ?? DateTime.now(),
    );
  }
}