using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Abstractions.Streaks;
using PaceUp.Application.DTOs.Streaks;

namespace PaceUp.Application.Features.Streaks;

public class StreakService : IStreakService
{
    private readonly IApplicationDbContext _dbContext;

    public StreakService(IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<StreakResponse> GetAsync(
        Guid userId,
        CancellationToken cancellationToken
    )
    {
        var activityDates = await _dbContext.Activities
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Select(x => x.StartedAt.Date)
            .Distinct()
            .OrderByDescending(x => x)
            .ToListAsync(cancellationToken);

        if (activityDates.Count == 0)
        {
            return new StreakResponse(
                0,
                0
            );
        }

        var currentStreak = CalculateCurrentStreak(
            activityDates
        );

        var longestStreak = CalculateLongestStreak(
            activityDates
        );

        return new StreakResponse(
            currentStreak,
            longestStreak
        );
    }

    private static int CalculateCurrentStreak(
        IReadOnlyList<DateTime> activityDates
    )
    {
        var today = DateTime.UtcNow.Date;

        var latestActivityDate = activityDates[0];

        if (latestActivityDate != today &&
            latestActivityDate != today.AddDays(-1))
        {
            return 0;
        }

        var streak = 1;

        for (var index = 1; index < activityDates.Count; index++)
        {
            var previousDate = activityDates[index - 1];
            var currentDate = activityDates[index];

            if (previousDate.AddDays(-1) != currentDate)
            {
                break;
            }

            streak++;
        }

        return streak;
    }

    private static int CalculateLongestStreak(
        IReadOnlyList<DateTime> activityDates
    )
    {
        if (activityDates.Count == 0)
        {
            return 0;
        }

        var longestStreak = 1;
        var currentStreak = 1;

        for (var index = 1; index < activityDates.Count; index++)
        {
            var previousDate = activityDates[index - 1];
            var currentDate = activityDates[index];

            if (previousDate.AddDays(-1) == currentDate)
            {
                currentStreak++;
                longestStreak = Math.Max(
                    longestStreak,
                    currentStreak
                );
            } else
            {
                currentStreak = 1;
            }
        }

        return longestStreak;
    }
}