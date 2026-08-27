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

    public async Task<PagedActivityResponse> GetUserActivitiesAsync(
    Guid userId,
    ActivityListRequest request,
    CancellationToken cancellationToken)
    {
        var page =
            Math.Max(request.Page, 1);

        var pageSize =
            Math.Clamp(request.PageSize, 1, 100);

        var query =
            _dbContext.Activities
                .AsNoTracking()
                .Where(x => x.UserId == userId);

        if (!string.IsNullOrWhiteSpace(request.Type))
        {
            query = query.Where(
                x => x.Type == request.Type);
        }

        if (request.From.HasValue)
        {
            query = query.Where(
                x => x.StartedAt >= request.From.Value);
        }

        if (request.To.HasValue)
        {
            query = query.Where(
                x => x.StartedAt <= request.To.Value);
        }

        var totalCount =
            await query.CountAsync(
                cancellationToken);

        var activities =
            await query
                .OrderByDescending(x => x.StartedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

        var totalPages =
            totalCount == 0
                ? 0
                : (int)Math.Ceiling(
                    totalCount / (double)pageSize);

        return new PagedActivityResponse(
            activities.Select(Map).ToList(),
            page,
            pageSize,
            totalCount,
            totalPages);
    }

    public async Task<ActivityStatsResponse> GetStatsAsync(
    Guid userId,
    ActivityListRequest request,
    CancellationToken cancellationToken)
    {
        var query =
            _dbContext.Activities
                .AsNoTracking()
                .Where(x => x.UserId == userId);

        if (!string.IsNullOrWhiteSpace(request.Type))
        {
            query = query.Where(
                x => x.Type == request.Type);
        }

        if (request.From.HasValue)
        {
            query = query.Where(
                x => x.StartedAt >= request.From.Value);
        }

        if (request.To.HasValue)
        {
            query = query.Where(
                x => x.StartedAt <= request.To.Value);
        }

        var totalActivities =
            await query.CountAsync(
                cancellationToken);

        var totalDistance =
            await query.SumAsync(
                x => x.Distance,
                cancellationToken);

        var totalDurationSeconds =
            await query.SumAsync(
                x => x.DurationSeconds,
                cancellationToken);

        var totalCalories =
            await query
                .SumAsync(
                    x => x.Calories ?? 0,
                    cancellationToken);

        var activitiesByType =
            await query
                .GroupBy(x => x.Type)
                .Select(x => new
                {
                    Type = x.Key,
                    Count = x.Count()
                })
                .ToDictionaryAsync(
                    x => x.Type,
                    x => x.Count,
                    cancellationToken);

        return new ActivityStatsResponse(
            TotalActivities: totalActivities,
            TotalDistance: totalDistance,
            TotalDurationSeconds: totalDurationSeconds,
            TotalCalories: totalCalories,
            ActivitiesByType: activitiesByType);
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

    public async Task<ActivityTrendResponse> GetTrendsAsync(
    Guid userId,
    ActivityTrendRequest request,
    CancellationToken cancellationToken)
    {
        var query =
            _dbContext.Activities
                .AsNoTracking()
                .Where(x => x.UserId == userId);

        if (request.From.HasValue)
        {
            query = query.Where(
                x => x.StartedAt >= request.From.Value);
        }

        if (request.To.HasValue)
        {
            query = query.Where(
                x => x.StartedAt <= request.To.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.Type))
        {
            query = query.Where(
                x => x.Type == request.Type);
        }

        var activities =
            await query
                .OrderBy(x => x.StartedAt)
                .ToListAsync(cancellationToken);

        var items =
            request.GroupBy.ToLowerInvariant() switch
            {
                "day" =>
                    activities
                        .GroupBy(x => x.StartedAt.Date)
                        .Select(MapTrendItem)
                        .ToList(),

                "week" =>
                    activities
                        .GroupBy(GetStartOfWeek)
                        .Select(MapTrendItem)
                        .ToList(),

                "month" =>
                    activities
                        .GroupBy(
                            x => new DateTime(
                                x.StartedAt.Year,
                                x.StartedAt.Month,
                                1))
                        .Select(MapTrendItem)
                        .ToList(),

                _ =>
                    throw new ArgumentException(
                        "GroupBy must be day, week, or month.",
                        nameof(request.GroupBy))
            };

        return new ActivityTrendResponse(
            request.From,
            request.To,
            request.Type,
            request.GroupBy.ToLowerInvariant(),
            items);
    }

    private static DateTime GetStartOfWeek(
        Activity activity)
    {
        var date = activity.StartedAt.Date;

        var daysSinceMonday =
            ((int)date.DayOfWeek + 6) % 7;

        return date.AddDays(-daysSinceMonday);
    }

    private static ActivityTrendItemResponse MapTrendItem(
        IGrouping<DateTime, Activity> group)
    {
        return new ActivityTrendItemResponse(
            group.Key,
            group.Count(),
            group.Sum(x => x.Distance),
            group.Sum(x => x.DurationSeconds),
            group.Sum(x => x.Calories ?? 0));
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