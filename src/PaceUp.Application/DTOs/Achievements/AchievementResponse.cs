namespace PaceUp.Application.DTOs.Achievements;

public record AchievementResponse(
    Guid Id,
    string Code,
    string Name,
    string Description,
    string Icon,
    string RequirementType,
    double RequirementValue,
    DateTime? UnlockedAt
);