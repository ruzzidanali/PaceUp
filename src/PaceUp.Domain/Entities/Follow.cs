namespace PaceUp.Domain.Entities;

public class Follow
{
    public Guid Id { get; private set; }

    public Guid FollowerId { get; private set; }

    public Guid FollowingId { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public User Follower { get; private set; } = null!;

    public User Following { get; private set; } = null!;

    private Follow()
    {
    }

    public Follow(
        Guid followerId,
        Guid followingId)
    {
        if (followerId == followingId)
        {
            throw new ArgumentException(
                "A user cannot follow themselves.");
        }

        Id = Guid.NewGuid();

        FollowerId = followerId;
        FollowingId = followingId;

        CreatedAt = DateTime.UtcNow;
    }
}