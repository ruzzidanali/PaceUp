using PaceUp.Application.DTOs.Challenges;

namespace PaceUp.Application.Abstractions.Challenges;

public interface IChallengeService
{
    Task<ChallengeResponse> CreateAsync(
        Guid userId,
        CreateChallengeRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<ChallengeResponse>> GetAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<ChallengeResponse?> GetByIdAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken);

    Task<ChallengeResponse?> UpdateAsync(
        Guid userId,
        Guid challengeId,
        UpdateChallengeRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken);

    Task<bool> JoinAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken);

    Task<bool> LeaveAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken);

    Task<ChallengeProgressResponse?> GetProgressAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken);

    Task<ChallengeLeaderboardResponse?> GetLeaderboardAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken);
}