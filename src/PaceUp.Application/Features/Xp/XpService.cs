using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Abstractions.Xp;
using PaceUp.Domain.Constants;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Xp;

public class XpService : IXpService
{
    private const int ActivityXp = 10;

    private readonly IApplicationDbContext _dbContext;

    public XpService(
        IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AwardActivityXpAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var existingTransaction =
            await _dbContext.XpTransactions
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.UserId == userId &&
                        x.SourceType == XpSourceTypes.Activity &&
                        x.SourceId == activityId,
                    cancellationToken);

        if (existingTransaction)
        {
            return;
        }

        var userGamification =
            await _dbContext.UserGamifications
                .FirstOrDefaultAsync(
                    x => x.UserId == userId,
                    cancellationToken);

        if (userGamification is null)
        {
            userGamification =
                new UserGamification(userId);

            _dbContext.UserGamifications.Add(
                userGamification);
        }

        var transaction =
            new XpTransaction(
                userId,
                ActivityXp,
                XpSourceTypes.Activity,
                activityId);

        _dbContext.XpTransactions.Add(transaction);

        userGamification.AddXp(ActivityXp);

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

    public async Task AwardChallengeXpAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken
    )
    {
        const int challengeXp = 50;

        var existingTransaction =
            await _dbContext.XpTransactions
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.UserId == userId &&
                        x.SourceType == XpSourceTypes.Challenge &&
                        x.SourceId == challengeId,
                    cancellationToken
                );

        if (existingTransaction)
        {
            return;
        }

        var userGamification =
            await _dbContext.UserGamifications
                .FirstOrDefaultAsync(
                    x => x.UserId == userId,
                    cancellationToken
                );

        if (userGamification is null)
        {
            userGamification =
                new UserGamification(userId);

            _dbContext.UserGamifications.Add(
                userGamification
            );
        }

        var transaction =
            new XpTransaction(
                userId,
                challengeXp,
                XpSourceTypes.Challenge,
                challengeId
            );

        _dbContext.XpTransactions.Add(transaction);

        userGamification.AddXp(challengeXp);

        await _dbContext.SaveChangesAsync(
            cancellationToken
        );
    }
}