namespace PaceUp.Application.DTOs.Challenges;

public record ChallengeProgressResponse(
    Guid ChallengeId,
    Guid UserId,
    string Type,
    double TargetValue,
    double CurrentValue,
    double RemainingValue,
    double ProgressPercentage,
    bool IsCompleted);