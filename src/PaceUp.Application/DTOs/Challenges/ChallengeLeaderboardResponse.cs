namespace PaceUp.Application.DTOs.Challenges;

public record ChallengeLeaderboardResponse(
    Guid ChallengeId,
    IReadOnlyList<ChallengeParticipantResponse> Participants);