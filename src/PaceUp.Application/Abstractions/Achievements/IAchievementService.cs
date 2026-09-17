using PaceUp.Application.DTOs.Achievements;

namespace PaceUp.Application.Abstractions.Achievements;

public interface IAchievementService
{
    Task<IReadOnlyList<AchievementResponse>> GetAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AchievementResponse>> EvaluateAsync(
        Guid userId,
        CancellationToken cancellationToken);
}