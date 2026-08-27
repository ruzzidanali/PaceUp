using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Notifications;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Notifications;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Notifications;

public class NotificationService : INotificationService
{
    private readonly IApplicationDbContext _dbContext;

    public NotificationService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task CreateAsync(
    Guid recipientUserId,
    Guid actorUserId,
    string type,
    CancellationToken cancellationToken)
    {
        var notification =
            new Notification(
                recipientUserId,
                actorUserId,
                type);

        _dbContext.Notifications.Add(
            notification);

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

    public async Task<IReadOnlyList<NotificationResponse>> GetAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var notifications =
            await _dbContext.Notifications
                .AsNoTracking()
                .Where(x => x.RecipientUserId == userId)
                .Include(x => x.ActorUser)
                .OrderByDescending(x => x.CreatedAt)
                .Select(
                    x =>
                        new NotificationResponse(
                            x.Id,
                            x.Type,
                            x.IsRead,
                            x.ActorUserId,
                            x.ActorUser.Username,
                            x.ActorUser.DisplayName,
                            x.ActorUser.ProfileImageUrl,
                            x.CreatedAt))
                .ToListAsync(cancellationToken);

        return notifications;
    }

    public async Task<bool> MarkAsReadAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken)
    {
        var notification =
            await _dbContext.Notifications
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == notificationId &&
                        x.RecipientUserId == userId,
                    cancellationToken);

        if (notification is null)
        {
            return false;
        }

        notification.MarkAsRead();

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    public async Task MarkAllAsReadAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var notifications =
            await _dbContext.Notifications
                .Where(
                    x =>
                        x.RecipientUserId == userId &&
                        !x.IsRead)
                .ToListAsync(cancellationToken);

        foreach (var notification in notifications)
        {
            notification.MarkAsRead();
        }

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }
}