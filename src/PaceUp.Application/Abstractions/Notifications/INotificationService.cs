using PaceUp.Application.DTOs.Notifications;

namespace PaceUp.Application.Abstractions.Notifications;

public interface INotificationService
{
    Task<IReadOnlyList<NotificationResponse>> GetAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<bool> MarkAsReadAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken);

    Task MarkAllAsReadAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task CreateAsync(
        Guid recipientUserId,
        Guid actorUserId,
        string type,
        Guid? targetId,
        CancellationToken cancellationToken);
}