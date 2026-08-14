using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Activities;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Activities;

public class ActivityService : IActivityService
{
    private readonly IApplicationDbContext _dbContext;

    public ActivityService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ActivityResponse> CreateAsync(
        Guid userId,
        CreateActivityRequest request,
        CancellationToken cancellationToken)
    {
        var activity = new Activity(
            userId,
            request.Type,
            request.Distance,
            request.DurationSeconds,
            request.Calories,
            request.StartedAt);

        _dbContext.Activities.Add(activity);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(activity);
    }

    public async Task<ActivityResponse?> GetByIdAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var activity =
            await _dbContext.Activities
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        return activity is null
            ? null
            : Map(activity);
    }

    public async Task<IReadOnlyList<ActivityResponse>>
        GetUserActivitiesAsync(
            Guid userId,
            CancellationToken cancellationToken)
    {
        var activities =
            await _dbContext.Activities
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.StartedAt)
                .ToListAsync(cancellationToken);

        return activities
            .Select(Map)
            .ToList();
    }

    public async Task<ActivityStatsResponse> GetStatsAsync(
    Guid userId,
    CancellationToken cancellationToken)
    {
        var stats =
            await _dbContext.Activities
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .GroupBy(_ => 1)
                .Select(group => new ActivityStatsResponse(
                    group.Count(),
                    group.Sum(x => x.Distance),
                    group.Sum(x => x.DurationSeconds),
                    group.Sum(x => x.Calories ?? 0)))
                .FirstOrDefaultAsync(
                    cancellationToken);

        return stats
            ?? new ActivityStatsResponse(
                0,
                0,
                0,
                0);
    }

    public async Task<ActivityResponse?> UpdateAsync(
    Guid userId,
    Guid activityId,
    UpdateActivityRequest request,
    CancellationToken cancellationToken)
    {
        var activity =
            await _dbContext.Activities
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        if (activity is null)
        {
            return null;
        }

        activity.Update(
            request.Type,
            request.Distance,
            request.DurationSeconds,
            request.Calories,
            request.StartedAt);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(activity);
    }

    public async Task<bool> DeleteAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var activity =
            await _dbContext.Activities
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        if (activity is null)
        {
            return false;
        }

        _dbContext.Activities.Remove(activity);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    private static ActivityResponse Map(
        Activity activity)
    {
        return new ActivityResponse(
            activity.Id,
            activity.UserId,
            activity.Type,
            activity.Distance,
            activity.DurationSeconds,
            activity.Calories,
            activity.StartedAt,
            activity.CreatedAt);
    }
}