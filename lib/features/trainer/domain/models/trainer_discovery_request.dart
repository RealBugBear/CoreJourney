class TrainerDiscoveryRequest {
  const TrainerDiscoveryRequest({
    required this.relationshipId,
    required this.clientId,
    required this.displayName,
    required this.createdAt,
  });

  final String relationshipId;
  final String clientId;
  final String displayName;
  final DateTime createdAt;

  factory TrainerDiscoveryRequest.fromJson(Map<String, dynamic> json) {
    return TrainerDiscoveryRequest(
      relationshipId: json['relationship_id'] as String,
      clientId: json['client_id'] as String,
      displayName: json['display_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
