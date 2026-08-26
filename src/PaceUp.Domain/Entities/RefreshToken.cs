namespace PaceUp.Domain.Entities;

public class RefreshToken
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string TokenHash { get; private set; } = null!;

    public DateTime ExpiresAt { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public DateTime? RevokedAt { get; private set; }

    public Guid? ReplacedByTokenId { get; private set; }

    public User User { get; private set; } = null!;

    private RefreshToken()
    {
    }

    public RefreshToken(
        Guid userId,
        string tokenHash,
        DateTime expiresAt)
    {
        Id = Guid.NewGuid();

        UserId = userId;
        TokenHash = tokenHash;
        ExpiresAt = expiresAt;
        CreatedAt = DateTime.UtcNow;
    }

    public bool IsExpired()
    {
        return DateTime.UtcNow >= ExpiresAt;
    }

    public bool IsRevoked()
    {
        return RevokedAt.HasValue;
    }

    public bool IsActive()
    {
        return !IsExpired() &&
               !IsRevoked();
    }

    public void Revoke()
    {
        if (RevokedAt.HasValue)
        {
            return;
        }

        RevokedAt = DateTime.UtcNow;
    }

    public void ReplaceWith(Guid replacementTokenId)
    {
        Revoke();

        ReplacedByTokenId = replacementTokenId;
    }
}