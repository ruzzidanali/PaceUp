namespace PaceUp.Application.DTOs.Activities;

public record ActivityResponse(
    Guid Id,
    Guid UserId,
    string Type,
    double Distance,
    int DurationSeconds,
    int? Calories,
    DateTime StartedAt,
    DateTime CreatedAt);