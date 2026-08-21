namespace PaceUp.Domain.Entities;

public class EmailVerificationToken
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string Token { get; private set; } = null!;

    public DateTime ExpiresAt { get; private set; }

    public DateTime? UsedAt { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public User User { get; private set; } = null!;

    private EmailVerificationToken()
    {
    }

    public EmailVerificationToken(
        Guid userId,
        string token,
        DateTime expiresAt)
    {
        Id = Guid.NewGuid();

        UserId = userId;
        Token = token;
        ExpiresAt = expiresAt;
        CreatedAt = DateTime.UtcNow;
    }

    public bool IsExpired()
    {
        return DateTime.UtcNow >= ExpiresAt;
    }

    public bool IsUsed()
    {
        return UsedAt.HasValue;
    }

    public void MarkAsUsed()
    {
        UsedAt = DateTime.UtcNow;
    }

    public void Expire()
    {
        ExpiresAt = DateTime.UtcNow.AddSeconds(-1);
    }
}