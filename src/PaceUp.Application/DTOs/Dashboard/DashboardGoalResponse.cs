namespace PaceUp.Application.DTOs.Dashboard;

public record DashboardGoalResponse(
    Guid Id,
    string Type,
    double Target,
    double Current,
    double Remaining,
    double ProgressPercentage,
    bool IsCompleted,
    DateTime StartDate,
    DateTime EndDate);