namespace PaceUp.Domain.Entities;

public class ChallengeParticipant
{
    public Guid Id { get; private set; }

    public Guid ChallengeId { get; private set; }

    public Guid UserId { get; private set; }

    public DateTime JoinedAt { get; private set; }

    public Challenge Challenge { get; private set; } = null!;

    public User User { get; private set; } = null!;

    private ChallengeParticipant()
    {
    }

    public ChallengeParticipant(
        Guid challengeId,
        Guid userId)
    {
        Id = Guid.NewGuid();

        ChallengeId = challengeId;
        UserId = userId;

        JoinedAt = DateTime.UtcNow;
    }
}