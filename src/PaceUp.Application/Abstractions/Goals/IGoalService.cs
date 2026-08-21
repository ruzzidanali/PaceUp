using PaceUp.Application.DTOs.Goals;

namespace PaceUp.Application.Abstractions.Goals;

public interface IGoalService
{
    Task<GoalResponse> CreateAsync(
        Guid userId,
        CreateGoalRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<GoalResponse>> GetUserGoalsAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<GoalResponse?> GetByIdAsync(
        Guid userId,
        Guid goalId,
        CancellationToken cancellationToken);

    Task<GoalResponse?> UpdateAsync(
        Guid userId,
        Guid goalId,
        UpdateGoalRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        Guid userId,
        Guid goalId,
        CancellationToken cancellationToken);

    Task<GoalProgressResponse?> GetGoalProgressAsync(
        Guid userId,
        Guid goalId,
        CancellationToken cancellationToken
    );
}