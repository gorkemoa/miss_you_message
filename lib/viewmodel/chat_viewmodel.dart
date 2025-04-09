import 'dart:async';
import 'package:flutter/material.dart';
import '../model/message_model.dart';
import '../model/persona_model.dart';
import '../service/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService;
  List<Message> _messages = [];
  Persona? _persona;
  bool _isLoading = false;
  String _error = '';
  Timer? _onlineStatusTimer; // Çevrimiçi durumu kontrol etmek için zamanlayıcı
  
  ChatViewModel(this._chatService) {
    // Düzenli aralıklarla çevrimiçi durumunu kontrol et
    _startOnlineStatusTimer();
  }
  
  // Zamanlayıcıyı başlat
  void _startOnlineStatusTimer() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Her dakika otomatik çevrimiçi kontrolü yap
      _checkAndUpdateOnlineStatus();
    });
  }
  
  // Çevrimiçi durumunu kontrol et ve güncelle
  Future<void> _checkAndUpdateOnlineStatus() async {
    if (_persona != null && _messages.isNotEmpty) {
      try {
        // Yeni bir mesaj oluşmasına gerek yok, sadece bir ping gönder
        await _chatService.pingService();
        notifyListeners(); // UI'ı güncelle
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    }
  }

  @override
  void dispose() {
    _onlineStatusTimer?.cancel();
    super.dispose();
  }

  // Getters
  List<Message> get messages => _messages;
  Persona? get persona => _persona;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Kişilik analizi yap
  Future<void> analyzePersona(String chatHistory, String personaName) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      _persona = await _chatService.analyzePersona(chatHistory, personaName);
      
      // Sohbet geçmişini temizle ve yeni bir hoş geldin mesajı ekle
      _messages = [
        Message(
          id: DateTime.now().toString(),
          text: 'Merhaba! Ben ${_persona!.name}. Nasılsın?',
          timestamp: DateTime.now(),
          isUser: false,
          sender: _persona!.name,
        )
      ];

      // Sohbeti kaydet
      await _chatService.saveChatHistory(
        ChatHistory(messages: _messages, personaName: _persona!.name),
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Kişilik analizi yapılamadı: $e';
      notifyListeners();
    }
  }

  // Mesaj gönderme
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _persona == null) return;

    try {
      // Kullanıcı mesajını ekle
      final userMessage = Message(
        id: DateTime.now().toString(),
        text: text,
        timestamp: DateTime.now(),
        isUser: true,
        sender: 'user',
      );
      
      _messages.add(userMessage);
      notifyListeners();
      
      // Cevap vermeden önce yazıyor efekti için bekle
      _isLoading = true;
      notifyListeners();
      
      // Gerçekçi bir "yazıyor" hissi için rastgele gecikme
      final responseDelay = _persona!.responseDelay * 1000;
      await Future.delayed(Duration(milliseconds: responseDelay.toInt()));
      
      // Bot mesajını al ve ekle
      final botMessage = await _chatService.sendMessage(text, _persona!, _messages);
      _messages.add(botMessage);
      
      // Sohbeti kaydet
      await _chatService.saveChatHistory(
        ChatHistory(messages: _messages, personaName: _persona!.name),
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Mesaj gönderilemedi: $e';
      notifyListeners();
    }
  }

  // Sohbet geçmişini yükle
  Future<void> loadChatHistory() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final chatHistory = await _chatService.loadChatHistory();
      
      if (chatHistory != null) {
        _messages = chatHistory.messages;
        // Kişilik bilgisini geçici olarak oluştur (tam değil)
        _persona = Persona(
          name: chatHistory.personaName,
          traits: {},
          commonPhrases: [],
          responsePatterns: {},
          responseDelay: 1.0,
          topicInterests: {},
        );
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Sohbet geçmişi yüklenemedi: $e';
      notifyListeners();
    }
  }

  // Sohbeti temizle
  void clearChat() {
    _messages = [];
    _persona = null;
    notifyListeners();
  }
} 