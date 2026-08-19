using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Goals;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Goals;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Goals;

public class GoalService : IGoalService
{
    private readonly IApplicationDbContext _dbContext;

    public GoalService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<GoalResponse> CreateAsync(
        Guid userId,
        CreateGoalRequest request,
        CancellationToken cancellationToken)
    {
        var goal = new Goal(
            userId,
            request.Type,
            request.Target,
            request.StartDate,
            request.EndDate);

        _dbContext.Goals.Add(goal);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(goal);
    }

    public async Task<IReadOnlyList<GoalResponse>> GetUserGoalsAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var goals =
            await _dbContext.Goals
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.StartDate)
                .ToListAsync(cancellationToken);

        return goals
            .Select(Map)
            .ToList();
    }

    public async Task<GoalResponse?> GetByIdAsync(
        Guid userId,
        Guid goalId,
        CancellationToken cancellationToken)
    {
        var goal =
            await _dbContext.Goals
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == goalId &&
                        x.UserId == userId,
                    cancellationToken);

        return goal is null
            ? null
            : Map(goal);
    }

    public async Task<GoalResponse?> UpdateAsync(
        Guid userId,
        Guid goalId,
        UpdateGoalRequest request,
        CancellationToken cancellationToken)
    {
        var goal =
            await _dbContext.Goals
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == goalId &&
                        x.UserId == userId,
                    cancellationToken);

        if (goal is null)
        {
            return null;
        }

        goal.Update(
            request.Type,
            request.Target,
            request.StartDate,
            request.EndDate);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(goal);
    }

    public async Task<bool> DeleteAsync(
        Guid userId,
        Guid goalId,
        CancellationToken cancellationToken)
    {
        var goal =
            await _dbContext.Goals
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == goalId &&
                        x.UserId == userId,
                    cancellationToken);

        if (goal is null)
        {
            return false;
        }

        _dbContext.Goals.Remove(goal);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    private static GoalResponse Map(Goal goal)
    {
        return new GoalResponse(
            goal.Id,
            goal.UserId,
            goal.Type,
            goal.Target,
            goal.StartDate,
            goal.EndDate,
            goal.CreatedAt,
            goal.UpdatedAt);
    }
}