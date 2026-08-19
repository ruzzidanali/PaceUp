namespace PaceUp.Application.DTOs.Goals;

public record CreateGoalRequest(
    string Type,
    double Target,
    DateTime StartDate,
    DateTime EndDate);