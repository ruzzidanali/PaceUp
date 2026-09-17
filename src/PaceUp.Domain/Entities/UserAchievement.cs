namespace PaceUp.Domain.Entities;

public class UserAchievement
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public Guid AchievementId { get; private set; }

    public DateTime UnlockedAt { get; private set; }

    public User User { get; private set; } = null!;

    public Achievement Achievement { get; private set; } = null!;

    private UserAchievement()
    {
    }

    public UserAchievement(
        Guid userId,
        Guid achievementId)
    {
        Id = Guid.NewGuid();

        UserId = userId;
        AchievementId = achievementId;
        UnlockedAt = DateTime.UtcNow;
    }
}