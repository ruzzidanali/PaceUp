namespace PaceUp.Application.DTOs.Challenges;

public record UpdateChallengeRequest(
    string Name,
    string? Description,
    string Type,
    double TargetValue,
    DateTime StartDate,
    DateTime EndDate);