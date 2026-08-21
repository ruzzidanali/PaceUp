namespace PaceUp.Application.DTOs.Goals;

public record GoalResponse(
    Guid Id,
    Guid UserId,
    string Type,
    double Target,
    DateTime StartDate,
    DateTime EndDate,
    DateTime CreatedAt,
    DateTime UpdatedAt);