using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Abstractions.PersonalRecords;
using PaceUp.Application.DTOs.PersonalRecords;
using PaceUp.Application.Features.Activities;

namespace PaceUp.Application.Features.PersonalRecords;

public class PersonalRecordService : IPersonalRecordService
{
    private readonly IApplicationDbContext _dbContext;

    public PersonalRecordService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<PersonalRecordResponse> GetAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var activities = await _dbContext.Activities
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .ToListAsync(cancellationToken);

        if (activities.Count == 0)
        {
            return new PersonalRecordResponse(
                LongestDistanceKm: null,
                LongestDurationSeconds: null,
                FastestSpeedKmh: null,
                FastestPaceSecondsPerKm: null,
                MostCalories: null);
        }

        var longestDistanceKm =
            activities.Max(x => x.Distance);

        var longestDurationSeconds =
            activities.Max(x => x.DurationSeconds);

        var mostCalories =
            activities
                .Where(x => x.Calories.HasValue)
                .Select(x => x.Calories!.Value)
                .DefaultIfEmpty()
                .Max();

        var fastestPaceSecondsPerKm =
            activities
                .Where(x =>
                    x.Distance > 0 &&
                    x.DurationSeconds > 0)
                .Select(x =>
                    ActivityPerformanceCalculator
                        .CalculateAveragePaceSecondsPerKm(
                            x.Distance,
                            x.DurationSeconds))
                .Where(x => x.HasValue)
                .Select(x => x!.Value)
                .DefaultIfEmpty()
                .Min();

        var activityIds =
            activities
                .Select(x => x.Id)
                .ToHashSet();

        var speeds =
            await _dbContext.ActivityPoints
                .AsNoTracking()
                .Where(x =>
                    activityIds.Contains(x.ActivityId) &&
                    x.Speed.HasValue &&
                    x.Speed.Value > 0)
                .Select(x => x.Speed!.Value)
                .ToListAsync(cancellationToken);

        double? fastestSpeedMetersPerSecond =
            speeds.Count == 0
                ? null
                : speeds.Max();

        var fastestSpeedKmh =
            ActivityPerformanceCalculator
                .CalculateBestSpeedKmh(
                    fastestSpeedMetersPerSecond);

        return new PersonalRecordResponse(
            LongestDistanceKm: longestDistanceKm,
            LongestDurationSeconds: longestDurationSeconds,
            FastestSpeedKmh: fastestSpeedKmh,
            FastestPaceSecondsPerKm: fastestPaceSecondsPerKm,
            MostCalories:
                activities.Any(x => x.Calories.HasValue)
                    ? mostCalories
                    : null);
    }
}