namespace PaceUp.Application.DTOs.Goals;

public record GoalProgressResponse(
    Guid GoalId,
    string Type,
    double Target,
    double Current,
    double Remaining,
    double ProgressPercentage,
    bool IsCompleted);