namespace PaceUp.Domain.Entities;

public class Goal
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string Type { get; private set; } = null!;

    public double Target { get; private set; }

    public DateTime StartDate { get; private set; }

    public DateTime EndDate { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public DateTime UpdatedAt { get; private set; }

    public User User { get; private set; } = null!;

    private Goal()
    {
    }

    public Goal(
        Guid userId,
        string type,
        double target,
        DateTime startDate,
        DateTime endDate)
    {
        Id = Guid.NewGuid();

        UserId = userId;
        Type = type;
        Target = target;
        StartDate = startDate;
        EndDate = endDate;

        CreatedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Update(
        string type,
        double target,
        DateTime startDate,
        DateTime endDate)
    {
        Type = type;
        Target = target;
        StartDate = startDate;
        EndDate = endDate;
        UpdatedAt = DateTime.UtcNow;
    }
}