using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Users;
using PaceUp.Application.Features.Users;
using PaceUp.Domain.Entities;
using PaceUp.Application.Exceptions;

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

        public DbSet<Follow> Follows =>
            Set<Follow>();

        public DbSet<Activity> Activities =>
            Set<Activity>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<RefreshToken> RefreshTokens =>
            Set<RefreshToken>();

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

            modelBuilder.Entity<Follow>()
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

    [Fact]
    public async Task FollowAsync_ShouldCreateFollow()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        var following = new User(
            "following",
            "following@example.com",
            "Following");

        db.Users.AddRange(follower, following);

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.FollowAsync(
            follower.Id,
            following.Id,
            CancellationToken.None);

        Assert.True(result);

        var follow = await db.Follows
            .SingleAsync();

        Assert.Equal(
            follower.Id,
            follow.FollowerId);

        Assert.Equal(
            following.Id,
            follow.FollowingId);
    }

    [Fact]
    public async Task FollowAsync_WhenFollowingUserDoesNotExist_ShouldReturnFalse()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        db.Users.Add(follower);

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.FollowAsync(
            follower.Id,
            Guid.NewGuid(),
            CancellationToken.None);

        Assert.False(result);

        Assert.Empty(
            await db.Follows.ToListAsync());
    }

    [Fact]
    public async Task FollowAsync_WhenFollowingSelf_ShouldThrowConflict()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service = new UserService(db);

        await Assert.ThrowsAsync<ConflictException>(
            () => service.FollowAsync(
                user.Id,
                user.Id,
                CancellationToken.None));
    }

    [Fact]
    public async Task FollowAsync_WhenTargetUserDoesNotExist_ShouldReturnFalse()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        db.Users.Add(follower);

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.FollowAsync(
            follower.Id,
            Guid.NewGuid(),
            CancellationToken.None);

        Assert.False(result);

        Assert.Empty(await db.Follows.ToListAsync());
    }

    [Fact]
    public async Task FollowAsync_WhenAlreadyFollowing_ShouldThrowConflict()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        var following = new User(
            "following",
            "following@example.com",
            "Following");

        db.Users.AddRange(follower, following);

        await db.SaveChangesAsync();

        db.Follows.Add(
            new Follow(
                follower.Id,
                following.Id));

        await db.SaveChangesAsync();

        var service = new UserService(db);

        await Assert.ThrowsAsync<ConflictException>(
            () => service.FollowAsync(
                follower.Id,
                following.Id,
                CancellationToken.None));
    }

    [Fact]
    public async Task UnfollowAsync_ShouldRemoveFollow()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        var following = new User(
            "following",
            "following@example.com",
            "Following");

        db.Users.AddRange(follower, following);

        await db.SaveChangesAsync();

        db.Follows.Add(
            new Follow(
                follower.Id,
                following.Id));

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.UnfollowAsync(
            follower.Id,
            following.Id,
            CancellationToken.None);

        Assert.True(result);

        Assert.Empty(
            await db.Follows.ToListAsync());
    }

    [Fact]
    public async Task UnfollowAsync_WhenFollowDoesNotExist_ShouldReturnFalse()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        var following = new User(
            "following",
            "following@example.com",
            "Following");

        db.Users.AddRange(follower, following);

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.UnfollowAsync(
            follower.Id,
            following.Id,
            CancellationToken.None);

        Assert.False(result);
    }

    [Fact]
    public async Task GetFollowersAsync_ShouldReturnFollowers()
    {
        await using var db = CreateDatabase();

        var target = new User(
            "target",
            "target@example.com",
            "Target");

        var follower1 = new User(
            "follower1",
            "follower1@example.com",
            "Follower 1");

        var follower2 = new User(
            "follower2",
            "follower2@example.com",
            "Follower 2");

        db.Users.AddRange(
            target,
            follower1,
            follower2);

        await db.SaveChangesAsync();

        db.Follows.AddRange(
            new Follow(follower1.Id, target.Id),
            new Follow(follower2.Id, target.Id));

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.GetFollowersAsync(
            target.Id,
            CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal(2, result.TotalCount);

        Assert.Contains(
            result.Users,
            x => x.UserId == follower1.Id);

        Assert.Contains(
            result.Users,
            x => x.UserId == follower2.Id);
    }

    [Fact]
    public async Task GetFollowingAsync_ShouldReturnFollowingUsers()
    {
        await using var db = CreateDatabase();

        var follower = new User(
            "follower",
            "follower@example.com",
            "Follower");

        var following1 = new User(
            "following1",
            "following1@example.com",
            "Following 1");

        var following2 = new User(
            "following2",
            "following2@example.com",
            "Following 2");

        db.Users.AddRange(
            follower,
            following1,
            following2);

        await db.SaveChangesAsync();

        db.Follows.AddRange(
            new Follow(follower.Id, following1.Id),
            new Follow(follower.Id, following2.Id));

        await db.SaveChangesAsync();

        var service = new UserService(db);

        var result = await service.GetFollowingAsync(
            follower.Id,
            CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal(2, result.TotalCount);

        Assert.Contains(
            result.Users,
            x => x.UserId == following1.Id);

        Assert.Contains(
            result.Users,
            x => x.UserId == following2.Id);
    }
}