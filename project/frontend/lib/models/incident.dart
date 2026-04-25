class Incident {
  final String id;
  final String type;
  final String location;
  final String description;
  final String severity; // P0, P1, P2, P3
  final String status;   // active, contained, resolved
  final String reporterType;
  final String zone;
  final String assignee;
  final List<String> responders;
  final String aiAction;
  final List<String> updates;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Incident({
    required this.id,
    required this.type,
    required this.location,
    required this.description,
    required this.severity,
    required this.status,
    required this.reporterType,
    required this.zone,
    required this.assignee,
    required this.responders,
    required this.aiAction,
    required this.updates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incident.fromRtdb(String key, Map<String, dynamic> data) {
    return Incident(
      id:           data['id'] ?? key,
      type:         data['type'] ?? 'Unknown',
      location:     data['location'] ?? '',
      description:  data['description'] ?? '',
      severity:     data['severity'] ?? 'P2',
      status:       data['status'] ?? 'active',
      reporterType: data['reporter_type'] ?? 'manual',
      zone:         data['zone'] ?? '',
      assignee:     data['assignee'] ?? 'Unassigned',
      responders:   List<String>.from(data['responders'] ?? []),
      aiAction:     data['ai_action'] ?? 'AI triage in progress...',
      updates:      List<String>.from(data['updates'] ?? []),
      createdAt:    data['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int)
          : DateTime.now(),
      updatedAt:    data['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updated_at'] as int)
          : DateTime.now(),
    );
  }

  bool get isCritical => severity == 'P0';
  bool get isActive    => status == 'active';
  bool get needsStaff  => responders.isEmpty && isActive;

  String get severityLabel {
    switch (severity) {
      case 'P0': return 'CRITICAL';
      case 'P1': return 'HIGH';
      case 'P2': return 'MEDIUM';
      case 'P3': return 'LOW';
      default:   return 'UNKNOWN';
    }
  }

  Incident copyWith({String? status, String? assignee, List<String>? responders}) {
    return Incident(
      id: id, type: type, location: location, description: description,
      severity: severity, status: status ?? this.status,
      reporterType: reporterType, zone: zone,
      assignee: assignee ?? this.assignee,
      responders: responders ?? this.responders,
      aiAction: aiAction, updates: updates,
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}
