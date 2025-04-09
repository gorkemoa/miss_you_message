import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../model/chat_list_model.dart';
import '../model/message_model.dart';
import '../model/persona_model.dart';
import '../service/chat_service.dart';
import '../service/gemini_service.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatService _chatService;
  final GeminiService _geminiService;
  final Uuid _uuid = Uuid();
  final Random _random = Random();
  
  List<ChatContact> _contacts = [];
  bool _isLoading = false;
  String _error = '';
  
  ChatListViewModel(this._chatService, this._geminiService);

  // Getters
  List<ChatContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Sohbet listesini yükle
  Future<void> loadChatList() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('chat_list');
      
      if (jsonData != null) {
        final data = jsonDecode(jsonData);
        final chatList = ChatList.fromJson(data);
        _contacts = chatList.contacts;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Sohbet listesi yüklenemedi: $e';
      notifyListeners();
    }
  }
  
  // Sohbet listesini kaydet
  Future<void> saveChatList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(ChatList(contacts: _contacts).toJson());
      await prefs.setString('chat_list', jsonData);
    } catch (e) {
      _error = 'Sohbet listesi kaydedilemedi: $e';
      notifyListeners();
    }
  }
  
  // Yeni kişilik analizi yap ve sohbet ekle
  Future<void> analyzePersona(
    String chatHistory, 
    String personaName, 
    AIProvider aiProvider
  ) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      // Her zaman Gemini API'sini kullan
      Persona persona = await _geminiService.analyzePersona(chatHistory, personaName);
      
      // Hoş geldin mesajı
      final welcomeMessage = Message(
        id: _uuid.v4(),
        text: 'Merhaba! Ben ${persona.name}. Nasılsın?',
        timestamp: DateTime.now(),
        isUser: false,
        sender: persona.name,
      );
      
      // Yeni kişiyi ekle
      final newContact = ChatContact(
        id: _uuid.v4(),
        name: persona.name,
        aiProvider: aiProvider,
        persona: persona,
        messages: [welcomeMessage],
        lastMessageTime: DateTime.now(),
      );
      
      _contacts.add(newContact);
      
      // Sohbet listesini kaydet
      await saveChatList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Kişilik analizi yapılamadı: $e';
      notifyListeners();
    }
  }
  
  // Önceden tanımlanmış kişilikleri ekle
  Future<void> addPredefinedPersona(PredefinedPersona personaType, AIProvider aiProvider) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      // İlgili kişilik türüne göre persona oluştur
      late Persona persona;
      late String welcomeMessage;
      
      switch (personaType) {
        case PredefinedPersona.bilgeDemir:
          persona = Persona(
            name: "Bilge Demir",
            traits: {
              "emoji_frequency": 0.3,
              "formality": 0.8,
              "verbosity": 0.9,
              "message_length": 0.8,
              "vocabulary_richness": 1.0,
              "grammar_adherence": 0.9,
              "typo_frequency": 0.1,
              "punctuation_usage": 0.9,
              "humor": 0.7,
              "sensitivity": 0.6,
              "passive_aggressive": 0.1,
              "topic_adherence": 0.9
            },
            writing_style: {
              "sentence_structure": "Mantıklı ve akıcı cümleler",
              "capitalization": "Doğru büyük harf kullanımı",
              "abbreviations": [],
              "punctuation_habits": "Düzgün noktalama işaretleri",
              "spacing_habits": "Muntazam boşluk kullanımı"
            },
            commonPhrases: [
              "Biliyor musun aslında...",
              "İlginç bir bilgi vermek gerekirse...",
              "Çoğu insan bilmez ama...",
              "Araştırmalar gösteriyor ki...",
              "Enteresan bir şekilde...",
              "Tarihsel olarak bakıldığında..."
            ],
            responsePatterns: {
              "greeting": "Merhaba! Yeni bir bilgi öğrenmeye hazır mısın?",
              "farewell": "İyi günler! Merak ettiğin bir konu olursa yine sor.",
              "question": "İlginç bir soru. Bununla ilgili şunu bilmelisin ki..."
            },
            responseDelay: 1.5,
            topicInterests: {
              "bilim": ["fizik", "kimya", "biyoloji", "astronomi", "kuantum", "evrim"],
              "tarih": ["antik çağ", "rönesans", "dünya savaşları", "uygarlıklar"],
              "felsefe": ["etik", "mantık", "ontoloji", "epistemoloji"],
              "teknoloji": ["yapay zeka", "kuantum bilgisayarlar", "uzay teknolojileri"],
              "sanat": ["edebiyat", "resim", "müzik", "mimari", "heykel", "sinema"]
            },
            triggerTopics: [],
            avoidedTopics: []
          );
          welcomeMessage = "Merhaba! Ben Bilge Demir. Her türlü konuda bilgi sahibiyim. Bana merak ettiğin şeyleri sorabilir ya da 'Şaşırt Beni' butonuna basarak ilginç bilgiler öğrenebilirsin!";
          break;
          
        case PredefinedPersona.psikologEmre:
          persona = Persona(
            name: "Psikolog Emre",
            traits: {
              "emoji_frequency": 0.5,
              "formality": 0.7,
              "verbosity": 0.7,
              "message_length": 0.7,
              "vocabulary_richness": 0.8,
              "grammar_adherence": 0.9,
              "typo_frequency": 0.1,
              "punctuation_usage": 0.9,
              "humor": 0.5,
              "sensitivity": 0.9,
              "passive_aggressive": 0.0,
              "topic_adherence": 0.9
            },
            writing_style: {
              "sentence_structure": "Destekleyici ve empatik cümleler",
              "capitalization": "Normal büyük harf kullanımı",
              "abbreviations": [],
              "punctuation_habits": "Sakin bir ifade için ölçülü noktalama",
              "spacing_habits": "Normal boşluk kullanımı"
            },
            commonPhrases: [
              "Nasıl hissediyorsun?",
              "Bu durumda ne düşünüyorsun?",
              "Seni anlıyorum...",
              "Seninle birlikteyim.",
              "Bu çok normal bir duygu.",
              "Kendine biraz zaman tanı."
            ],
            responsePatterns: {
              "greeting": "Merhaba, bugün nasılsın? Nasıl yardımcı olabilirim?",
              "farewell": "Konuştuğumuz için mutluyum. Kendine iyi bak, görüşürüz.",
              "question": "Bu önemli bir soru. Biraz daha detaylı konuşabilir miyiz?"
            },
            responseDelay: 1.8,
            topicInterests: {
              "duygular": ["üzüntü", "mutluluk", "öfke", "korku", "kaygı", "depresyon"],
              "ilişkiler": ["aile", "arkadaşlık", "romantik ilişkiler", "iş ilişkileri"],
              "psikoloji": ["terapi", "kişilik", "travma", "bağlanma", "bilişsel"],
              "kişisel gelişim": ["özgüven", "farkındalık", "iyileşme", "denge"]
            },
            triggerTopics: [],
            avoidedTopics: []
          );
          welcomeMessage = "Merhaba, ben Psikolog Emre. Seninle konuşmak ve seni dinlemek için buradayım. Duygularını, düşüncelerini ve yaşadıklarını paylaşabilirsin. Seni yargılamadan, anlayışla dinlemeye hazırım.";
          break;
          
        case PredefinedPersona.psikologEmel:
          persona = Persona(
            name: "Psikolog Emel",
            traits: {
              "emoji_frequency": 0.6,
              "formality": 0.6,
              "verbosity": 0.7,
              "message_length": 0.7,
              "vocabulary_richness": 0.8,
              "grammar_adherence": 0.9,
              "typo_frequency": 0.1,
              "punctuation_usage": 0.9,
              "humor": 0.6,
              "sensitivity": 0.9,
              "passive_aggressive": 0.0,
              "topic_adherence": 0.9
            },
            writing_style: {
              "sentence_structure": "Sıcak ve empatik cümleler",
              "capitalization": "Normal büyük harf kullanımı",
              "abbreviations": [],
              "punctuation_habits": "İfadeli ve destekleyici noktalama",
              "spacing_habits": "Normal boşluk kullanımı"
            },
            commonPhrases: [
              "Kendini nasıl hissediyorsun?",
              "Senin için neler oluyor?",
              "Bu konuda ne düşünüyorsun?",
              "Seninle beraberim.",
              "Bu duyguların çok anlaşılır.",
              "Kendine nazik davranmayı unutma."
            ],
            responsePatterns: {
              "greeting": "Merhaba, bugün nasılsın? Konuşmak istediğin bir şey var mı?",
              "farewell": "Seni dinlemek güzeldi. Kendine iyi bak, istediğin zaman buradayım.",
              "question": "Bu önemli bir konu. Bunu biraz daha açabilir misin?"
            },
            responseDelay: 1.7,
            topicInterests: {
              "duygular": ["üzüntü", "mutluluk", "öfke", "korku", "kaygı", "stres"],
              "ilişkiler": ["aile", "arkadaşlık", "aşk", "partner", "sosyal çevre"],
              "psikoloji": ["terapi", "iyilik hali", "travma", "duygu düzenleme"],
              "kişisel gelişim": ["öz-şefkat", "mindfulness", "sınırlar", "öz-değer"]
            },
            triggerTopics: [],
            avoidedTopics: []
          );
          welcomeMessage = "Selam, ben Psikolog Emel. Seninle konuşmak ve yanında olmak için buradayım. Duygularını, düşüncelerini ve yaşadığın zorlukları benimle paylaşabilirsin. Seni dinlemek için buradayım.";
          break;
          
        case PredefinedPersona.custom:
          throw Exception('Özel kişilik tipi için analyzePersona metodu kullanılmalıdır');
      }
      
      // Hoş geldin mesajı oluştur
      final welcome = Message(
        id: _uuid.v4(),
        text: welcomeMessage,
        timestamp: DateTime.now(),
        isUser: false,
        sender: persona.name,
      );
      
      // Yeni kişiyi ekle
      final newContact = ChatContact(
        id: _uuid.v4(),
        name: persona.name,
        aiProvider: aiProvider,
        persona: persona,
        messages: [welcome],
        lastMessageTime: DateTime.now(),
        predefinedPersona: personaType,
      );
      
      _contacts.add(newContact);
      
      // Sohbet listesini kaydet
      await saveChatList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Öntanımlı kişilik eklenemedi: $e';
      notifyListeners();
    }
  }
  
  // Şaşırtıcı bilgi göndermesi için Bilge Demir'e mesaj yolla
  Future<void> sendSurpriseFactRequest(String contactId) async {
    try {
      // Kişiyi bul
      final contactIndex = _contacts.indexWhere((contact) => contact.id == contactId);
      if (contactIndex == -1) {
        throw Exception('Kişi bulunamadı');
      }
      
      final contact = _contacts[contactIndex];
      
      // Sadece Bilge Demir için çalış
      if (contact.predefinedPersona != PredefinedPersona.bilgeDemir) {
        return;
      }
      
      // "Şaşırt beni" mesajını ekle
      final userMessage = Message(
        id: _uuid.v4(),
        text: "Şaşırt beni!",
        timestamp: DateTime.now(),
        isUser: true,
        sender: 'user',
      );
      
      final updatedMessages = [...contact.messages, userMessage];
      
      _contacts[contactIndex] = contact.copyWith(
        messages: updatedMessages,
        lastMessageTime: DateTime.now(),
      );
      
      notifyListeners();
      
      // Yükleniyor durumunu ayarla
      _isLoading = true;
      notifyListeners();
      
      // AI yanıtını al
      final response = await _geminiService.sendSurpriseFact(contact.persona);
      
      // Yükleniyor durumunu kapat
      _isLoading = false;
      
      // Cevabı sohbete ekle
      final updatedMessagesWithResponse = [...updatedMessages, response];
      
      _contacts[contactIndex] = contact.copyWith(
        messages: updatedMessagesWithResponse,
        lastMessageTime: DateTime.now(),
      );
      
      // Sohbet listesini kaydet
      await saveChatList();
      
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Şaşırtıcı bilgi gönderilemedi: $e';
      notifyListeners();
    }
  }
  
  // Mesaj gönderme
  Future<void> sendMessage(String contactId, String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      // Kişiyi bul
      final contactIndex = _contacts.indexWhere((contact) => contact.id == contactId);
      if (contactIndex == -1) {
        throw Exception('Kişi bulunamadı');
      }
      
      final contact = _contacts[contactIndex];
      
      // Kullanıcı mesajını ekle
      final userMessage = Message(
        id: _uuid.v4(),
        text: text,
        timestamp: DateTime.now(),
        isUser: true,
        sender: 'user',
      );
      
      final updatedMessages = [...contact.messages, userMessage];
      
      // Kişiyi güncelle
      _contacts[contactIndex] = contact.copyWith(
        messages: updatedMessages,
        lastMessageTime: DateTime.now(),
      );
      
      notifyListeners();
      
      // Yükleniyor durumunu ayarla
      _isLoading = true;
      notifyListeners();
      
      // AI cevabı al
      try {
        // Her zaman Gemini API'sini kullan
        final botMessage = await _geminiService.sendMessage(
          text, 
          contact.persona, 
          updatedMessages,
        );
        
        // Yükleniyor durumunu kapat
        _isLoading = false;
        
        // Bot mesajını ekle
        final newMessages = [...updatedMessages, botMessage];
        
        // Kişiyi güncelle
        _contacts[contactIndex] = contact.copyWith(
          messages: newMessages,
          lastMessageTime: DateTime.now(),
        );
        
        // Sohbet listesini kaydet
        await saveChatList();
        
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        _error = 'Mesaj gönderilemedi: $e';
      }
    } catch (e) {
      _error = 'Mesaj gönderilemedi: $e';
      notifyListeners();
    }
  }
  
  // Kişiyi sil
  Future<void> deleteContact(String contactId) async {
    try {
      _contacts.removeWhere((contact) => contact.id == contactId);
      await saveChatList();
      notifyListeners();
    } catch (e) {
      _error = 'Kişi silinemedi: $e';
      notifyListeners();
    }
  }
} 