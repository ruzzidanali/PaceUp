using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Kudos;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Kudos;
using PaceUp.Domain.Constants;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Kudos;

public class KudosService : IKudosService
{
    private readonly IApplicationDbContext _dbContext;

    public KudosService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<KudosResponse> GetAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var activityExists =
            await _dbContext.Activities
                .AsNoTracking()
                .AnyAsync(
                    x => x.Id == activityId,
                    cancellationToken);

        if (!activityExists)
        {
            throw new KeyNotFoundException(
                "Activity not found.");
        }

        var kudosCount =
            await _dbContext.Kudos
                .AsNoTracking()
                .CountAsync(
                    x => x.ActivityId == activityId,
                    cancellationToken);

        var hasGivenKudos =
            await _dbContext.Kudos
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.ActivityId == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        return new KudosResponse(
            activityId,
            kudosCount,
            hasGivenKudos);
    }

    public async Task<KudosResponse> GiveAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var activity =
            await _dbContext.Activities
                .FirstOrDefaultAsync(
                    x => x.Id == activityId,
                    cancellationToken);

        if (activity is null)
        {
            throw new KeyNotFoundException(
                "Activity not found.");
        }

        if (activity.UserId == userId)
        {
            throw new InvalidOperationException(
                "You cannot give kudos to your own activity.");
        }

        var existingKudos =
            await _dbContext.Kudos
                .FirstOrDefaultAsync(
                    x =>
                        x.ActivityId == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        if (existingKudos is null)
        {
            var kudos =
                new Domain.Entities.Kudos(
                    activityId,
                    userId);

            _dbContext.Kudos.Add(kudos);

            var notification =
                new Notification(
                    activity.UserId,
                    userId,
                    NotificationTypes.ActivityKudos);

            _dbContext.Notifications.Add(
                notification);

            await _dbContext.SaveChangesAsync(
                cancellationToken);
        }

        return await GetAsync(
            userId,
            activityId,
            cancellationToken);
    }

    public async Task<KudosResponse> RemoveAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var activityExists =
            await _dbContext.Activities
                .AsNoTracking()
                .AnyAsync(
                    x => x.Id == activityId,
                    cancellationToken);

        if (!activityExists)
        {
            throw new KeyNotFoundException(
                "Activity not found.");
        }

        var kudos =
            await _dbContext.Kudos
                .FirstOrDefaultAsync(
                    x =>
                        x.ActivityId == activityId &&
                        x.UserId == userId,
                    cancellationToken);

        if (kudos is not null)
        {
            _dbContext.Kudos.Remove(kudos);

            await _dbContext.SaveChangesAsync(
                cancellationToken);
        }

        return await GetAsync(
            userId,
            activityId,
            cancellationToken);
    }
}