class ProductIdea {
  final String id;
  final String description;
  final String problemSolved;
  final String targetUsers;
  final String monetizationModel;
  final String judgment;
  final String reason;
  final String nextStep;
  final DateTime createdAt;

  ProductIdea({
    required this.id,
    required this.description,
    required this.problemSolved,
    required this.targetUsers,
    required this.monetizationModel,
    required this.judgment,
    required this.reason,
    required this.nextStep,
    required this.createdAt,
  });

  factory ProductIdea.fromJson(Map<String, dynamic> json) {
    return ProductIdea(
      id: json['id'],
      description: json['description'],
      problemSolved: json['problemSolved'],
      targetUsers: json['targetUsers'],
      monetizationModel: json['monetizationModel'],
      judgment: json['judgment'],
      reason: json['reason'],
      nextStep: json['nextStep'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'problemSolved': problemSolved,
      'targetUsers': targetUsers,
      'monetizationModel': monetizationModel,
      'judgment': judgment,
      'reason': reason,
      'nextStep': nextStep,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ProductEvaluation {
  final List<ProductIdea> ideas;

  ProductEvaluation({
    required this.ideas,
  });

  factory ProductEvaluation.fromJson(Map<String, dynamic> json) {
    return ProductEvaluation(
      ideas: (json['ideas'] as List)
          .map((idea) => ProductIdea.fromJson(idea))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ideas': ideas.map((idea) => idea.toJson()).toList(),
    };
  }
} 