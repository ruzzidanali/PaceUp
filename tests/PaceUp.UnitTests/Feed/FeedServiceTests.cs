using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Feed;
using PaceUp.Application.Features.Feed;
using PaceUp.Domain.Entities;
using PaceUp.Domain.Constants;

namespace PaceUp.UnitTests.Feed;

public class FeedServiceTests
{
    [Fact]
    public async Task GetAsync_WithNoFollowing_ShouldReturnOwnActivities()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        db.Users.Add(user);

        db.Activities.Add(
            new Activity(
                user.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-1)));

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(),
                CancellationToken.None);

        Assert.Equal(1, result.TotalCount);
        Assert.Single(result.Activities);

        Assert.Equal(
            user.Id,
            result.Activities[0].UserId);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnFollowedUsersActivities()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        var followed =
            new User(
                "user2",
                "user2@example.com",
                "User Two");

        db.Users.AddRange(
            user,
            followed);

        db.Follows.Add(
            new Follow(
                user.Id,
                followed.Id));

        db.Activities.Add(
            new Activity(
                followed.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-1)));

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(),
                CancellationToken.None);

        Assert.Equal(1, result.TotalCount);
        Assert.Single(result.Activities);

        Assert.Equal(
            followed.Id,
            result.Activities[0].UserId);

        Assert.Equal(
            followed.Username,
            result.Activities[0].Username);

        Assert.Equal(
            followed.DisplayName,
            result.Activities[0].DisplayName);
    }

    [Fact]
    public async Task GetAsync_ShouldNotReturnUnfollowedUsersActivities()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        var otherUser =
            new User(
                "user2",
                "user2@example.com",
                "User Two");

        db.Users.AddRange(
            user,
            otherUser);

        db.Activities.Add(
            new Activity(
                otherUser.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-1)));

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(),
                CancellationToken.None);

        Assert.Equal(0, result.TotalCount);
        Assert.Empty(result.Activities);
    }

    [Fact]
    public async Task GetAsync_ShouldIncludeOwnAndFollowedActivities()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        var followed =
            new User(
                "user2",
                "user2@example.com",
                "User Two");

        db.Users.AddRange(
            user,
            followed);

        db.Follows.Add(
            new Follow(
                user.Id,
                followed.Id));

        db.Activities.AddRange(
            new Activity(
                user.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-2)),

            new Activity(
                followed.Id,
                ActivityTypes.Ride,
                10,
                3600,
                600,
                DateTime.UtcNow.AddHours(-1)));

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(),
                CancellationToken.None);

        Assert.Equal(2, result.TotalCount);

        Assert.Equal(
            followed.Id,
            result.Activities[0].UserId);

        Assert.Equal(
            user.Id,
            result.Activities[1].UserId);
    }

    [Fact]
    public async Task GetAsync_ShouldOrderByStartedAtDescending()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        db.Users.Add(user);

        var oldest =
            new Activity(
                user.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-3));

        var newest =
            new Activity(
                user.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-1));

        var middle =
            new Activity(
                user.Id,
                ActivityTypes.Run,
                5,
                1800,
                400,
                DateTime.UtcNow.AddHours(-2));

        db.Activities.AddRange(
            oldest,
            newest,
            middle);

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(),
                CancellationToken.None);

        Assert.Equal(3, result.TotalCount);

        Assert.Equal(
            newest.Id,
            result.Activities[0].Id);

        Assert.Equal(
            middle.Id,
            result.Activities[1].Id);

        Assert.Equal(
            oldest.Id,
            result.Activities[2].Id);
    }

    [Fact]
    public async Task GetAsync_ShouldPaginate()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        db.Users.Add(user);

        for (var i = 0; i < 5; i++)
        {
            db.Activities.Add(
                new Activity(
                    user.Id,
                    ActivityTypes.Run,
                    5,
                    1800,
                    400,
                    DateTime.UtcNow.AddHours(-i)));
        }

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(
                    Page: 2,
                    PageSize: 2),
                CancellationToken.None);

        Assert.Equal(5, result.TotalCount);
        Assert.Equal(2, result.Page);
        Assert.Equal(2, result.PageSize);
        Assert.Equal(3, result.TotalPages);

        Assert.Equal(2, result.Activities.Count);
    }

    [Fact]
    public async Task GetAsync_ShouldClampPageSizeTo100()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user1",
                "user1@example.com",
                "User One");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service =
            new FeedService(db);

        var result =
            await service.GetAsync(
                user.Id,
                new FeedRequest(
                    Page: 1,
                    PageSize: 500),
                CancellationToken.None);

        Assert.Equal(100, result.PageSize);
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

        public DbSet<Activity> Activities =>
            Set<Activity>();

        public DbSet<Goal> Goals =>
            Set<Goal>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<RefreshToken> RefreshTokens =>
            Set<RefreshToken>();

        public DbSet<Follow> Follows =>
            Set<Follow>();

        protected override void OnModelCreating(
    ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<UserIdentity>()
                .HasKey(x => x.UserId);

            modelBuilder.Entity<Activity>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Follow>()
                .HasKey(x => x.Id);
        }
    }
}