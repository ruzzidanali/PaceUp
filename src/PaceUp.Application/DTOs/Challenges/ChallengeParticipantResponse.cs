namespace PaceUp.Application.DTOs.Challenges;

public record ChallengeParticipantResponse(
    Guid UserId,
    string Username,
    string DisplayName,
    string? ProfileImageUrl,
    double CurrentValue,
    int Rank);