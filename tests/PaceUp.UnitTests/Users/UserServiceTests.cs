using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Users;
using PaceUp.Application.Features.Users;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Users;

public class UserServiceTests
{
    [Fact]
    public async Task UpdateProfileAsync_ShouldUpdateUserProfile()
    {
        await using var db =
            CreateDatabase();

        var user = new User(
            "ruzzidan",
            "ruzzidan@example.com",
            "Old Name");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service =
            new UserService(db);

        var request =
            new UpdateProfileRequest(
                "New Name",
                "Updated bio");

        var result =
            await service.UpdateProfileAsync(
                user.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            user.Id,
            result.Id);

        Assert.Equal(
            "New Name",
            result.DisplayName);

        Assert.Equal(
            "Updated bio",
            result.Bio);

        var savedUser =
            await db.Users
                .SingleAsync(
                    x => x.Id == user.Id);

        Assert.Equal(
            "New Name",
            savedUser.DisplayName);

        Assert.Equal(
            "Updated bio",
            savedUser.Bio);
    }

    [Fact]
    public async Task UpdateProfileAsync_WhenUserDoesNotExist_ShouldReturnNull()
    {
        await using var db =
            CreateDatabase();

        var service =
            new UserService(db);

        var request =
            new UpdateProfileRequest(
                "New Name",
                "Updated bio");

        var result =
            await service.UpdateProfileAsync(
                Guid.NewGuid(),
                request,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task UpdateProfileAsync_WithNullBio_ShouldClearBio()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "ruzzidan",
                "ruzzidan@example.com",
                "Ruzzidan");

        user.UpdateProfile(
            "Ruzzidan",
            "Existing bio");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service =
            new UserService(db);

        var request =
            new UpdateProfileRequest(
                "Ruzzidan",
                null);

        var result =
            await service.UpdateProfileAsync(
                user.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Null(result.Bio);

        var savedUser =
            await db.Users
                .SingleAsync(
                    x => x.Id == user.Id);

        Assert.Null(
            savedUser.Bio);
    }

    private static TestDbContext CreateDatabase()
    {
        var options =
            new DbContextOptionsBuilder<TestDbContext>()
                .UseInMemoryDatabase(
                    Guid.NewGuid().ToString())
                .Options;

        return new TestDbContext(options);
    }

    private sealed class TestDbContext :
        DbContext,
        IApplicationDbContext
    {
        public TestDbContext(
            DbContextOptions<TestDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users =>
            Set<User>();

        public DbSet<UserIdentity> UserIdentities =>
            Set<UserIdentity>();

        public DbSet<Goal> Goals =>
            Set<Goal>();

        public DbSet<Activity> Activities =>
            Set<Activity>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<RefreshToken> RefreshTokens { get; } = null!;

        protected override void OnModelCreating(
            ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<UserIdentity>()
                .HasKey(x => x.UserId);

            modelBuilder.Entity<Activity>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);
        }
    }

    [Fact]
    public async Task UpdateProfileImageAsync_ShouldUpdateProfileImage()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "ruzzidan",
                "ruzzidan@example.com",
                "Ruzzidan");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service =
            new UserService(db);

        var request =
            new UpdateProfileImageRequest(
                "https://example.com/profile.jpg");

        var result =
            await service.UpdateProfileImageAsync(
                user.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            "https://example.com/profile.jpg",
            result.ProfileImageUrl);

        var savedUser =
            await db.Users
                .SingleAsync(
                    x => x.Id == user.Id);

        Assert.Equal(
            "https://example.com/profile.jpg",
            savedUser.ProfileImageUrl);
    }

    [Fact]
    public async Task UpdateProfileImageAsync_WhenUserDoesNotExist_ShouldReturnNull()
    {
        await using var db =
            CreateDatabase();

        var service =
            new UserService(db);

        var request =
            new UpdateProfileImageRequest(
                "https://example.com/profile.jpg");

        var result =
            await service.UpdateProfileImageAsync(
                Guid.NewGuid(),
                request,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task UpdateProfileImageAsync_WithNullUrl_ShouldClearProfileImage()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "ruzzidan",
                "ruzzidan@example.com",
                "Ruzzidan");

        user.UpdateProfileImage(
            "https://example.com/old-profile.jpg");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service =
            new UserService(db);

        var request =
            new UpdateProfileImageRequest(null);

        var result =
            await service.UpdateProfileImageAsync(
                user.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Null(
            result.ProfileImageUrl);

        var savedUser =
            await db.Users
                .SingleAsync(
                    x => x.Id == user.Id);

        Assert.Null(
            savedUser.ProfileImageUrl);
    }
}