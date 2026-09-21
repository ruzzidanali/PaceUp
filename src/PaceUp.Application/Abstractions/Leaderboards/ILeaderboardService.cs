using PaceUp.Application.DTOs.Leaderboards;

namespace PaceUp.Application.Abstractions.Leaderboards;

public interface ILeaderboardService
{
    Task<IReadOnlyList<LeaderboardEntryResponse>> GetAsync(
        Guid userId,
        string period,
        int limit,
        CancellationToken cancellationToken);
}