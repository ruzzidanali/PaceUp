namespace PaceUp.Application.DTOs.Activities;

public record ActivityTrendItemResponse(
    DateTime Date,
    int TotalActivities,
    double TotalDistance,
    int TotalDurationSeconds,
    double TotalCalories);