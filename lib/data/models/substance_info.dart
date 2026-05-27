class AdverseEventInfo {
  final String name;
  final double? frequencyPercent;

  const AdverseEventInfo({required this.name, this.frequencyPercent});

  factory AdverseEventInfo.fromJson(Map<String, dynamic> j) =>
      AdverseEventInfo(
        name: j['name'] as String,
        frequencyPercent: (j['frequencyPercent'] as num?)?.toDouble(),
      );
}

class InteractionInfo {
  final String withId;
  final String withName;
  final String severity; // major | moderate | minor
  final String description;

  const InteractionInfo({
    required this.withId,
    required this.withName,
    required this.severity,
    required this.description,
  });

  factory InteractionInfo.fromJson(Map<String, dynamic> j) => InteractionInfo(
        withId: j['withId'] as String,
        withName: j['withName'] as String,
        severity: j['severity'] as String,
        description: j['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'withId': withId,
        'withName': withName,
        'severity': severity,
        'description': description,
      };
}

class SubstanceInfo {
  final String id;
  final String name;
  final String type; // 'medication' | 'supplement'
  final String? category;
  final String? atcCode;
  final String? mechanism;
  final String? halfLife;
  final String? commonDosage;
  final String? evidenceGrade;
  final List<AdverseEventInfo> adverseEvents;
  final List<InteractionInfo> interactions;
  final bool isLocal;

  const SubstanceInfo({
    required this.id,
    required this.name,
    required this.type,
    this.category,
    this.atcCode,
    this.mechanism,
    this.halfLife,
    this.commonDosage,
    this.evidenceGrade,
    this.adverseEvents = const [],
    this.interactions = const [],
    this.isLocal = true,
  });

  factory SubstanceInfo.fromJson(Map<String, dynamic> j, {bool isLocal = true}) =>
      SubstanceInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        category: j['category'] as String?,
        atcCode: j['atcCode'] as String?,
        mechanism: j['mechanism'] as String?,
        halfLife: j['halfLife'] as String?,
        commonDosage: j['commonDosage'] as String?,
        evidenceGrade: j['evidenceGrade'] as String?,
        adverseEvents: ((j['adverseEvents'] as List?) ?? [])
            .map((e) => AdverseEventInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        interactions: ((j['interactions'] as List?) ?? [])
            .map((e) => InteractionInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLocal: isLocal,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'category': category,
        'atcCode': atcCode,
        'mechanism': mechanism,
        'halfLife': halfLife,
        'commonDosage': commonDosage,
        'evidenceGrade': evidenceGrade,
        'adverseEvents': adverseEvents.map((e) => {'name': e.name, 'frequencyPercent': e.frequencyPercent}).toList(),
        'interactions': interactions.map((e) => e.toJson()).toList(),
      };
}

class InteractionAlert {
  final String substanceAName;
  final String substanceBName;
  final String severity;
  final String description;

  const InteractionAlert({
    required this.substanceAName,
    required this.substanceBName,
    required this.severity,
    required this.description,
  });
}
