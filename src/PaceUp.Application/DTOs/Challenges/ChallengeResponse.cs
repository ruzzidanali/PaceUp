namespace PaceUp.Application.DTOs.Challenges;

public record ChallengeResponse(
    Guid Id,
    Guid CreatedByUserId,
    string Name,
    string? Description,
    string Type,
    double TargetValue,
    DateTime StartDate,
    DateTime EndDate,
    DateTime CreatedAt,
    int ParticipantCount);