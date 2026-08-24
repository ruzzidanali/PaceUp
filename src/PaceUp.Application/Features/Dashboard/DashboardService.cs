using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Dashboard;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Dashboard;
using PaceUp.Domain.Constants;

namespace PaceUp.Application.Features.Dashboard;

public class DashboardService : IDashboardService
{
    private readonly IApplicationDbContext _dbContext;

    public DashboardService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<DashboardResponse> GetAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var activitiesQuery =
            _dbContext.Activities
                .AsNoTracking()
                .Where(x => x.UserId == userId);

        var totalActivities =
            await activitiesQuery.CountAsync(
                cancellationToken);

        var totalDistance =
            await activitiesQuery.SumAsync(
                x => x.Distance,
                cancellationToken);

        var totalDurationSeconds =
            await activitiesQuery.SumAsync(
                x => x.DurationSeconds,
                cancellationToken);

        var totalCalories =
            await activitiesQuery.SumAsync(
                x => x.Calories ?? 0,
                cancellationToken);

        var recentActivities =
            await activitiesQuery
                .OrderByDescending(x => x.StartedAt)
                .Take(5)
                .ToListAsync(cancellationToken);

        var now = DateTime.UtcNow;

        var activeGoals =
            await _dbContext.Goals
                .AsNoTracking()
                .Where(
                    x =>
                        x.UserId == userId &&
                        x.StartDate <= now &&
                        x.EndDate >= now)
                .OrderBy(x => x.EndDate)
                .ToListAsync(cancellationToken);

        var activeGoalIds =
            activeGoals
                .Select(x => x.Id)
                .ToList();

        var goalActivities = new List<Domain.Entities.Activity>();

        if (activeGoals.Count > 0)
        {
            var earliestGoalStart =
                activeGoals.Min(x => x.StartDate);

            var latestGoalEnd =
                activeGoals.Max(x => x.EndDate);

            goalActivities =
                await _dbContext.Activities
                    .AsNoTracking()
                    .Where(
                        x =>
                            x.UserId == userId &&
                            x.StartedAt >= earliestGoalStart &&
                            x.StartedAt <= latestGoalEnd)
                    .ToListAsync(cancellationToken);
        }

        var goals =
            activeGoals
                .Select(
                    goal =>
                    {
                        var activities =
                            goalActivities
                                .Where(
                                    x =>
                                        x.StartedAt >=
                                            goal.StartDate &&
                                        x.StartedAt <=
                                            goal.EndDate)
                                .ToList();

                        var current =
                            goal.Type switch
                            {
                                GoalTypes.Distance =>
                                    activities.Sum(
                                        x => x.Distance),

                                GoalTypes.Duration =>
                                    activities.Sum(
                                        x => x.DurationSeconds),

                                GoalTypes.Calories =>
                                    activities.Sum(
                                        x => x.Calories ?? 0),

                                GoalTypes.Activities =>
                                    activities.Count,

                                _ => 0
                            };

                        var remaining =
                            Math.Max(
                                goal.Target - current,
                                0);

                        var progressPercentage =
                            goal.Target <= 0
                                ? 0
                                : Math.Min(
                                    current /
                                    goal.Target *
                                    100,
                                    100);

                        return new DashboardGoalResponse(
                            goal.Id,
                            goal.Type,
                            goal.Target,
                            current,
                            remaining,
                            progressPercentage,
                            current >= goal.Target,
                            goal.StartDate,
                            goal.EndDate);
                    })
                .ToList();

        return new DashboardResponse(
            new DashboardActivitySummaryResponse(
                totalActivities,
                totalDistance,
                totalDurationSeconds,
                totalCalories),
            recentActivities
                .Select(
                    x =>
                        new ActivityResponse(
                            x.Id,
                            x.UserId,
                            x.Type,
                            x.Distance,
                            x.DurationSeconds,
                            x.Calories,
                            x.StartedAt,
                            x.CreatedAt))
                .ToList(),
            goals);
    }
}