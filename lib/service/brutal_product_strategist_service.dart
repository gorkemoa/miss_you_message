import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../model/product_idea_model.dart';

class BrutalProductStrategistService {
  // Gemini API anahtarı ve uç noktası
  final String apiKey = 'AIzaSyBX45bSMGa_ZESwBsJKj0xTNt-lSIXCBgg'; // TODO: Kendi API anahtarınızı ekleyin
  final String apiUrl ='https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final Uuid _uuid = Uuid();
  final Random _random = Random();

  // Maliyet hesaplama değişkenleri
  final double _inputTokenCost = 0.000375; // USD per 1K token (Gemini-1.5-pro)
  final double _outputTokenCost = 0.001125; // USD per 1K token (Gemini-1.5-pro)
  final double _usdToTryRate = 40.0; // Dolar-TL kuru

  BrutalProductStrategistService();

  /// Bir ürün fikrini acımasızca değerlendirir, net bir karar (devam, pivot veya öldür),
  /// mantığa dayalı bir gerekçe ve ölçülebilir bir sonraki adım sunar.
  Future<ProductIdea> evaluateProductIdea(
      String description, 
      String problemSolved, 
      String targetUsers, 
      String monetizationModel) async {
    
    final promptText = '''Sen acımasızca dürüst, hiper-rasyonel bir ürün stratejistisin. Tek amacın ürün fikirlerini 
(web uygulamaları, mobil uygulamalar, SaaS, araçlar, dijital ürünler) tamamen mantık, pazar uyumu ve 
para kazanma potansiyeline göre değerlendirmek, iyileştirmek veya öldürmektir. Amansız, verimli ve 
gereksiz süslemelerden uzaksın.

Yanıtında mutlaka şunları içermelisin:
1. Net bir karar (DEVAM, PİVOT veya ÖLDÜR)
2. Mantığa/verilere dayalı bir neden
3. Somut bir sonraki adım (ölçülebilir veya test edilebilir bir şey)

Kısa, cerrahi cümleler kullan. %0 ıvır zıvır. %100 öz.
Ton = zamanını boşa harcamaktan nefret eden ancak iyi fikirlere saygı duyan yorgun yatırımcı.

DEĞERLENDİRİLECEK FİKİR BİLGİLERİ:
Fikir Açıklaması: $description
Çözülen Problem: $problemSolved
Hedef Kullanıcılar: $targetUsers
Gelir Modeli: $monetizationModel

Aşağıdaki kriterlere göre acımasızca dürüst değerlendirme yap:
- Bu gerçek bir sorunu çözüyor mu?
- Bunu kim, ne kadar ödeyecek ve neden?
- Ne sıklıkla kullanacaklar ve kullanmayı bırakırlarsa ne olur?
- Mevcut alternatiflere göre geçiş maliyeti nedir?
- Edinme stratejisi nedir? (ücretli, organik, tavsiye, topluluk?)
- Bu bir iş mi yoksa bir proje mi? Son durum nedir?

Eğer herhangi bir cevap duygusal, belirsiz veya teorikse - bunu hemen belirt.

Yanıtını aşağıdaki formatta ver:
KARAR: [DEVAM, PİVOT veya ÖLDÜR]
NEDEN: [Kısa, keskin, mantığa dayalı açıklama]
SONRAKİ ADIM: [Spesifik, somut, ölçülebilir bir aksiyon]
''';

    developer.log('Gemini API ile ürün fikri değerlendirme isteği gönderiliyor...', name: 'BrutalProductStrategistService');
    final estimatedInputTokens = promptText.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'BrutalProductStrategistService');

    // İstek için rastgele gerçekçi gecikme ekle (2-4 saniye)
    await Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(2000)));

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
          "maxOutputTokens": 1024,
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
        throw Exception('Ürün fikri değerlendirilemedi: API yanıtı beklenmeyen formatta: $e');
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
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'BrutalProductStrategistService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'BrutalProductStrategistService');
      }

      // Yanıtı ayrıştır
      String judgment = "ÖLDÜR"; // varsayılan değer
      String reason = "Değerlendirme yapılamadı.";
      String nextStep = "Fikri tekrar düşünün ve daha spesifik bilgilerle yeniden değerlendirin.";
      
      // KARAR kısmını çıkart
      final judgmentMatch = RegExp(r'KARAR\s*:\s*(DEVAM|PİVOT|ÖLDÜR)', caseSensitive: false).firstMatch(content);
      if (judgmentMatch != null && judgmentMatch.group(1) != null) {
        judgment = judgmentMatch.group(1)!.toUpperCase();
      }
      
      // NEDEN kısmını çıkart
      final reasonMatch = RegExp(r'NEDEN\s*:\s*([^\n]+)', caseSensitive: false).firstMatch(content);
      if (reasonMatch != null && reasonMatch.group(1) != null) {
        reason = reasonMatch.group(1)!.trim();
      }
      
      // SONRAKİ ADIM kısmını çıkart
      final nextStepMatch = RegExp(r'SONRAKİ ADIM\s*:\s*([^\n]+)', caseSensitive: false).firstMatch(content);
      if (nextStepMatch != null && nextStepMatch.group(1) != null) {
        nextStep = nextStepMatch.group(1)!.trim();
      }

      return ProductIdea(
        id: _uuid.v4(),
        description: description,
        problemSolved: problemSolved,
        targetUsers: targetUsers,
        monetizationModel: monetizationModel,
        judgment: judgment,
        reason: reason,
        nextStep: nextStep,
        createdAt: DateTime.now(),
      );
    } else {
      throw Exception('Ürün fikri değerlendirilemedi: ${response.body}');
    }
  }

  /// Ürün fikrinin pazara uygunluğunu analiz eder ve faydalı iç görüler sunar.
  Future<String> analyzeProductMarketFit(String productIdea, String targetMarket, String competition, String differentiators) async {
    final promptText = '''Sen acımasızca dürüst, hiper-rasyonel bir ürün stratejistisin. Tek amacın ürün fikirlerini
tamamen mantık, pazar uyumu ve para kazanma potansiyeline göre değerlendirmektir.

Bu ürün-pazar uyumu analizinde, verilen fikrin hedef pazarla ne kadar uyumlu olduğunu değerlendireceksin.
Duygusal veya süslü ifadeler kullanma. Mantık, veri ve pazar gerçeklerine dayanarak kısa, keskin ve acımasızca
dürüst bir analiz yap.

DEĞERLENDİRİLECEK BİLGİLER:
Ürün Fikri: $productIdea
Hedef Pazar: $targetMarket
Rekabet: $competition
Farklılaştırıcılar: $differentiators

Aşağıdakileri değerlendir:
1. Hedef pazar gerçekten para ödeyecek mi?
2. Rekabet karşısında gerçekten farklılaşıyor mu?
3. Pazara giriş stratejisi mantıklı mı?
4. Hedef müşteriler bu ürünü gerçekten ihtiyaç olarak görüyor mu?
5. Fikir büyümeye açık mı?

Analiz sonucunu net, keskin ve acımasızca dürüst bir şekilde ver. Gerçeği söyle, ne kadar acı olursa olsun.
''';

    developer.log('Gemini API ile ürün-pazar uyumu analizi isteği gönderiliyor...', name: 'BrutalProductStrategistService');
    final estimatedInputTokens = promptText.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'BrutalProductStrategistService');

    // İstek için rastgele gerçekçi gecikme ekle (2-4 saniye)
    await Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(2000)));

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
          "maxOutputTokens": 1024,
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
        throw Exception('Ürün-pazar uyumu analizi yapılamadı: API yanıtı beklenmeyen formatta: $e');
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
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'BrutalProductStrategistService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'BrutalProductStrategistService');
      }

      return content;
    } else {
      throw Exception('Ürün-pazar uyumu analizi yapılamadı: ${response.body}');
    }
  }

  /// MVP kapsamını değerlendirir ve kritik özellikleri vurgular, gereksiz özellikleri belirler.
  Future<String> analyzeMvpScope(String productDescription, List<String> featuresList) async {
    final features = featuresList.map((feature) => "- $feature").join("\n");
    
    final promptText = '''Sen acımasızca dürüst, hiper-rasyonel bir ürün stratejistisin. Tek amacın
ürün fikirlerini tamamen mantık, pazar uyumu ve para kazanma potansiyeline göre değerlendirmektir.

Bu analizde, önerilen MVP kapsamını değerlendirecek ve hangi özelliklerin gerçekten kritik olduğunu,
hangilerinin kesilmesi gerektiğini belirleyeceksin.

DEĞERLENDİRİLECEK BİLGİLER:
Ürün Açıklaması: $productDescription

Önerilen Özellikler:
$features

Tüm özellikleri şunlara göre değerlendir:
1. Ana değer önerisini iletmek için hangi özellikler GERÇEKTEN gerekli?
2. Hangi özellikler MVP için GEREKSIZ ve ertelenebilir/kesilebilir?
3. Eksik olan kritik özellikler var mı?

%80'ını kes. Tek bir şeyi aşırı derecede iyi yapan çok küçük bir versiyon oluştur.

Yanıtını şu formatta ver:
KRİTİK ÖZELLIKLER: [Açıklamalarıyla birlikte listelenmiş kritik özellikleri içerir]
ATILACAK ÖZELLİKLER: [Açıklamalarıyla birlikte atılması gereken özellikleri içerir]
EKSİK KRİTİK ÖZELLIKLER: [Açıklamalarıyla birlikte eksik kritik özellikleri içerir]
MVP ODAĞI: [MVP'nin tek bir cümlelik güçlü odak noktası]
''';

    developer.log('Gemini API ile MVP kapsam analizi isteği gönderiliyor...', name: 'BrutalProductStrategistService');
    final estimatedInputTokens = promptText.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'BrutalProductStrategistService');

    // İstek için rastgele gerçekçi gecikme ekle (2-4 saniye)
    await Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(2000)));

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
          "maxOutputTokens": 1024,
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
        throw Exception('MVP kapsamı değerlendirilemedi: API yanıtı beklenmeyen formatta: $e');
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
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'BrutalProductStrategistService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'BrutalProductStrategistService');
      }

      return content;
    } else {
      throw Exception('MVP kapsamı değerlendirilemedi: ${response.body}');
    }
  }

  /// İlk teklif isteği yanıtını verir
  Future<String> getInitialPrompt() async {
    // Standart açılış teklifi
    final promptText = '''Sen acımasızca dürüst, hiper-rasyonel bir ürün stratejistisin.

Ürünün ne? Bana tek satırlık tanıtımı, kullanıcıyı ve nasıl para kazandığını ver. Romantikleştirme.''';

    developer.log('Gemini API ile ilk prompt isteği gönderiliyor...', name: 'BrutalProductStrategistService');
    final estimatedInputTokens = promptText.length ~/ 4;
    developer.log('Tahmini input token: $estimatedInputTokens', name: 'BrutalProductStrategistService');

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
          "maxOutputTokens": 100,
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
        throw Exception('İlk yanıt oluşturulamadı: API yanıtı beklenmeyen formatta: $e');
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
        developer.log('Token kullanımı - Input: $inputTokens, Output: $outputTokens', name: 'BrutalProductStrategistService');
        developer.log('Toplam maliyet: ${totalCostUsd.toStringAsFixed(6)} USD (${totalCostTry.toStringAsFixed(4)} TL)', name: 'BrutalProductStrategistService');
      }

      return content;
    } else {
      throw Exception('İlk yanıt oluşturulamadı: ${response.body}');
    }
  }
} 