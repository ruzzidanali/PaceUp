using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Configuration;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Persistence;

namespace PaceUp.Infrastructure.Authentication;

public class RefreshTokenService : IRefreshTokenService
{
    private readonly PaceUpDbContext _dbContext;
    private readonly JwtOptions _options;

    public RefreshTokenService(
        PaceUpDbContext dbContext,
        IOptions<JwtOptions> options)
    {
        _dbContext = dbContext;
        _options = options.Value;
    }

    public async Task<string> CreateAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var rawToken = GenerateToken();

        var tokenHash = HashToken(rawToken);

        var expiresAt =
            DateTime.UtcNow.AddDays(
                _options.RefreshTokenExpirationDays);

        var refreshToken =
            new RefreshToken(
                userId,
                tokenHash,
                expiresAt);

        _dbContext.RefreshTokens.Add(refreshToken);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return rawToken;
    }

    public async Task<Guid?> ValidateAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        var tokenHash = HashToken(refreshToken);

        var token =
            await _dbContext.RefreshTokens
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.TokenHash == tokenHash,
                    cancellationToken);

        if (token is null ||
            !token.IsActive())
        {
            return null;
        }

        return token.UserId;
    }

    public async Task RevokeAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        var tokenHash = HashToken(refreshToken);

        var token =
            await _dbContext.RefreshTokens
                .FirstOrDefaultAsync(
                    x => x.TokenHash == tokenHash,
                    cancellationToken);

        if (token is null)
        {
            return;
        }

        token.Revoke();

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

    public async Task RevokeAllAsync(
    Guid userId,
    CancellationToken cancellationToken)
    {
        var tokens =
            await _dbContext.RefreshTokens
                .Where(x =>
                    x.UserId == userId &&
                    x.RevokedAt == null)
                .ToListAsync(cancellationToken);

        foreach (var token in tokens)
        {
            token.Revoke();
        }

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

    public async Task<string?> RotateAsync(
    string refreshToken,
    CancellationToken cancellationToken)
    {
        var tokenHash = HashToken(refreshToken);
        var now = DateTime.UtcNow;

        await using var transaction =
            await _dbContext.Database.BeginTransactionAsync(
                cancellationToken);

        try
        {
            var existingToken =
                await _dbContext.RefreshTokens
                    .AsNoTracking()
                    .FirstOrDefaultAsync(
                        x => x.TokenHash == tokenHash,
                        cancellationToken);

            if (existingToken is null ||
                existingToken.RevokedAt.HasValue ||
                existingToken.ExpiresAt <= now)
            {
                await transaction.RollbackAsync(cancellationToken);
                return null;
            }

            var newRawToken = GenerateToken();
            var newTokenHash = HashToken(newRawToken);

            var replacementToken = new RefreshToken(
                existingToken.UserId,
                newTokenHash,
                now.AddDays(_options.RefreshTokenExpirationDays));

            var affectedRows =
                await _dbContext.RefreshTokens
                    .Where(x =>
                        x.Id == existingToken.Id &&
                        x.RevokedAt == null &&
                        x.ExpiresAt > now)
                    .ExecuteUpdateAsync(
                        setters => setters
                            .SetProperty(x => x.RevokedAt, now)
                            .SetProperty(
                                x => x.ReplacedByTokenId,
                                replacementToken.Id),
                        cancellationToken);

            if (affectedRows != 1)
            {
                await transaction.RollbackAsync(cancellationToken);
                return null;
            }

            _dbContext.RefreshTokens.Add(replacementToken);

            await _dbContext.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return newRawToken;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static string GenerateToken()
    {
        var bytes =
            RandomNumberGenerator.GetBytes(64);

        return Convert.ToBase64String(bytes);
    }

    private static string HashToken(
        string token)
    {
        var bytes =
            SHA256.HashData(
                Encoding.UTF8.GetBytes(token));

        return Convert.ToHexString(bytes);
    }
}