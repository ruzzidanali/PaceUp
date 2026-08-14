namespace PaceUp.Application.DTOs.Activities;

public record UpdateActivityRequest(
    string Type,
    double Distance,
    int DurationSeconds,
    int? Calories,
    DateTime StartedAt);