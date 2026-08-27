namespace PaceUp.Application.DTOs.Challenges;

public record CreateChallengeRequest(
    string Name,
    string? Description,
    string Type,
    double TargetValue,
    DateTime StartDate,
    DateTime EndDate);