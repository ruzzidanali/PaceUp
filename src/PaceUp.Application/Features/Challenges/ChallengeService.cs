using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Challenges;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Challenges;
using PaceUp.Application.Exceptions;
using PaceUp.Domain.Constants;
using PaceUp.Domain.Entities;
using PaceUp.Application.Abstractions.Notifications;

namespace PaceUp.Application.Features.Challenges;

public class ChallengeService : IChallengeService
{
    private readonly IApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public ChallengeService(
        IApplicationDbContext dbContext,
        INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<ChallengeResponse> CreateAsync(
        Guid userId,
        CreateChallengeRequest request,
        CancellationToken cancellationToken)
    {
        var challenge =
            new Challenge(
                userId,
                request.Name,
                request.Description,
                request.Type,
                request.TargetValue,
                request.StartDate,
                request.EndDate);

        _dbContext.Challenges.Add(challenge);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(
            challenge,
            0);
    }

    public async Task<IReadOnlyList<ChallengeResponse>> GetAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var challenges =
            await _dbContext.Challenges
                .AsNoTracking()
                .Select(
                    x =>
                        new
                        {
                            Challenge = x,
                            ParticipantCount =
                                x.Participants.Count()
                        })
                .OrderByDescending(
                    x => x.Challenge.CreatedAt)
                .ToListAsync(
                    cancellationToken);

        return challenges
            .Select(
                x =>
                    Map(
                        x.Challenge,
                        x.ParticipantCount))
            .ToList();
    }

    public async Task<ChallengeResponse?> GetByIdAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var challenge =
            await _dbContext.Challenges
                .AsNoTracking()
                .Where(x => x.Id == challengeId)
                .Select(
                    x =>
                        new
                        {
                            Challenge = x,
                            ParticipantCount =
                                x.Participants.Count()
                        })
                .FirstOrDefaultAsync(
                    cancellationToken);

        return challenge is null
            ? null
            : Map(
                challenge.Challenge,
                challenge.ParticipantCount);
    }

    public async Task<ChallengeResponse?> UpdateAsync(
        Guid userId,
        Guid challengeId,
        UpdateChallengeRequest request,
        CancellationToken cancellationToken)
    {
        var challenge =
            await _dbContext.Challenges
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == challengeId &&
                        x.CreatedByUserId == userId,
                    cancellationToken);

        if (challenge is null)
        {
            return null;
        }

        challenge.Update(
            request.Name,
            request.Description,
            request.Type,
            request.TargetValue,
            request.StartDate,
            request.EndDate);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        var participantCount =
            await _dbContext.ChallengeParticipants
                .CountAsync(
                    x => x.ChallengeId == challengeId,
                    cancellationToken);

        return Map(
            challenge,
            participantCount);
    }

    public async Task<bool> DeleteAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var challenge =
            await _dbContext.Challenges
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == challengeId &&
                        x.CreatedByUserId == userId,
                    cancellationToken);

        if (challenge is null)
        {
            return false;
        }

        _dbContext.Challenges.Remove(challenge);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    public async Task<bool> JoinAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var challenge =
            await _dbContext.Challenges
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.Id == challengeId,
                    cancellationToken);

        if (challenge is null)
        {
            return false;
        }

        if (challenge.EndDate < DateTime.UtcNow)
        {
            throw new ConflictException(
                "This challenge has already ended.");
        }

        var alreadyJoined =
            await _dbContext.ChallengeParticipants
                .AnyAsync(
                    x =>
                        x.ChallengeId == challengeId &&
                        x.UserId == userId,
                    cancellationToken);

        if (alreadyJoined)
        {
            throw new ConflictException(
                "You have already joined this challenge.");
        }

        var participant =
            new ChallengeParticipant(
                challengeId,
                userId);

        _dbContext.ChallengeParticipants.Add(
            participant);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        if (challenge.CreatedByUserId != userId)
        {
            await _notificationService.CreateAsync(
                challenge.CreatedByUserId,
                userId,
                NotificationTypes.ChallengeJoined,
                cancellationToken
            );
        }

        return true;
    }

    public async Task<bool> LeaveAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var participant =
            await _dbContext.ChallengeParticipants
                .FirstOrDefaultAsync(
                    x =>
                        x.ChallengeId == challengeId &&
                        x.UserId == userId,
                    cancellationToken);

        if (participant is null)
        {
            return false;
        }

        _dbContext.ChallengeParticipants.Remove(
            participant);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    public async Task<ChallengeProgressResponse?> GetProgressAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var challenge =
            await _dbContext.Challenges
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.Id == challengeId,
                    cancellationToken);

        if (challenge is null)
        {
            return null;
        }

        var isParticipant =
            await _dbContext.ChallengeParticipants
                .AnyAsync(
                    x =>
                        x.ChallengeId == challengeId &&
                        x.UserId == userId,
                    cancellationToken);

        if (!isParticipant)
        {
            return null;
        }

        var activities =
            await _dbContext.Activities
                .AsNoTracking()
                .Where(
                    x =>
                        x.UserId == userId &&
                        x.StartedAt >= challenge.StartDate &&
                        x.StartedAt <= challenge.EndDate)
                .ToListAsync(
                    cancellationToken);

        var current =
            CalculateValue(
                challenge.Type,
                activities);

        var remaining =
            Math.Max(
                challenge.TargetValue - current,
                0);

        var progressPercentage =
            challenge.TargetValue <= 0
                ? 0
                : Math.Min(
                    (current / challenge.TargetValue) * 100,
                    100);

        var isCompleted =
            current >= challenge.TargetValue;

        return new ChallengeProgressResponse(
            challenge.Id,
            userId,
            challenge.Type,
            challenge.TargetValue,
            current,
            remaining,
            progressPercentage,
            isCompleted);
    }

    public async Task<ChallengeLeaderboardResponse?> GetLeaderboardAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var challenge =
            await _dbContext.Challenges
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.Id == challengeId,
                    cancellationToken);

        if (challenge is null)
        {
            return null;
        }

        var isParticipant =
            await _dbContext.ChallengeParticipants
                .AnyAsync(
                    x =>
                        x.ChallengeId == challengeId &&
                        x.UserId == userId,
                    cancellationToken);

        if (!isParticipant)
        {
            return null;
        }

        var participants =
            await _dbContext.ChallengeParticipants
                .AsNoTracking()
                .Where(
                    x =>
                        x.ChallengeId == challengeId)
                .Include(x => x.User)
                .ToListAsync(
                    cancellationToken);

        var participantIds =
            participants
                .Select(x => x.UserId)
                .ToList();

        var activities =
            await _dbContext.Activities
                .AsNoTracking()
                .Where(
                    x =>
                        participantIds.Contains(x.UserId) &&
                        x.StartedAt >= challenge.StartDate &&
                        x.StartedAt <= challenge.EndDate)
                .ToListAsync(
                    cancellationToken);

        var leaderboard =
            participants
                .Select(
                    participant =>
                    {
                        var userActivities =
                            activities
                                .Where(
                                    x =>
                                        x.UserId ==
                                        participant.UserId)
                                .ToList();

                        var currentValue =
                            CalculateValue(
                                challenge.Type,
                                userActivities);

                        return new
                        {
                            participant.UserId,
                            participant.User.Username,
                            participant.User.DisplayName,
                            participant.User.ProfileImageUrl,
                            CurrentValue = currentValue
                        };
                    })
                .OrderByDescending(
                    x => x.CurrentValue)
                .ThenBy(
                    x => x.Username)
                .Select(
                    (x, index) =>
                        new ChallengeParticipantResponse(
                            x.UserId,
                            x.Username,
                            x.DisplayName,
                            x.ProfileImageUrl,
                            x.CurrentValue,
                            index + 1))
                .ToList();

        return new ChallengeLeaderboardResponse(
            challenge.Id,
            leaderboard);
    }

    private static double CalculateValue(
        string type,
        IReadOnlyCollection<Activity> activities)
    {
        return type switch
        {
            ChallengeTypes.Distance =>
                activities.Sum(
                    x => x.Distance),

            ChallengeTypes.Duration =>
                activities.Sum(
                    x => x.DurationSeconds),

            ChallengeTypes.Activities =>
                activities.Count,

            _ => 0
        };
    }

    private static ChallengeResponse Map(
        Challenge challenge,
        int participantCount)
    {
        return new ChallengeResponse(
            challenge.Id,
            challenge.CreatedByUserId,
            challenge.Name,
            challenge.Description,
            challenge.Type,
            challenge.TargetValue,
            challenge.StartDate,
            challenge.EndDate,
            challenge.CreatedAt,
            participantCount);
    }
}