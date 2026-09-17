using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Achievements;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Achievements;
using PaceUp.Domain.Entities;
using PaceUp.Application.Abstractions.Notifications;

namespace PaceUp.Application.Features.Achievements;

public class AchievementService : IAchievementService
{
    private readonly IApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public AchievementService(
    IApplicationDbContext dbContext,
    INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<IReadOnlyList<AchievementResponse>> GetAsync(
    Guid userId,
    CancellationToken cancellationToken)
    {
        var achievements = await _dbContext.Achievements
            .AsNoTracking()
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        if (achievements.Count == 0)
        {
            return [];
        }

        var unlockedAchievements = await _dbContext.UserAchievements
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .ToDictionaryAsync(
                x => x.AchievementId,
                x => x.UnlockedAt,
                cancellationToken);

        var activityCount = await _dbContext.Activities
            .CountAsync(
                x => x.UserId == userId,
                cancellationToken);

        var totalDistance = await _dbContext.Activities
            .Where(x => x.UserId == userId)
            .SumAsync(
                x => x.Distance,
                cancellationToken);

        var longestActivityDurationSeconds = await _dbContext.Activities
            .Where(x => x.UserId == userId)
            .Select(x => (int?)x.DurationSeconds)
            .MaxAsync(cancellationToken) ?? 0;

        return achievements
            .Select(achievement =>
            {
                var currentProgress = achievement.RequirementType switch
                {
                    "ACTIVITY_COUNT" =>
                        activityCount,

                    "TOTAL_DISTANCE_KM" =>
                        totalDistance,

                    "ACTIVITY_DURATION_MINUTES" =>
                        longestActivityDurationSeconds / 60.0,

                    _ => 0
                };

                return new AchievementResponse(
                    achievement.Id,
                    achievement.Code,
                    achievement.Name,
                    achievement.Description,
                    achievement.Icon,
                    achievement.RequirementType,
                    achievement.RequirementValue,
                    currentProgress,
                    unlockedAchievements.TryGetValue(
                        achievement.Id,
                        out var unlockedAt)
                        ? unlockedAt
                        : null);
            })
            .ToList();
    }

    public async Task<IReadOnlyList<AchievementResponse>> EvaluateAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var achievements = await _dbContext.Achievements
            .AsNoTracking()
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        if (achievements.Count == 0)
        {
            return [];
        }

        var unlockedAchievementIds = await _dbContext.UserAchievements
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Select(x => x.AchievementId)
            .ToHashSetAsync(cancellationToken);

        var activityCount = await _dbContext.Activities
            .CountAsync(
                x => x.UserId == userId,
                cancellationToken);

        var totalDistance = await _dbContext.Activities
            .Where(x => x.UserId == userId)
            .SumAsync(
                x => x.Distance,
                cancellationToken);

        var hasSixtyMinuteActivity = await _dbContext.Activities
            .AnyAsync(
                x => x.UserId == userId &&
                     x.DurationSeconds >= 60 * 60,
                cancellationToken);

        var newlyUnlocked = new List<(Achievement Achievement, UserAchievement UserAchievement)>();

        foreach (var achievement in achievements)
        {
            if (unlockedAchievementIds.Contains(achievement.Id))
            {
                continue;
            }

            var isQualified = achievement.RequirementType switch
            {
                "ACTIVITY_COUNT" =>
                    activityCount >= achievement.RequirementValue,

                "TOTAL_DISTANCE_KM" =>
                    totalDistance >= achievement.RequirementValue,

                "ACTIVITY_DURATION_MINUTES" =>
                    hasSixtyMinuteActivity &&
                    achievement.RequirementValue <= 60,

                _ => false
            };

            if (!isQualified)
            {
                continue;
            }

            var userAchievement = new UserAchievement(
                userId,
                achievement.Id);

            _dbContext.UserAchievements.Add(userAchievement);

            newlyUnlocked.Add(
                (achievement, userAchievement));
        }

        if (newlyUnlocked.Count == 0)
        {
            return [];
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        foreach (var unlocked in newlyUnlocked)
        {
            await _notificationService.CreateAsync(
                userId,
                null,
                "AchievementUnlocked",
                unlocked.Achievement.Id,
                cancellationToken);
        }

        return newlyUnlocked
    .Select(x => new AchievementResponse(
        x.Achievement.Id,
        x.Achievement.Code,
        x.Achievement.Name,
        x.Achievement.Description,
        x.Achievement.Icon,
        x.Achievement.RequirementType,
        x.Achievement.RequirementValue,
        x.Achievement.RequirementType switch
        {
            "ACTIVITY_COUNT" => activityCount,
            "TOTAL_DISTANCE_KM" => totalDistance,
            "ACTIVITY_DURATION_MINUTES" =>
                hasSixtyMinuteActivity
                    ? 60
                    : 0,
            _ => 0
        },
        x.UserAchievement.UnlockedAt))
    .ToList();
    }
}