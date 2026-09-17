using PaceUp.Application.DTOs.Streaks;

namespace PaceUp.Application.Abstractions.Streaks;

public interface IStreakService
{
    Task<StreakResponse> GetAsync(
        Guid userId,
        CancellationToken cancellationToken
    );
}