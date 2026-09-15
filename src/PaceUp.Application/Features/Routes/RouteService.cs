using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Abstractions.Routes;
using PaceUp.Application.DTOs.Routes;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Routes;

public class RouteService : IRouteService
{
    private readonly IApplicationDbContext _dbContext;

    public RouteService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<RouteResponse?> GetByActivityIdAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var activityExists =
            await _dbContext.Activities
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        if (!activityExists)
        {
            return null;
        }

        var points =
            await _dbContext.ActivityPoints
                .AsNoTracking()
                .Where(
                    x => x.ActivityId == activityId)
                .OrderBy(x => x.RecordedAt)
                .Select(
                    x => new ActivityPointResponse(
                        x.Id,
                        x.ActivityId,
                        x.Latitude,
                        x.Longitude,
                        x.Altitude,
                        x.Accuracy,
                        x.Speed,
                        x.HeartRate,
                        x.RecordedAt))
                .ToListAsync(cancellationToken);

        return new RouteResponse(
            activityId,
            points);
    }

    public async Task<RouteResponse> CreateAsync(
    Guid userId,
    Guid activityId,
    CreateActivityRouteRequest request,
    CancellationToken cancellationToken)
    {
        var activityExists =
            await _dbContext.Activities
                .AsNoTracking()
                .AnyAsync(
                    x => x.Id == activityId && x.UserId == userId,
                    cancellationToken);

        if (!activityExists)
            throw new KeyNotFoundException("Activity not found.");

        var points =
            request.Points
                .Select(
                    x => new ActivityPoint(
                        activityId,
                        x.Latitude,
                        x.Longitude,
                        x.Altitude,
                        x.Accuracy,
                        x.Speed,
                        x.HeartRate,
                        x.RecordedAt))
                .ToList();

        if (points.Count > 0)
        {
            _dbContext.ActivityPoints.AddRange(points);

            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return new RouteResponse(
            activityId,
            points
                .OrderBy(x => x.RecordedAt)
                .Select(
                    x => new ActivityPointResponse(
                        x.Id,
                        x.ActivityId,
                        x.Latitude,
                        x.Longitude,
                        x.Altitude,
                        x.Accuracy,
                        x.Speed,
                        x.HeartRate,
                        x.RecordedAt))
                .ToList());
    }
}
