namespace PaceUp.Domain.Entities;

public class UserIdentity
{
    public Guid UserId { get; private set; }

    public string PasswordHash { get; private set; } = null!;

    public bool EmailVerified { get; private set; }

    public string SecurityStamp { get; private set; } = null!;

    public DateTime CreatedAt { get; private set; }

    public DateTime? UpdatedAt { get; private set; }

    public User User { get; private set; } = null!;

    private UserIdentity()
    {
    }

    public UserIdentity(
        Guid userId,
        string passwordHash)
    {
        UserId = userId;
        PasswordHash = passwordHash;
        EmailVerified = false;
        SecurityStamp = Guid.NewGuid().ToString("N");
        CreatedAt = DateTime.UtcNow;
    }

    public void UpdatePassword(string passwordHash)
    {
        PasswordHash = passwordHash;
        SecurityStamp = Guid.NewGuid().ToString("N");
        UpdatedAt = DateTime.UtcNow;
    }

    public void VerifyEmail()
    {
        EmailVerified = true;
        UpdatedAt = DateTime.UtcNow;
    }
}