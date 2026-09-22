namespace PaceUp.Application.Abstractions.Xp;

public interface IXpService
{
    Task AwardActivityXpAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken
    );

    Task AwardChallengeXpAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken
    );
}