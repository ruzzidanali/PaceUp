using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Challenges;

public class ChallengeParticipantTests
{
    [Fact]
    public void Constructor_ShouldCreateParticipant()
    {
        var challengeId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var participant =
            new ChallengeParticipant(
                challengeId,
                userId);

        Assert.NotEqual(
            Guid.Empty,
            participant.Id);

        Assert.Equal(
            challengeId,
            participant.ChallengeId);

        Assert.Equal(
            userId,
            participant.UserId);

        Assert.NotEqual(
            default,
            participant.JoinedAt);
    }
}