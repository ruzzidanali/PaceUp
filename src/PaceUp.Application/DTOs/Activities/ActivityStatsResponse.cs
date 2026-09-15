namespace PaceUp.Application.DTOs.Activities;

public record ActivityStatsResponse(
    int TotalActivities,
    double TotalDistance,
    int TotalDurationSeconds,
    int TotalCalories,
    IReadOnlyDictionary<string, int> ActivitiesByType,
    double? AverageSpeedKmh = null,
    double? AveragePaceSecondsPerKm = null,
    double? BestSpeedKmh = null,
    double? BestPaceSecondsPerKm = null);