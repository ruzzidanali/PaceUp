using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Leaderboards;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Leaderboards;

namespace PaceUp.Application.Features.Leaderboards;

public class LeaderboardService : ILeaderboardService
{
    private readonly IApplicationDbContext _dbContext;

    public LeaderboardService(IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyList<LeaderboardEntryResponse>> GetAsync(
        Guid userId,
        string period,
        int limit,
        CancellationToken cancellationToken)
    {
        if (limit <= 0)
        {
            throw new ArgumentException(
                "Leaderboard limit must be greater than zero.",
                nameof(limit));
        }

        var normalizedPeriod =
            period.Trim().ToLowerInvariant();

        var today = DateTime.UtcNow.Date;

        var startDate = normalizedPeriod switch
        {
            "weekly" => GetStartOfWeek(today),

            "monthly" => new DateTime(
                today.Year,
                today.Month,
                1,
                0,
                0,
                0,
                DateTimeKind.Utc),

            "all-time" => DateTime.MinValue,

            _ => throw new ArgumentException(
                "Invalid leaderboard period.",
                nameof(period))
        };

        var query = _dbContext.Activities
            .AsNoTracking()
            .Where(x => x.StartedAt >= startDate);

        var leaderboard = await query
            .GroupBy(x => x.UserId)
            .Select(group => new
            {
                UserId = group.Key,
                DistanceKm = group.Sum(x => x.Distance)
            })
            .OrderByDescending(x => x.DistanceKm)
            .ThenBy(x => x.UserId)
            .Take(limit)
            .Join(
                _dbContext.Users.AsNoTracking(),
                entry => entry.UserId,
                user => user.Id,
                (entry, user) => new
                {
                    entry.UserId,
                    entry.DistanceKm,
                    user.Username,
                    user.DisplayName,
                    user.ProfileImageUrl
                })
            .ToListAsync(cancellationToken);

        var rankedLeaderboard =
            new List<LeaderboardEntryResponse>();

        var previousDistance = double.NaN;
        var previousRank = 0;

        for (var index = 0;
             index < leaderboard.Count;
             index++)
        {
            var entry = leaderboard[index];

            var rank =
                index == 0 ||
                entry.DistanceKm != previousDistance
                    ? index + 1
                    : previousRank;

            rankedLeaderboard.Add(
                new LeaderboardEntryResponse(
                    Rank: rank,
                    UserId: entry.UserId,
                    Username: entry.Username,
                    DisplayName: entry.DisplayName,
                    ProfileImageUrl: entry.ProfileImageUrl,
                    DistanceKm: entry.DistanceKm,
                    IsCurrentUser:
                        entry.UserId == userId));

            previousDistance = entry.DistanceKm;
            previousRank = rank;
        }

        return rankedLeaderboard;
    }

    private static DateTime GetStartOfWeek(
        DateTime date)
    {
        var daysSinceMonday =
            ((int)date.DayOfWeek + 6) % 7;

        return date.AddDays(-daysSinceMonday);
    }
}