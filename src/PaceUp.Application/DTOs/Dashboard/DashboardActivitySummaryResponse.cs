namespace PaceUp.Application.DTOs.Dashboard;

public record DashboardActivitySummaryResponse(
    int TotalActivities,
    double TotalDistance,
    int TotalDurationSeconds,
    int TotalCalories);