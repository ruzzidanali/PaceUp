using PaceUp.Domain.Constants;

namespace PaceUp.Domain.Entities;

public class Notification
{
    public Guid Id { get; private set; }

    public Guid RecipientUserId { get; private set; }

    public Guid ActorUserId { get; private set; }

    public string Type { get; private set; } = null!;

    public bool IsRead { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public User RecipientUser { get; private set; } = null!;

    public User ActorUser { get; private set; } = null!;

    public Guid? TargetId { get; private set; }

    private Notification()
    {
    }

    public Notification(
    Guid recipientUserId,
    Guid actorUserId,
    string type,
    Guid? targetId = null)
    {
        if (!NotificationTypes.IsValid(type))
        {
            throw new ArgumentException(
                $"Unsupported notification type: {type}",
                nameof(type));
        }

        if (recipientUserId == actorUserId)
        {
            throw new ArgumentException(
                "A user cannot receive a notification from themselves.",
                nameof(actorUserId));
        }

        Id = Guid.NewGuid();

        RecipientUserId = recipientUserId;
        ActorUserId = actorUserId;
        Type = type;
        TargetId = targetId;

        IsRead = false;
        CreatedAt = DateTime.UtcNow;
    }

    public void MarkAsRead()
    {
        IsRead = true;
    }
}