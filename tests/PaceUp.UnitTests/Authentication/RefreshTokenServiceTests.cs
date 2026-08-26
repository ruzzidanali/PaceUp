using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Authentication;
using PaceUp.Infrastructure.Persistence;
using Microsoft.Extensions.Options;
using PaceUp.Application.Configuration;

namespace PaceUp.UnitTests.Authentication;

public class RefreshTokenServiceTests
{
    private static PaceUpDbContext CreateDatabase()
    {
        var options =
            new DbContextOptionsBuilder<PaceUpDbContext>()
                .UseInMemoryDatabase(
                    Guid.NewGuid().ToString())
                .Options;

        return new PaceUpDbContext(options);
    }

    private static RefreshTokenService CreateService(
        PaceUpDbContext db)
    {
        var options =
            Options.Create(
                new JwtOptions
                {
                    RefreshTokenExpirationDays = 30
                });

        return new RefreshTokenService(
            db,
            options);
    }

    [Fact]
    public async Task CreateAsync_ShouldReturnTokenAndPersistHash()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        var user =
            new User(
                "refresh_create_user",
                "refresh_create@example.com",
                "Refresh Create User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var rawToken =
            await service.CreateAsync(
                user.Id,
                CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(rawToken));

        var savedToken =
            await db.RefreshTokens
                .SingleAsync(
                    x => x.UserId == user.Id);

        Assert.NotEqual(
            rawToken,
            savedToken.TokenHash);

        Assert.True(savedToken.IsActive());
        Assert.Equal(
            user.Id,
            savedToken.UserId);
    }

    [Fact]
    public async Task ValidateAsync_WithValidToken_ShouldReturnUserId()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        var user =
            new User(
                "refresh_validate_user",
                "refresh_validate@example.com",
                "Refresh Validate User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var rawToken =
            await service.CreateAsync(
                user.Id,
                CancellationToken.None);

        var result =
            await service.ValidateAsync(
                rawToken,
                CancellationToken.None);

        Assert.Equal(
            user.Id,
            result);
    }

    [Fact]
    public async Task ValidateAsync_WithInvalidToken_ShouldReturnNull()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        var result =
            await service.ValidateAsync(
                "invalid-refresh-token",
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task ValidateAsync_WithRevokedToken_ShouldReturnNull()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        var user =
            new User(
                "refresh_revoke_user",
                "refresh_revoke@example.com",
                "Refresh Revoke User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var rawToken =
            await service.CreateAsync(
                user.Id,
                CancellationToken.None);

        await service.RevokeAsync(
            rawToken,
            CancellationToken.None);

        var result =
            await service.ValidateAsync(
                rawToken,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task RotateAsync_ShouldRevokeOldTokenAndCreateReplacement()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        var user =
            new User(
                "refresh_rotate_user",
                "refresh_rotate@example.com",
                "Refresh Rotate User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var originalToken =
            await service.CreateAsync(
                user.Id,
                CancellationToken.None);

        var replacementToken =
            await service.RotateAsync(
                originalToken,
                CancellationToken.None);

        Assert.NotNull(replacementToken);
        Assert.NotEqual(
            originalToken,
            replacementToken);

        var tokens =
            await db.RefreshTokens
                .Where(x => x.UserId == user.Id)
                .ToListAsync();

        Assert.Equal(2, tokens.Count);

        var oldToken =
            tokens.Single(
                x =>
                    !x.IsActive() &&
                    x.ReplacedByTokenId.HasValue);

        var newToken =
            tokens.Single(
                x => x.IsActive());

        Assert.Equal(
            newToken.Id,
            oldToken.ReplacedByTokenId);

        Assert.True(oldToken.IsRevoked());
        Assert.True(newToken.IsActive());
    }

    [Fact]
    public async Task RotateAsync_WithAlreadyRotatedToken_ShouldReturnNull()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        var user =
            new User(
                "refresh_reuse_user",
                "refresh_reuse@example.com",
                "Refresh Reuse User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var originalToken =
            await service.CreateAsync(
                user.Id,
                CancellationToken.None);

        var replacementToken =
            await service.RotateAsync(
                originalToken,
                CancellationToken.None);

        Assert.NotNull(replacementToken);

        var secondRotation =
            await service.RotateAsync(
                originalToken,
                CancellationToken.None);

        Assert.Null(secondRotation);
    }

    [Fact]
    public async Task RevokeAsync_WithUnknownToken_ShouldDoNothing()
    {
        await using var db = CreateDatabase();

        var service = CreateService(db);

        await service.RevokeAsync(
            "unknown-refresh-token",
            CancellationToken.None);

        Assert.Empty(
            await db.RefreshTokens.ToListAsync());
    }
}
