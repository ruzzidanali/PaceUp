namespace PaceUp.Domain.Entities;

public class Activity
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string Type { get; private set; } = null!;

    public double Distance { get; private set; }

    public int DurationSeconds { get; private set; }

    public int? Calories { get; private set; }

    public DateTime StartedAt { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public User User { get; private set; } = null!;

    private Activity()
    {
    }

    public Activity(
        Guid userId,
        string type,
        double distance,
        int durationSeconds,
        int? calories,
        DateTime startedAt)
    {
        Id = Guid.NewGuid();

        UserId = userId;
        Type = type;
        Distance = distance;
        DurationSeconds = durationSeconds;
        Calories = calories;
        StartedAt = startedAt;

        CreatedAt = DateTime.UtcNow;
    }

    public void Update(
    string type,
    double distance,
    int durationSeconds,
    int? calories,
    DateTime startedAt)
    {
        Type = type;
        Distance = distance;
        DurationSeconds = durationSeconds;
        Calories = calories;
        StartedAt = startedAt;
    }
}