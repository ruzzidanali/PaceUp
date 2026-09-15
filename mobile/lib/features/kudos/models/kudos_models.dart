class KudosResponse {
  final String activityId;
  final int kudosCount;
  final bool hasGivenKudos;

  const KudosResponse({
    required this.activityId,
    required this.kudosCount,
    required this.hasGivenKudos,
  });

  factory KudosResponse.fromJson(Map<String, dynamic> json) {
    return KudosResponse(
      activityId: json['activityId'] as String,
      kudosCount: json['kudosCount'] as int,
      hasGivenKudos: json['hasGivenKudos'] as bool,
    );
  }
}