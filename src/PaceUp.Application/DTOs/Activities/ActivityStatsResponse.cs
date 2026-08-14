namespace PaceUp.Application.DTOs.Activities;

public record ActivityStatsResponse(
    int TotalActivities,
    double TotalDistance,
    int TotalDurationSeconds,
    int TotalCalories);