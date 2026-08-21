using PaceUp.Domain.Constants;

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
        if (!ActivityTypes.IsValid(type))
        {
            throw new ArgumentException(
                $"Unsupported activity type: {type}",
                nameof(type));
        }

        if (!double.IsFinite(distance))
        {
            throw new ArgumentException(
                "Distance must be a finite number.",
                nameof(distance));
        }

        if (distance < 0)
        {
            throw new ArgumentException(
                "Distance cannot be negative.",
                nameof(distance));
        }

        if (durationSeconds <= 0)
        {
            throw new ArgumentException(
                "Duration must be greater than zero.",
                nameof(durationSeconds));
        }

        if (calories < 0)
        {
            throw new ArgumentException(
                "Calories cannot be negative.",
                nameof(calories));
        }

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
        if (!ActivityTypes.IsValid(type))
        {
            throw new ArgumentException(
                $"Unsupported activity type: {type}",
                nameof(type));
        }

        if (!double.IsFinite(distance))
        {
            throw new ArgumentException(
                "Distance must be a finite number.",
                nameof(distance));
        }

        if (distance < 0)
        {
            throw new ArgumentException(
                "Distance cannot be negative.",
                nameof(distance));
        }

        if (durationSeconds <= 0)
        {
            throw new ArgumentException(
                "Duration must be greater than zero.",
                nameof(durationSeconds));
        }

        if (calories < 0)
        {
            throw new ArgumentException(
                "Calories cannot be negative.",
                nameof(calories));
        }

        Type = type;
        Distance = distance;
        DurationSeconds = durationSeconds;
        Calories = calories;
        StartedAt = startedAt;
    }
}