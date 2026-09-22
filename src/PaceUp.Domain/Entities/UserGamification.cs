namespace PaceUp.Domain.Entities;

public class UserGamification
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public int TotalXp { get; private set; }

    public int Level { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public DateTime UpdatedAt { get; private set; }

    public User User { get; private set; } = null!;

    private UserGamification()
    {
    }

    public UserGamification(Guid userId)
    {
        Id = Guid.NewGuid();

        UserId = userId;

        TotalXp = 0;
        Level = 1;

        CreatedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void AddXp(int amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentException(
                "XP amount must be greater than zero.",
                nameof(amount));
        }

        TotalXp += amount;

        Level = CalculateLevel(TotalXp);

        UpdatedAt = DateTime.UtcNow;
    }

    private static int CalculateLevel(int totalXp)
    {
        return (totalXp / 100) + 1;
    }
}