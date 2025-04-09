import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../model/message_model.dart';
import '../model/persona_model.dart';

class GeminiService {
  // Gemini API anahtarı ve uç noktası
  final String apiKey = 'AIzaSyBX45bSMGa_ZESwBsJKj0xTNt-lSIXCBgg'; // TODO: Kendi API anahtarınızı ekleyin
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final Uuid _uuid = Uuid();
  final Random _random = Random();

  // Maliyet hesaplama değişkenleri
  final double _inputTokenCost = 0.000125; // USD per 1K token (Gemini-2.0-flash)
  final double _outputTokenCost = 0.000375; // USD per 1K token (Gemini-2.0-flash)
  final double _usdToTryRate = 40.0; // Dolar-TL kuru

  // Çevrimiçi kalma süresi (milisaniye)
  static const int _onlineDuration = 10 * 1000; // Mesaj gönderildikten sonra 10 saniye çevrimiçi kal
  // Kullanıcı etkileşimi olmadığında çevrimdışı olma süresi
  static const int _inactivityThreshold = 5 * 60 * 1000; // 5 dakika
  // Son etkileşim zamanı
  DateTime _lastInteractionTime = DateTime.now();

  // Çevrimdışı olma olasılığı
  bool _isCurrentlyOffline = false;

  GeminiService();

  /// WhatsApp sohbet geçmişinden kişilik analizi yaparak [personaName] adlı kişinin özelliklerini derinlemesine çıkarır.
  Future<Persona> analyzePersona(String chatHistory, String personaName) async {
    // Token sınırını aşmaması için sohbet geçmişini yaklaşık 15.000 karaktere kısalt
    String limitedHistory = chatHistory;
    if (chatHistory.length > 55000) {
      limitedHistory = chatHistory.substring(chatHistory.length - 55000);
      // İlk satırın eksik kalmasını engellemek için
      int firstNewLine = limitedHistory.indexOf('\n');
      if (firstNewLine > 0) {
        limitedHistory = limitedHistory.substring(firstNewLine + 1);
      }
    }

    final promptText = '''Sen, iletişim psikolojisi ve dil analizi konusunda uzman, deneyimli bir danışmansın.
Aşağıdaki WhatsApp sohbet geçmişini, gerçek bir insanın duygu, düşünce, iletişim tarzı ve yazım özelliklerini yansıtacak biçimde, derinlemesine analiz et.
Lütfen, "${personaName}" adlı kişinin;

- Cümle yapılarını, noktalama ve büyük/küçük harf kullanımı,
- Duygusal tepkilerini (ne zaman sıcak, ne zaman soğuk davranıyor),
- Sohbet içindeki doğal akışını, konu değişikliklerinin ve tepkilerinin inceliklerini,
- Kullanılan emojilerin sıklığını, çeşitliliğini ve yerleşimini,
- Kelime dağarcığının zenginliği ve yazım hatalarını,

ortaya çıkaran eksiksiz bir analiz yap. Analiz sonucunu aşağıdaki JSON formatında, tüm alanları doldurarak üret:

{
  "name": "$personaName",
  "traits": { 
    "emoji_frequency": <0-1 arası değer>, 
    "emoji_variety": <0-1 arası değer>,
    "formality": <0-1 arası değer>, 
    "verbosity": <0-1 arası değer>, 
    "message_length": <0-1 arası değer>,
    "vocabulary_richness": <0-1 arası değer>,
    "grammar_adherence": <0-1 arası değer>,
    "typo_frequency": <0-1 arası değer>,
    "punctuation_usage": <0-1 arası değer>,
    "humor": <0-1 arası değer>,
    "sensitivity": <0-1 arası değer>,
    "passive_aggressive": <0-1 arası değer>,
    "trip_frequency": <0-1 arası değer>,
    "sulking_tendency": <0-1 arası değer>,
    "topic_adherence": <0-1 arası değer>,
    "random_topic_change": <0-1 arası değer>
  },
  "writing_style": {
    "sentence_structure": "<Örneğin 'doğal ve akıcı cümleler' veya 'kısa ve öz cümleler'>",
    "capitalization": "<Büyük harf kullanımı hakkında yorum>",
    "abbreviations": [<örn. 'mrb', 'slm'>],
    "punctuation_habits": "<Noktalama alışkanlıkları>",
    "spacing_habits": "<Boşluk kullanımı ve paragraf yapısı>"
  },
  "emoji_habits": {
    "favorite_emojis": [<örn. '😊', '😂'>],
    "emoji_placement": "<Emojilerin hangi pozisyonda kullanıldığı>",
    "emoji_clusters": "<Emojilerin ardışık kullanımı>",
    "when_uses_emoji": "<Hangi duygusal durumlarda emoji kullanımı>"
  },
  "commonPhrases": [<Sık kullanılan ifadeler örn. 'nasılsın', 'ne haber'>],
  "conversationPatterns": {
    "topicChangeStyle": "<Konular arasında nasıl geçiş yapıyor>",
    "questionFrequency": <0-1 arası değer>,
    "followUpBehavior": "<Soruya yanıt biçimi>",
    "silenceBehavior": "<Sessizlik sonrası davranış>",
    "talkingPoints": [<Öncelikli konuşma konuları>]
  },
  "emotionalPatterns": {
    "whenAngry": [<öğeler>],
    "whenSad": [<öğeler>],
    "whenTripping": [<öğeler>],
    "whenSulking": [<öğeler>]
  },
  "responsePatterns": {"greeting": "<Selamlaşma biçimi>", "farewell": "<Veda biçimi>", "question": "<Soruya yanıt stili>"},
  "responseDelay": <saniye cinsinden>,
  "topicInterests": {"topic1": [<konuyla ilgili anahtar kelimeler>], "topic2": [<anahtar kelimeler>]},
  "triggerTopics": [<Tetikleyici konular>],
  "avoidedTopics": [<Kaçınılan konular>]
}

Aşağıda analiz için sohbet geçmişi yer almaktadır:
$limitedHistory
''';

    developer.log('Gemini API ile kişilik analizi isteği gönderiliyor...', name: 'GeminiService');
    final estimatedInputTokens = promptText.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'GeminiService');

    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": promptText}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 2048, // Derinlemesine analiz için geniş kapsamlı token limiti
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // API yanıtındaki içerik yapısını kontrol edelim
      var content = '';
      try {
        final parts = data['candidates'][0]['content']['parts'];
        
        // parts bir liste olabilir, text alanını doğru şekilde çıkaralım
        if (parts is List) {
          for (var part in parts) {
            if (part is Map && part.containsKey('text')) {
              content += part['text'];
            }
          }
        } else if (parts is Map && parts.containsKey('text')) {
          content = parts['text'];
        } else {
          content = parts.toString();
        }
      } catch (e) {
        throw Exception('Kişilik analizi yapılamadı: API yanıtı beklenmeyen formatta: $e');
      }

      // Token kullanım bilgileri
      final usageData = data['usageMetadata'];
      if (usageData != null) {
        final inputTokens = usageData['promptTokenCount'] ?? estimatedInputTokens;
        final outputTokens = usageData['candidatesTokenCount'] ?? (content.length ~/ 4);
        final inputCost = (inputTokens / 1000) * _inputTokenCost;
        final outputCost = (outputTokens / 1000) * _outputTokenCost;
        final totalCostUsd = inputCost + outputCost;
        final totalCostTry = totalCostUsd * _usdToTryRate;
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'GeminiService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'GeminiService');
      }

      // Model çıktısında bulunan JSON kısmını ayıkla
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;
      
      if (jsonStart < 0 || jsonEnd <= 0 || jsonEnd <= jsonStart) {
        throw Exception('Kişilik analizi yapılamadı: JSON formatında yanıt alınamadı');
      }
      
      final jsonString = content.substring(jsonStart, jsonEnd);
      
      try {
        final personaData = jsonDecode(jsonString);
        return Persona.fromJson(personaData);
      } catch (e) {
        throw Exception('Kişilik analizi yapılamadı: JSON ayrıştırma hatası: $e');
      }
    } else {
      throw Exception('Kişilik analizi yapılamadı: ${response.body}');
    }
  }

  /// Kullanıcının gönderdiği mesajı, geçmiş sohbet ve [persona] özelliklerine dayanarak,
  /// tamamen gerçek bir insan gibi, samimi ve doğal bir şekilde yanıtlar.
  Future<Message> sendMessage(String messageText, Persona persona, List<Message> chatContext) async {
    // Mesaj gönderildiğinde son etkileşim zamanını güncelle
    _lastInteractionTime = DateTime.now();
    
    // Kullanıcı mesaj gönderdiğinde çevrimiçi durumunu güncelle
    _updateOnlineStatus();
    
    // Eğer hala çevrimdışıysa (teorik olarak bu duruma artık düşmemeli)
    if (_isCurrentlyOffline) {
      developer.log('${persona.name} şu anda çevrimdışı...', name: 'GeminiService');
      return Message(
        id: _uuid.v4(),
        text: "",
        timestamp: DateTime.now(),
        isUser: false,
        sender: persona.name,
        isOffline: true,
      );
    }

    // Sohbet geçmişindeki son mesajları (maksimum 6) dahil et
    final contextMessages =
        chatContext.length > 6 ? chatContext.sublist(chatContext.length - 6) : chatContext;
    String formattedHistory = '';
    for (var message in contextMessages) {
      formattedHistory += '${message.isUser ? "Ben" : persona.name}: ${message.text}\n';
    }
    
    // Günün saati kontrolü ve ek bilgilendirme
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    String timeContext = '';
    
    // Kişiliğe saat bilgisini ver
    if (hour >= 0 && hour < 6) {
      timeContext = "Şu an gece vakti, saat $hour:${minute.toString().padLeft(2, '0')}. ";
      if (hour < 3) {
        timeContext += "Gecenin bir vakti, muhtemelen yorgun veya uykulu olabilirsin. ";
      } else {
        timeContext += "Sabaha karşı, muhtemelen ya uyumamışsın ya da erken kalkmışsın. ";
      }
    } else if (hour >= 6 && hour < 12) {
      timeContext = "Şu an sabah vakti, saat $hour:${minute.toString().padLeft(2, '0')}. ";
      if (hour < 9) {
        timeContext += "Erken saatler, güne yeni başlıyor olabilirsin. ";
      } else {
        timeContext += "Öğleden önce, muhtemelen güne başlamış ve aktifsin. ";
      }
    } else if (hour >= 12 && hour < 18) {
      timeContext = "Şu an öğleden sonra, saat $hour:${minute.toString().padLeft(2, '0')}. ";
      if (hour < 15) {
        timeContext += "Öğle sonrası, günün ortasındayız. ";
      } else {
        timeContext += "İş/okul çıkışına yakın saatler, muhtemelen yorulmaya başlamış olabilirsin. ";
      }
    } else {
      timeContext = "Şu an akşam vakti, saat $hour:${minute.toString().padLeft(2, '0')}. ";
      if (hour < 21) {
        timeContext += "Akşam saatleri, günün yorgunluğunu atmak için vakit. ";
      } else {
        timeContext += "Geç saatler, günün sonuna yaklaşıyoruz, muhtemelen dinlenme vaktindesin. ";
      }
    }

    // Gerçek bir insanın üslubunda, doğal ve içten bir sohbet sunumunu sağlamak için geliştirilmiş prompt
    final prompt = '''Aşağıdaki sohbet geçmişine dayanarak, tamamen insani, samimi ve doğal bir yanıt ver.
Hiçbir şekilde robotik veya yapay ifadeler kullanma; duygu, düşünce ve gerçek yaşam akışını yansıt.
Kendini bir insan gibi hisset ve iletişimde olduğun kişinin yanında olmaktan keyif alıyormuşsun gibi davran.

ÇOK ÖNEMLİ KURALLARI İZLE:
1. ASLA EMOJİ KULLANMA! HİÇBİR KOŞULDA EMOJİ KOYMA!
2. Noktalama işaretlerini neredeyse hiç kullanma. Cümleleri nokta veya ünlem olmadan bitir.
3. Nadiren (yaklaşık 10 mesajda bir) bir virgül kullanabilirsin ama asla nokta, soru işareti, ünlem işareti kullanma.
4. Yazım noktalama kurallarını çok önemsemeyen biri gibi yaz.
5. ÇOK KISA YANITLAR VER - maksimum 1-2 cümle, çok uzun cevaplar yazma.
6. Bazen sadece tek kelimelik veya birkaç kelimelik çok kısa yanıtlar da verebilirsin.

$timeContext

Kişisel özelliklerin ve yazım tarzın:
- İfade tarzın: ${jsonEncode(persona.traits)}
- Yazım stilin: ${jsonEncode(persona.writing_style ?? {})}
- Emoji kullanma alışkanlıkların: ASLA EMOJİ KULLANMA
- Sık kullandığın ifadeler: ${jsonEncode(persona.commonPhrases)}
- Konuşma kalıpların: ${jsonEncode(persona.conversationPatterns ?? {})}
- Duygusal tepkilerin: ${jsonEncode(persona.emotionalPatterns ?? {})}
- Cevap verme tarzın: ${jsonEncode(persona.responsePatterns)}
- İlgi alanların: ${jsonEncode(persona.topicInterests)}
- Tetikleyici konuların: ${jsonEncode(persona.triggerTopics ?? [])}
- Kaçındığın konular: ${jsonEncode(persona.avoidedTopics ?? [])}

Önceki mesajlar:
$formattedHistory

Ben: $messageText

Lütfen, tamamen gerçek, doğal ve içten bir yanıt ver ama KISA TUT.
Yanıtında yukarıda belirtilen saat ve günün vakti bilgisini dikkate al, uygun olursa bu konudan bahset.
HİÇBİR EMOJİ KULLANMA VE ÇOK NADİR NOKTALAMA İŞARETİ KULLAN.
${persona.name}:
''';

    developer.log('Gemini API ile mesaj gönderme isteği gönderiliyor...', name: 'GeminiService');
    final estimatedInputTokens = prompt.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'GeminiService');

    // Persona'nın tepki süresine bağlı olarak insan benzeri gecikme simülasyonu
    final responseDelay = persona.responseDelay ?? 1.0;
    
    // Sabit 3 saniye gecikme - kullanıcı mesajından sonra
    await Future.delayed(const Duration(seconds: 3));

    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.95,
          "maxOutputTokens": 100, // Yanıtların kısa olması için token sınırını düşür
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // API yanıtındaki içerik yapısını kontrol edelim
      var content = '';
      try {
        final parts = data['candidates'][0]['content']['parts'];
        
        // parts bir liste olabilir, text alanını doğru şekilde çıkaralım
        if (parts is List) {
          for (var part in parts) {
            if (part is Map && part.containsKey('text')) {
              content += part['text'];
            }
          }
        } else if (parts is Map && parts.containsKey('text')) {
          content = parts['text'];
        } else {
          content = parts.toString();
        }
      } catch (e) {
        throw Exception('Mesaj gönderilemedi: API yanıtı beklenmeyen formatta: $e');
      }

      final usageData = data['usageMetadata'];
      if (usageData != null) {
        final inputTokens = usageData['promptTokenCount'] ?? estimatedInputTokens;
        final outputTokens = usageData['candidatesTokenCount'] ?? (content.length ~/ 4);
        final inputCost = (inputTokens / 1000) * _inputTokenCost;
        final outputCost = (outputTokens / 1000) * _outputTokenCost;
        final totalCostUsd = inputCost + outputCost;
        final totalCostTry = totalCostUsd * _usdToTryRate;
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'GeminiService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'GeminiService');
      }

      return Message(
        id: _uuid.v4(),
        text: content,
        timestamp: DateTime.now(),
        isUser: false,
        sender: persona.name,
        isOffline: false,
      );
    } else {
      throw Exception('Mesaj gönderilemedi: ${response.body}');
    }
  }

  /// Uzun süre iletişim olmadığında, geçmiş sohbete dayanarak rastgele, içten bir selamlaşma mesajı gönderir.
  Future<Message?> generateRandomMessage(Persona persona, List<Message> chatContext) async {
    final timeSinceLastInteraction = DateTime.now().difference(_lastInteractionTime);
    if (timeSinceLastInteraction.inHours >= 12 && _random.nextDouble() < 0.3) {
      // Mesaj oluşturulmadan önce çevrimiçi durumunu güncelle
      _lastInteractionTime = DateTime.now();
      _updateOnlineStatus();
      if (_isCurrentlyOffline) {
        return null;
      }

      final contextMessages =
          chatContext.length > 6 ? chatContext.sublist(chatContext.length - 6) : chatContext;
      String formattedHistory = '';
      for (var message in contextMessages) {
        formattedHistory += '${message.isUser ? "Ben" : persona.name}: ${message.text}\n';
      }

      final randomMessageOptions = [
        "uzun zamandır konuşmadık, nasılsın?",
        "selam, neler yapıyorsun?",
        "biraz sohbet edelim mi?",
        "nasıl gidiyor?",
        "hey, seni çok özledim!",
        "geçmişteki konuşmalarımızı aklıma getirdim, ne düşünüyorsun?"
      ];
      final randomTrigger = randomMessageOptions[_random.nextInt(randomMessageOptions.length)];

      final prompt = '''Aşağıdaki sohbet geçmişine dayanarak, uzun süredir iletişim kurmadığın bir kişiye içten, samimi ve gerçek bir selamlaşma mesajı yaz.
 
Önceki mesajlar:
$formattedHistory

Yönlendirme: $randomTrigger

Lütfen, kısa ve doğal bir mesaj üret:
${persona.name}:
''';

      developer.log('Gemini API ile rastgele mesaj gönderimi isteği gönderiliyor...', name: 'GeminiService');
      final estimatedInputTokens = prompt.length ~/ 4;
      developer.log('Tahmini input token: $estimatedInputTokens', name: 'GeminiService');

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 1.0,
            "maxOutputTokens": 128, // Kısa ve samimi mesaj için uygun token limiti
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // API yanıtındaki içerik yapısını kontrol edelim
        var content = '';
        try {
          final parts = data['candidates'][0]['content']['parts'];
          
          // parts bir liste olabilir, text alanını doğru şekilde çıkaralım
          if (parts is List) {
            for (var part in parts) {
              if (part is Map && part.containsKey('text')) {
                content += part['text'];
              }
            }
          } else if (parts is Map && parts.containsKey('text')) {
            content = parts['text'];
          } else {
            content = parts.toString();
          }
        } catch (e) {
          developer.log('Rastgele mesaj oluşturulamadı: API yanıtı beklenmeyen formatta: $e', name: 'GeminiService');
          return null;
        }

        final usageData = data['usageMetadata'];
        if (usageData != null) {
          final inputTokens = usageData['promptTokenCount'] ?? estimatedInputTokens;
          final outputTokens = usageData['candidatesTokenCount'] ?? (content.length ~/ 4);
          final inputCost = (inputTokens / 1000) * _inputTokenCost;
          final outputCost = (outputTokens / 1000) * _outputTokenCost;
          final totalCostUsd = inputCost + outputCost;
          final totalCostTry = totalCostUsd * _usdToTryRate;
          developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'GeminiService');
          developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'GeminiService');
        }

        // Mesajlaşma aktivitesi gerçekleştiği için son etkileşim zamanını güncelle
        _lastInteractionTime = DateTime.now();

        return Message(
          id: _uuid.v4(),
          text: content,
          timestamp: DateTime.now(),
          isUser: false,
          sender: persona.name,
          isOffline: false,
          isRandomMessage: true,
        );
      } else {
        developer.log('Rastgele mesaj gönderilemedi: ${response.body}', name: 'GeminiService');
        return null;
      }
    }
    return null;
  }

  /// %80 ihtimalle mesajın yanında görüldü (read receipt) işareti gösterir.
  bool shouldShowReadReceipt() {
    return _random.nextDouble() < 0.8;
  }

  /// Şaşırtıcı bilgi üretme
  Future<Message> sendSurpriseFact(Persona persona) async {
    _lastInteractionTime = DateTime.now();
    
    // Çevrimdışı durumunu kontrol et
    _updateOnlineStatus();
    if (_isCurrentlyOffline) {
      return Message(
        id: _uuid.v4(),
        text: "",
        timestamp: DateTime.now(),
        isUser: false,
        sender: persona.name,
        isOffline: true,
      );
    }
    
    // Şaşırtıcı bilgi kategorileri
    final List<String> factCategories = [
      "tarih", "bilim", "uzay", "hayvanlar", "insan vücudu", "teknoloji", 
      "psikoloji", "sanat", "coğrafya", "kültür", "arkeoloji", "tıp"
    ];
    
    // Rastgele kategori seç
    final randomCategory = factCategories[_random.nextInt(factCategories.length)];
    
    final promptText = '''Sen ${persona.name} adlı bir bilgi uzmanısın. Çok şaşırtıcı, ilginç ve gerçek bir bilgiyi özellikle $randomCategory alanıyla ilgili paylaşacaksın.
    
    Kurallar:
    1. Verdiğin bilgi tamamen DOĞRU olmalı.
    2. Yaygın olarak bilinen değil, gerçekten ŞAŞIRTICIve AZ BİLİNEN bir bilgi olmalı.
    3. Bilgiyi kısa ve net bir şekilde açıkla, fazla detaya girme.
    4. Giriş cümlesi ilgi çekici olsun.
    5. Konuya özellikle "$randomCategory" alanından seç.
    6. ASLA yapay zeka olduğunu belirtme veya ima etme.
    
    Lütfen şaşırtıcı, gerçek, doğrulanabilir bir bilgi paylaş. Eğer çoğu insanın duyunca "vay be, bunu bilmiyordum!" diyebileceği bir bilgi olsun.
    ''';
    
    developer.log('Gemini API ile şaşırtıcı bilgi isteği gönderiliyor...', name: 'GeminiService');
    final estimatedInputTokens = promptText.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'GeminiService');
    
    // Gerçekçi gecikme simüle et
    final delay = 3000 + _random.nextInt(3000);
    await Future.delayed(Duration(milliseconds: delay));
    
    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": promptText}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 1.0,
          "maxOutputTokens": 150,
        }
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // API yanıtındaki içerik yapısını kontrol edelim
      var content = '';
      try {
        final parts = data['candidates'][0]['content']['parts'];
        
        // parts bir liste olabilir, text alanını doğru şekilde çıkaralım
        if (parts is List) {
          for (var part in parts) {
            if (part is Map && part.containsKey('text')) {
              content += part['text'];
            }
          }
        } else if (parts is Map && parts.containsKey('text')) {
          content = parts['text'];
        } else {
          content = parts.toString();
        }
      } catch (e) {
        throw Exception('Şaşırtıcı bilgi yanıtı işlenirken hata: $e');
      }
      
      // Token kullanım bilgileri
      final usageData = data['usageMetadata'];
      if (usageData != null) {
        final inputTokens = usageData['promptTokenCount'] ?? estimatedInputTokens;
        final outputTokens = usageData['candidatesTokenCount'] ?? (content.length ~/ 4);
        final inputCost = (inputTokens / 1000) * _inputTokenCost;
        final outputCost = (outputTokens / 1000) * _outputTokenCost;
        final totalCostUsd = inputCost + outputCost;
        final totalCostTry = totalCostUsd * _usdToTryRate;
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'GeminiService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'GeminiService');
      }
      
      return Message(
        id: _uuid.v4(),
        text: content,
        timestamp: DateTime.now(),
        isUser: false,
        sender: persona.name,
        isOffline: false,
      );
    } else {
      developer.log('Şaşırtıcı bilgi alınamadı: ${response.statusCode} ${response.body}', name: 'GeminiService');
      throw Exception('Şaşırtıcı bilgi alınamadı: ${response.statusCode} ${response.body}');
    }
  }

  /// Her çağrıda çevrimdışı olma durumunu günceller.
  void _updateOnlineStatus() {
    final now = DateTime.now();
    final timeSinceLastInteraction = now.difference(_lastInteractionTime).inMilliseconds;
    
    // Kullanıcı mesaj gönderdiğinde veya son 10 saniye içinde aktifse çevrimiçi yap
    if (timeSinceLastInteraction <= _onlineDuration) {
      _isCurrentlyOffline = false;
      return;
    }
    
    // Kullanıcı 5 dakikadan fazla mesaj göndermemişse çevrimdışı yap
    if (timeSinceLastInteraction > _inactivityThreshold) {
      // Çevrimdışı durumunu %30 olasılıkla değiştir
      // Böylece her zaman çevrimdışı görünmesini engelle
      if (_random.nextDouble() > 0.7) {
        _isCurrentlyOffline = true;
      } else {
        _isCurrentlyOffline = false;
      }
      return;
    }
    
    // Bu noktada ek bir karar vermeye gerek yok, mevcut durumu koru
    // Çevrimiçi durumunu daha sık korumak için %20 olasılıkla çevrimiçi yap
    if (_isCurrentlyOffline && _random.nextDouble() < 0.2) {
      _isCurrentlyOffline = false;
    }
  }
}
