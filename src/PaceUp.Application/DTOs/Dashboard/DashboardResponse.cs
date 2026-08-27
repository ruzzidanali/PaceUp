using PaceUp.Application.DTOs.Activities;

namespace PaceUp.Application.DTOs.Dashboard;

public record DashboardResponse(
    DashboardActivitySummaryResponse ActivitySummary,
    IReadOnlyList<ActivityResponse> RecentActivities,
    IReadOnlyList<DashboardGoalResponse> ActiveGoals);