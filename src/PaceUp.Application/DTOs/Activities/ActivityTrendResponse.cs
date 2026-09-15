namespace PaceUp.Application.DTOs.Activities;

public record ActivityTrendItemResponse(
    DateTime Date,
    int TotalActivities,
    double TotalDistance,
    int TotalDurationSeconds,
    double TotalCalories,
    double? AverageSpeedKmh = null,
    double? AveragePaceSecondsPerKm = null);

public record ActivityTrendResponse(
    DateTime? From,
    DateTime? To,
    string? Type,
    string GroupBy,
    IReadOnlyList<ActivityTrendItemResponse> Items);