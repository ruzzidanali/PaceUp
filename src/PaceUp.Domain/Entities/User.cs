namespace PaceUp.Domain.Entities;

public class User
{
    public Guid Id { get; private set; }
    public string Username { get; private set; } = null!;
    public string Email { get; private set; } = null!;
    public string DisplayName { get; private set; } = null!;
    public string? Bio { get; private set; }
    public string? ProfileImageUrl { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public UserIdentity? Identity { get; private set; }
    private User()
    {
    }

    public User(
        string username,
        string email,
        string displayName)
    {
        Id = Guid.NewGuid();

        Username = username;
        Email = email;
        DisplayName = displayName;

        CreatedAt = DateTime.UtcNow;
    }

    public void UpdateProfile(
        string displayName,
        string? bio)
    {
        DisplayName = displayName;
        Bio = bio;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdateProfileImage(string? profileImageUrl)
    {
        ProfileImageUrl = profileImageUrl;
        UpdatedAt = DateTime.UtcNow;
    }
}