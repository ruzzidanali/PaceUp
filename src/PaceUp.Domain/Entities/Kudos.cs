namespace PaceUp.Domain.Entities;

public class Kudos
{
    public Guid Id { get; private set; }

    public Guid ActivityId { get; private set; }

    public Guid UserId { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public Activity Activity { get; private set; } = null!;

    public User User { get; private set; } = null!;

    private Kudos()
    {
    }

    public Kudos(
        Guid activityId,
        Guid userId)
    {
        Id = Guid.NewGuid();

        ActivityId = activityId;
        UserId = userId;

        CreatedAt = DateTime.UtcNow;
    }
}