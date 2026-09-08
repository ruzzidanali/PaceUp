namespace PaceUp.Domain.Entities;

public class Comment
{
    public Guid Id { get; private set; }
    public Guid ActivityId { get; private set; }
    public Guid UserId { get; private set; }
    public string Content { get; private set; } = null!;
    public DateTime CreatedAt { get; private set; }
    public Activity Activity { get; private set; } = null!;
    public User User { get; private set; } = null!;

    private Comment() { }

    public Comment(Guid activityId, Guid userId, string content)
    {
        if (activityId == Guid.Empty) throw new ArgumentException("Activity is required.", nameof(activityId));
        if (userId == Guid.Empty) throw new ArgumentException("User is required.", nameof(userId));
        if (string.IsNullOrWhiteSpace(content)) throw new ArgumentException("Comment cannot be empty.", nameof(content));
        content = content.Trim();
        if (content.Length > 1000) throw new ArgumentException("Comment cannot exceed 1000 characters.", nameof(content));
        Id = Guid.NewGuid(); ActivityId = activityId; UserId = userId; Content = content; CreatedAt = DateTime.UtcNow;
    }
}