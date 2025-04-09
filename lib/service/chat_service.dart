import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../model/message_model.dart';
import '../model/persona_model.dart';

class ChatService {
  // OpenAI API anahtarı doğrudan tanımlandı
  final String apiKey = 'BURAYA_OPENAI_API_KEY_EKLEYIN'; // TODO: Kendi API anahtarınızı buraya ekleyin
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';
  final Uuid _uuid = Uuid();
  final Random _random = Random();
  
  // Maliyet hesaplama için değişkenler
  final double _inputTokenCost = 0.00001; // USD per 1K token (gpt-4o)
  final double _outputTokenCost = 0.00003; // USD per 1K token (gpt-4o)
  final double _usdToTryRate = 33.0; // Dolar-TL kuru (değişken)
  
  // Son etkileşim zamanı
  DateTime _lastInteractionTime = DateTime.now();
  
  ChatService();

  // Çevrimiçi durumunu kontrol etmek için ping metodu
  Future<bool> pingService() async {
    // Son etkileşim zamanını güncelle
    _lastInteractionTime = DateTime.now();
    // Her zaman çevrimiçi olarak döndür
    return true;
  }

  // WhatsApp geçmişinden kişilik analizi yapma
  Future<Persona> analyzePersona(String chatHistory, String personaName) async {
    // Sohbet geçmişini token limitlerini aşmamak için kısalt
    String limitedHistory = chatHistory;
    if (chatHistory.length > 15000) {
      // Yaklaşık 15bin karakter (tahmini 4-5bin token) ile sınırla
      limitedHistory = chatHistory.substring(chatHistory.length - 15000);
      // İlk satırı temizle (yarım kalabilir)
      int firstNewLine = limitedHistory.indexOf('\n');
      if (firstNewLine > 0) {
        limitedHistory = limitedHistory.substring(firstNewLine + 1);
      }
    }

    developer.log('OpenAI API isteği gönderiliyor...', name: 'ChatService');
    
    // Tahmini token sayısı (karakter sayısı / 4 ile yaklaşık hesaplanabilir)
    final estimatedInputTokens = limitedHistory.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'ChatService');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': '''
            Sen bir kişilik analiz uzmanısın. Aşağıdaki WhatsApp konuşma geçmişini analiz edip, 
            "$personaName" adlı kişinin yazım tarzını, sık kullandığı ifadeleri, emoji kullanımını, 
            cevap verme hızını ve konuşma özelliklerini çıkar. Özellikle kişinin duygusal tepkileri, 
            trip atma durumları, alınganlık gösterme, pasif-agresif davranışlar, küsme, surat asma gibi 
            karakteristik davranışlarını detaylı analiz et. Bu kişinin iletişim stilini taklit edebilmek için 
            bir kişilik profili oluştur. Yanıtını YALNIZCA AŞAĞIDA BELİRTİLEN JSON FORMATIYLA aşağıdaki gibi ver:
            
            {
              "name": "$personaName",
              "traits": { 
                "emoji_frequency": 0.8, 
                "formality": 0.3, 
                "verbosity": 0.7, 
                "humor": 0.6,
                "sensitivity": 0.5,
                "passive_aggressive": 0.4,
                "trip_frequency": 0.3,
                "sulking_tendency": 0.2
              },
              "commonPhrases": ["phrase1", "phrase2", "phrase3"],
              "emotionalPatterns": {
                "whenAngry": ["pattern1", "pattern2"],
                "whenSad": ["pattern1", "pattern2"],
                "whenTripping": ["pattern1", "pattern2"],
                "whenSulking": ["pattern1", "pattern2"]
              },
              "responsePatterns": {"greeting": "pattern", "farewell": "pattern", "question": "pattern"},
              "responseDelay": 1.5,
              "topicInterests": {"topic1": ["keyword1", "keyword2"], "topic2": ["keyword3"]},
              "triggerTopics": ["trigger1", "trigger2"]
            }
            
            NOT: SADECE JSON FORMATI ver. Kesinlikle açıklama, ön bilgi, kod bloğu işaretleri (```) veya başka içerik EKLEME. Direkt olarak { ile başlayıp } ile biten geçerli bir JSON döndür.
            '''
          },
          {
            'role': 'user',
            'content': limitedHistory,
          }
        ],
        'temperature': 0.7,
      }),
    );

    developer.log('OpenAI API yanıtı alındı: ${response.statusCode}', name: 'ChatService');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        developer.log('Ham API yanıtı: $content', name: 'ChatService');
        
        // Token kullanım bilgisi
        if (data['usage'] != null) {
          final inputTokens = data['usage']['prompt_tokens'] ?? estimatedInputTokens;
          final outputTokens = data['usage']['completion_tokens'] ?? 0;
          final totalTokens = data['usage']['total_tokens'] ?? 0;
          
          // Maliyet hesaplama
          final inputCost = (inputTokens / 1000) * _inputTokenCost;
          final outputCost = (outputTokens / 1000) * _outputTokenCost;
          final totalCostUsd = inputCost + outputCost;
          final totalCostTry = totalCostUsd * _usdToTryRate;
          
          developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens, Toplam: $totalTokens', name: 'ChatService');
          developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'ChatService');
        }
        
        // JSON öncesi veya sonrası olan açıklamaları temizle
        String cleanJson = content.trim();
        
        // Eğer JSON backtick içinde verilmişse (```json ... ```) temizle
        if (cleanJson.contains('```')) {
          developer.log('Backtick temizleniyor...', name: 'ChatService');
          int startIndex = cleanJson.indexOf('{');
          int endIndex = cleanJson.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1) {
            cleanJson = cleanJson.substring(startIndex, endIndex + 1);
          }
        }
        
        // Sadece JSON kısmını al
        int jsonStart = cleanJson.indexOf('{');
        int jsonEnd = cleanJson.lastIndexOf('}');
        
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1);
          developer.log('Temizlenmiş JSON: $cleanJson', name: 'ChatService');
        } else {
          developer.log('JSON başlangıç ve bitiş indeksleri bulunamadı: start=$jsonStart, end=$jsonEnd', name: 'ChatService');
          throw Exception('Geçerli JSON içeriği bulunamadı');
        }
        
        try {
          // Önce bir deneme ayrıştırması yap
          final testParse = jsonDecode(cleanJson);
          developer.log('JSON başarıyla ayrıştırıldı', name: 'ChatService');
          final personaData = testParse;
          return Persona.fromJson(personaData);
        } catch (jsonError) {
          developer.log('JSON ayrıştırma hatası: $jsonError\n\nJSON: $cleanJson', name: 'ChatService', error: jsonError);
          
          // Son bir deneme daha - olası newline veya carriage return karakterlerini temizle
          cleanJson = cleanJson.replaceAll('\n', ' ').replaceAll('\r', ' ');
          developer.log('Yeni line temizlenmiş JSON: $cleanJson', name: 'ChatService');
          
          // Tekrar dene
          final personaData = jsonDecode(cleanJson);
          return Persona.fromJson(personaData);
        }
      } catch (e) {
        developer.log('Genel hata: $e\nİçerik: ${response.body}', name: 'ChatService', error: e);
        throw Exception('JSON ayrıştırma hatası: $e');
      }
    } else {
      developer.log('API hata yanıtı: ${response.body}', name: 'ChatService');
      throw Exception('Kişilik analizi yapılamadı: ${response.statusCode} ${response.body}');
    }
  }

  // Mesaj gönderme ve cevap alma
  Future<Message> sendMessage(String messageText, Persona persona, List<Message> chatContext) async {
    _lastInteractionTime = DateTime.now();
    
    // Kullanıcı mesajı oluştur
    final Message userMessage = Message(
      id: _uuid.v4(),
      text: messageText,
      timestamp: DateTime.now(),
      isUser: true,
      sender: 'user',
    );
    
    // Mesaj geçmişini hazırla (daha fazla bağlam için son mesaj sayısını artırıyoruz)
    final contextMessages = chatContext.length > 10 
        ? chatContext.sublist(chatContext.length - 10) 
        : chatContext;
    
    final List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content': '''
        Sen ${persona.name} adlı bir gerçek insansın. WhatsApp'ta yazışıyorsun. 
        Aşağıdaki özelliklere TAMAMEN BAĞLI KAL:
        
        1. KİŞİLİK ÖZELLİKLERİN: ${jsonEncode(persona.traits)}
        2. YAZIM TARZIN: ${jsonEncode(persona.writing_style ?? {})}
        3. EMOJİ KULLANIM ALIŞKANLIKLARIN: ${jsonEncode(persona.emoji_habits ?? {})}
        4. SIK KULLANDIĞIN İFADELER: ${jsonEncode(persona.commonPhrases)}
        5. KONUŞMA KALIPLARIN: ${jsonEncode(persona.conversationPatterns ?? {})}
        6. DUYGUSAL TEPKİ KALIPLARIN: ${jsonEncode(persona.emotionalPatterns ?? {})}
        7. CEVAP VERME KALIPLARIN: ${jsonEncode(persona.responsePatterns)}
        8. İLGİ ALANLARIN: ${jsonEncode(persona.topicInterests)}
        9. TETİKLEYİCİ KONULAR: ${jsonEncode(persona.triggerTopics ?? [])}
        10. KAÇINDIĞIN KONULAR: ${jsonEncode(persona.avoidedTopics ?? [])}
        
        ÇOK ÖNEMLİ KURALLAR (MUTLAKA UYGULANACAK):
        1. Kesinlikle yapay zeka olduğunu SÖYLEME veya İMA ETME. Sen ${persona.name} adlı gerçek bir insansın.
        2. EMOJİ KULLANIMINI kontrol et. Emoji kullanım sıklığın: ${persona.traits["emoji_frequency"] ?? 0.3} (0-1 arası). 
           Düşük bir değer ise, nadiren emoji kullan veya hiç kullanma.
           HER MESAJDA EMOJİ KULLANMA! Sadece gerçekten uygun olduğunda kullan.
           Her cümlede emoji kullanmak yapay duruyor.
        3. Yazım hatası oranın: ${persona.traits["typo_frequency"] ?? 0.3} (0-1 arası). 
           Mükemmel yazma, bazı yazım hataları yap. Gerçek insanlar bazen yazım hatası yapar.
        4. Mesaj uzunluğun: ${persona.traits["message_length"] ?? 0.5} (0-1 arası). 
           Uzun değer = uzun mesajlar, kısa değer = kısa mesajlar.
        5. Konudan ani sapma eğilimin: ${persona.traits["random_topic_change"] ?? 0.2} (0-1 arası).
           Düşük değer = konuya bağlı kal, yüksek değer = farklı konulara geç.
        6. Asla robotik, yapay ya da şablondan gelmiş gibi cevaplar verme!
        7. Basmakalıp cümleler kullanma. Doğal ve gerçekçi cevaplar ver.
        8. Abartılı noktalama işaretleri kullanma (!!!!!, ???), bu yapay görünüyor.
        9. Hiçbir şekilde yapay zeka, dil modeli, asistan olduğunu ima etme.
        10. Alakasız konular açma. Konuya uygun cevaplar ver.
        
        NOT: ASLA AŞIRI DÜZGÜN DİL BILGISI KULLANMA. GERÇEKÇI OL.
        '''
      },
    ];
    
    // Geçmiş mesajları ekle
    for (var message in contextMessages) {
      messages.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }
    
    // Kullanıcının yeni mesajını ekle
    messages.add({
      'role': 'user',
      'content': messageText,
    });
    
    developer.log('OpenAI mesaj isteği gönderiliyor...', name: 'ChatService');
    
    // Tahmini token sayısını hesapla
    int estimatedTokenCount = 0;
    for (var msg in messages) {
      estimatedTokenCount += (msg['content'] ?? '').length ~/ 4;
    }
    developer.log('Tahmini token sayısı: $estimatedTokenCount', name: 'ChatService');
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': messages,
        'temperature': 0.9, // Daha yaratıcı yanıtlar için temperature değerini artırdık
        'max_tokens': 200,
      }),
    );

    developer.log('OpenAI mesaj yanıtı alındı: ${response.statusCode}', name: 'ChatService');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        developer.log('OpenAI yanıt içeriği: $content', name: 'ChatService');
        
        // Token kullanım bilgisi
        if (data['usage'] != null) {
          final inputTokens = data['usage']['prompt_tokens'] ?? estimatedTokenCount;
          final outputTokens = data['usage']['completion_tokens'] ?? 0;
          final totalTokens = data['usage']['total_tokens'] ?? 0;
          
          // Maliyet hesaplama
          final inputCost = (inputTokens / 1000) * _inputTokenCost;
          final outputCost = (outputTokens / 1000) * _outputTokenCost;
          final totalCostUsd = inputCost + outputCost;
          final totalCostTry = totalCostUsd * _usdToTryRate;
          
          developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens, Toplam: $totalTokens', name: 'ChatService');
          developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'ChatService');
        }
        
        return Message(
          id: _uuid.v4(),
          text: content,
          timestamp: DateTime.now(),
          isUser: false,
          sender: persona.name,
          isOffline: false,
        );
      } catch (e) {
        developer.log('OpenAI yanıt işlenirken hata: $e', name: 'ChatService', error: e);
        throw Exception('Mesaj işlenemedi: $e');
      }
    } else {
      developer.log('OpenAI API hata yanıtı: ${response.body}', name: 'ChatService');
      throw Exception('Mesaj gönderilemedi: ${response.statusCode} ${response.body}');
    }
  }
  
  // Rastgele mesaj gönderme fonksiyonu - basitleştirilmiş
  Future<Message?> generateRandomMessage(Persona persona, List<Message> chatContext) async {
    // Her zaman null döndür - rastgele mesaj oluşturmayı devre dışı bırak
    return null;
  }
  
  // Görüldü (read receipt) davranışı simülasyonu
  bool shouldShowReadReceipt() {
    // Her zaman görüldü işareti göster
    return true;
  }
  
  // Sohbet geçmişini kaydetme
  Future<void> saveChatHistory(ChatHistory chatHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(chatHistory.toJson());
    await prefs.setString('chat_history', jsonData);
  }

  // Sohbet geçmişini yükleme
  Future<ChatHistory?> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('chat_history');
    
    if (jsonData != null) {
      final data = jsonDecode(jsonData);
      return ChatHistory.fromJson(data);
    }
    
    return null;
  }
  
  // Şaşırtıcı bilgi üretme
  Future<Message> sendSurpriseFact(Persona persona) async {
    _lastInteractionTime = DateTime.now();
    
    // Şaşırtıcı bilgi kategorileri
    final List<String> factCategories = [
      "tarih", "bilim", "uzay", "hayvanlar", "insan vücudu", "teknoloji", 
      "psikoloji", "sanat", "coğrafya", "kültür", "arkeoloji", "tıp"
    ];
    
    // Rastgele kategori seç
    final randomCategory = factCategories[_random.nextInt(factCategories.length)];
    
    final List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content': '''
        Sen ${persona.name} adlı bir bilgi uzmanısın. Çok şaşırtıcı, ilginç ve gerçek bir bilgiyi özellikle $randomCategory alanıyla ilgili paylaşacaksın.
        
        Kurallar:
        1. Verdiğin bilgi tamamen DOĞRU olmalı.
        2. Yaygın olarak bilinen değil, gerçekten ŞAŞIRTICIve AZ BİLİNEN bir bilgi olmalı.
        3. Bilgiyi kısa ve net bir şekilde açıkla, fazla detaya girme.
        4. Giriş cümlesi ilgi çekici olsun.
        5. Konuya özellikle "$randomCategory" alanından seç.
        6. ASLA yapay zeka olduğunu belirtme veya ima etme.
        
        Lütfen şaşırtıcı, gerçek, doğrulanabilir bir bilgi paylaş. Eğer çoğu insanın duyunca "vay be, bunu bilmiyordum!" diyebileceği bir bilgi olsun.
        '''
      },
      {
        'role': 'user',
        'content': 'Şaşırt beni!'
      }
    ];
    
    developer.log('OpenAI şaşırtıcı bilgi isteği gönderiliyor...', name: 'ChatService');
    
    // Tahmini token sayısını hesapla
    int estimatedTokenCount = 0;
    for (var msg in messages) {
      estimatedTokenCount += (msg['content'] ?? '').length ~/ 4;
    }
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': messages,
        'temperature': 1.0,
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Token kullanım bilgisi
        if (data['usage'] != null) {
          final inputTokens = data['usage']['prompt_tokens'] ?? estimatedTokenCount;
          final outputTokens = data['usage']['completion_tokens'] ?? 0;
          final totalTokens = data['usage']['total_tokens'] ?? 0;
          
          // Maliyet hesaplama
          final inputCost = (inputTokens / 1000) * _inputTokenCost;
          final outputCost = (outputTokens / 1000) * _outputTokenCost;
          final totalCostUsd = inputCost + outputCost;
          final totalCostTry = totalCostUsd * _usdToTryRate;
          
          developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens, Toplam: $totalTokens', name: 'ChatService');
          developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'ChatService');
        }
        
        return Message(
          id: _uuid.v4(),
          text: content,
          timestamp: DateTime.now(),
          isUser: false,
          sender: persona.name,
          isOffline: false,
        );
      } catch (e) {
        developer.log('Şaşırtıcı bilgi yanıtı işlenirken hata: $e', name: 'ChatService', error: e);
        throw Exception('Şaşırtıcı bilgi işlenemedi: $e');
      }
    } else {
      developer.log('OpenAI API hata yanıtı: ${response.body}', name: 'ChatService');
      throw Exception('Şaşırtıcı bilgi alınamadı: ${response.statusCode} ${response.body}');
    }
  }
} 