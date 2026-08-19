namespace PaceUp.Application.DTOs.Goals;

public record UpdateGoalRequest(
    string Type,
    double Target,
    DateTime StartDate,
    DateTime EndDate);