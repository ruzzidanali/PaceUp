namespace PaceUp.Application.DTOs.Activities;

public record CreateActivityRequest(
    string Type,
    double Distance,
    int DurationSeconds,
    int? Calories,
    DateTime StartedAt);