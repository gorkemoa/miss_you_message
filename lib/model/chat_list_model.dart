import 'dart:convert';
import 'message_model.dart';
import 'persona_model.dart';

enum AIProvider {
  openai,
  gemini
}

enum PredefinedPersona {
  custom,
  bilgeDemir,
  psikologEmre,
  psikologEmel
}

class ChatContact {
  final String id;
  final String name;
  final String? avatarUrl;
  final AIProvider aiProvider;
  final Persona persona;
  final List<Message> messages;
  final DateTime lastMessageTime;
  final PredefinedPersona predefinedPersona;

  ChatContact({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.aiProvider,
    required this.persona,
    required this.messages,
    required this.lastMessageTime,
    this.predefinedPersona = PredefinedPersona.custom,
  });

  String get lastMessage {
    if (messages.isEmpty) {
      return '';
    }
    return messages.last.text;
  }

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      aiProvider: AIProvider.values.firstWhere(
        (e) => e.toString() == 'AIProvider.${json['aiProvider']}',
        orElse: () => AIProvider.openai,
      ),
      persona: Persona.fromJson(json['persona']),
      messages: (json['messages'] as List)
          .map((message) => Message.fromJson(message))
          .toList(),
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      predefinedPersona: json['predefinedPersona'] != null 
          ? PredefinedPersona.values.firstWhere(
              (e) => e.toString() == 'PredefinedPersona.${json['predefinedPersona']}',
              orElse: () => PredefinedPersona.custom,
            )
          : PredefinedPersona.custom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'aiProvider': aiProvider.toString().split('.').last,
      'persona': persona.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'predefinedPersona': predefinedPersona.toString().split('.').last,
    };
  }

  ChatContact copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    AIProvider? aiProvider,
    Persona? persona,
    List<Message>? messages,
    DateTime? lastMessageTime,
    PredefinedPersona? predefinedPersona,
  }) {
    return ChatContact(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aiProvider: aiProvider ?? this.aiProvider,
      persona: persona ?? this.persona,
      messages: messages ?? this.messages,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      predefinedPersona: predefinedPersona ?? this.predefinedPersona,
    );
  }
}

class ChatList {
  final List<ChatContact> contacts;

  ChatList({required this.contacts});

  factory ChatList.fromJson(Map<String, dynamic> json) {
    return ChatList(
      contacts: (json['contacts'] as List)
          .map((contact) => ChatContact.fromJson(contact))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
    };
  }
} 