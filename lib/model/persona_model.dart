class Persona {
  final String name;
  final Map<String, double> traits;
  final Map<String, dynamic>? writing_style;
  final Map<String, dynamic>? emoji_habits;
  final List<String> commonPhrases;
  final Map<String, dynamic>? conversationPatterns;
  final Map<String, String> responsePatterns;
  final double responseDelay;
  final Map<String, List<String>> topicInterests;
  final Map<String, List<String>>? emotionalPatterns;
  final List<String>? triggerTopics;
  final List<String>? avoidedTopics;

  Persona({
    required this.name,
    required this.traits,
    this.writing_style,
    this.emoji_habits,
    required this.commonPhrases,
    this.conversationPatterns,
    required this.responsePatterns,
    required this.responseDelay,
    required this.topicInterests,
    this.emotionalPatterns,
    this.triggerTopics,
    this.avoidedTopics,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    try {
      // Name kontrolü
      final name = json['name'] is String 
          ? json['name'] as String 
          : json['name'].toString();
      
      // Traits kontrolü
      Map<String, double> traits = {};
      if (json['traits'] is Map) {
        (json['traits'] as Map).forEach((key, value) {
          if (value is double) {
            traits[key.toString()] = value;
          } else if (value is int) {
            traits[key.toString()] = value.toDouble();
          } else if (value is String) {
            traits[key.toString()] = double.tryParse(value) ?? 0.5;
          } else {
            traits[key.toString()] = 0.5; // Varsayılan değer
          }
        });
      }
      
      // Writing Style kontrolü
      Map<String, dynamic>? writingStyle;
      if (json['writing_style'] is Map) {
        writingStyle = {};
        (json['writing_style'] as Map).forEach((key, value) {
          writingStyle![key.toString()] = value;
        });
      }
      
      // Common Phrases kontrolü
      List<String> commonPhrases = [];
      if (json['commonPhrases'] is List) {
        commonPhrases = (json['commonPhrases'] as List)
            .map((item) => item?.toString() ?? '')
            .toList();
      }
      
      // Response Patterns kontrolü
      Map<String, String> responsePatterns = {};
      if (json['responsePatterns'] is Map) {
        (json['responsePatterns'] as Map).forEach((key, value) {
          responsePatterns[key.toString()] = value?.toString() ?? '';
        });
      }
      
      // Response Delay kontrolü
      double responseDelay = 1.0;
      if (json['responseDelay'] is double) {
        responseDelay = json['responseDelay'];
      } else if (json['responseDelay'] is int) {
        responseDelay = (json['responseDelay'] as int).toDouble();
      } else if (json['responseDelay'] is String) {
        responseDelay = double.tryParse(json['responseDelay']) ?? 1.0;
      }
      
      // Topic Interests kontrolü
      Map<String, List<String>> topicInterests = {};
      if (json['topicInterests'] is Map) {
        (json['topicInterests'] as Map).forEach((key, value) {
          if (value is List) {
            topicInterests[key.toString()] = 
                (value as List).map((item) => item?.toString() ?? '').toList();
          } else if (value is String) {
            topicInterests[key.toString()] = [value];
          } else {
            topicInterests[key.toString()] = [];
          }
        });
      }
      
      // Emotional Patterns kontrolü
      Map<String, List<String>>? emotionalPatterns;
      if (json['emotionalPatterns'] is Map) {
        emotionalPatterns = {};
        (json['emotionalPatterns'] as Map).forEach((key, value) {
          if (value is List) {
            emotionalPatterns![key.toString()] = 
                (value as List).map((item) => item?.toString() ?? '').toList();
          } else if (value is String) {
            emotionalPatterns![key.toString()] = [value];
          } else {
            emotionalPatterns![key.toString()] = [];
          }
        });
      }
      
      // Trigger Topics kontrolü
      List<String>? triggerTopics;
      if (json['triggerTopics'] is List) {
        triggerTopics = (json['triggerTopics'] as List)
            .map((item) => item?.toString() ?? '')
            .toList();
      }
      
      // Avoided Topics kontrolü
      List<String>? avoidedTopics;
      if (json['avoidedTopics'] is List) {
        avoidedTopics = (json['avoidedTopics'] as List)
            .map((item) => item?.toString() ?? '')
            .toList();
      }
      
      return Persona(
        name: name,
        traits: traits,
        writing_style: writingStyle,
        emoji_habits: json['emoji_habits'],
        commonPhrases: commonPhrases,
        conversationPatterns: json['conversationPatterns'],
        responsePatterns: responsePatterns,
        responseDelay: responseDelay,
        topicInterests: topicInterests,
        emotionalPatterns: emotionalPatterns,
        triggerTopics: triggerTopics,
        avoidedTopics: avoidedTopics,
      );
    } catch (e) {
      throw Exception('Persona JSON ayrıştırma hatası: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'traits': traits,
      'writing_style': writing_style,
      'emoji_habits': emoji_habits,
      'commonPhrases': commonPhrases,
      'conversationPatterns': conversationPatterns,
      'responsePatterns': responsePatterns,
      'responseDelay': responseDelay,
      'topicInterests': topicInterests,
      'emotionalPatterns': emotionalPatterns,
      'triggerTopics': triggerTopics,
      'avoidedTopics': avoidedTopics,
    };
  }
} 