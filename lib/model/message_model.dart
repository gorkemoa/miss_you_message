class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isUser;
  final String sender;
  final bool isOffline;
  final bool isRandomMessage;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isUser,
    required this.sender,
    this.isOffline = false,
    this.isRandomMessage = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      isUser: json['isUser'],
      sender: json['sender'],
      isOffline: json['isOffline'] ?? false,
      isRandomMessage: json['isRandomMessage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isUser': isUser,
      'sender': sender,
      'isOffline': isOffline,
      'isRandomMessage': isRandomMessage,
    };
  }
}

class ChatHistory {
  final List<Message> messages;
  final String personaName;

  ChatHistory({
    required this.messages,
    required this.personaName,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      messages: (json['messages'] as List)
          .map((message) => Message.fromJson(message))
          .toList(),
      personaName: json['personaName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((message) => message.toJson()).toList(),
      'personaName': personaName,
    };
  }
} 