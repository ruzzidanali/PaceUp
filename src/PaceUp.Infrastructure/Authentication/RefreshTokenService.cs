using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Configuration;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Authentication;

public class RefreshTokenService : IRefreshTokenService
{
    private readonly IApplicationDbContext _dbContext;
    private readonly JwtOptions _options;

    public RefreshTokenService(
        IApplicationDbContext dbContext,
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

    public async Task<string?> RotateAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        var tokenHash = HashToken(refreshToken);

        var existingToken =
            await _dbContext.RefreshTokens
                .FirstOrDefaultAsync(
                    x => x.TokenHash == tokenHash,
                    cancellationToken);

        if (existingToken is null ||
            !existingToken.IsActive())
        {
            return null;
        }

        var newRawToken = GenerateToken();

        var newTokenHash = HashToken(newRawToken);

        var newExpiresAt =
            DateTime.UtcNow.AddDays(
                _options.RefreshTokenExpirationDays);

        var replacementToken =
            new RefreshToken(
                existingToken.UserId,
                newTokenHash,
                newExpiresAt);

        _dbContext.RefreshTokens.Add(
            replacementToken);

        existingToken.ReplaceWith(
            replacementToken.Id);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return newRawToken;
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