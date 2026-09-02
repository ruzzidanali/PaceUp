using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Features.Kudos;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Kudos;

public class KudosServiceTests
{
    [Fact]
    public async Task GetAsync_ShouldReturnKudosCountAndUserStatus()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        var otherUser = new User(
            "other",
            "other@example.com",
            "Other");

        db.Users.AddRange(
            owner,
            user,
            otherUser);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        db.Kudos.AddRange(
            new PaceUp.Domain.Entities.Kudos(
                activity.Id,
                user.Id),
            new PaceUp.Domain.Entities.Kudos(
                activity.Id,
                otherUser.Id));

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        var result =
            await service.GetAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Equal(
            activity.Id,
            result.ActivityId);

        Assert.Equal(
            2,
            result.KudosCount);

        Assert.True(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnFalseWhenUserHasNotGivenKudos()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        var result =
            await service.GetAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Equal(
            0,
            result.KudosCount);

        Assert.False(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task GiveAsync_ShouldCreateKudos()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        var result =
            await service.GiveAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Equal(
            1,
            result.KudosCount);

        Assert.True(
            result.HasGivenKudos);

        var savedKudos =
            await db.Kudos
                .SingleAsync(
                    x =>
                        x.ActivityId == activity.Id &&
                        x.UserId == user.Id);

        Assert.NotEqual(
            Guid.Empty,
            savedKudos.Id);
    }

    [Fact]
    public async Task GiveAsync_ShouldCreateActivityKudosNotification()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await service.GiveAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        var notification =
            await db.Notifications
                .SingleAsync();

        Assert.Equal(
            owner.Id,
            notification.RecipientUserId);

        Assert.Equal(
            user.Id,
            notification.ActorUserId);

        Assert.Equal(
            "ActivityKudos",
            notification.Type);

        Assert.False(
            notification.IsRead);
    }

    [Fact]
    public async Task GiveAsync_ShouldNotCreateDuplicateKudos()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await service.GiveAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        var result =
            await service.GiveAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Equal(
            1,
            result.KudosCount);

        var kudosCount =
            await db.Kudos.CountAsync(
                x =>
                    x.ActivityId == activity.Id &&
                    x.UserId == user.Id);

        Assert.Equal(
            1,
            kudosCount);

        var notificationCount =
            await db.Notifications.CountAsync();

        Assert.Equal(
            1,
            notificationCount);
    }

    [Fact]
    public async Task GiveAsync_ShouldThrowWhenUserKudosOwnActivity()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.Add(user);

        var activity = new Activity(
            user.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () =>
                service.GiveAsync(
                    user.Id,
                    activity.Id,
                    CancellationToken.None));
    }

    [Fact]
    public async Task GiveAsync_ShouldThrowWhenActivityDoesNotExist()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () =>
                service.GiveAsync(
                    user.Id,
                    Guid.NewGuid(),
                    CancellationToken.None));
    }

    [Fact]
    public async Task RemoveAsync_ShouldRemoveKudos()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        var kudos =
            new PaceUp.Domain.Entities.Kudos(
                activity.Id,
                user.Id);

        db.Kudos.Add(kudos);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        var result =
            await service.RemoveAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Equal(
            0,
            result.KudosCount);

        Assert.False(
            result.HasGivenKudos);

        var savedKudos =
            await db.Kudos
                .FirstOrDefaultAsync(
                    x => x.Id == kudos.Id);

        Assert.Null(savedKudos);
    }

    [Fact]
    public async Task RemoveAsync_ShouldBeIdempotent()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        var result =
            await service.RemoveAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Equal(
            0,
            result.KudosCount);

        Assert.False(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task RemoveAsync_ShouldNotCreateNotification()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.AddRange(
            owner,
            user);

        var activity = new Activity(
            owner.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        db.Kudos.Add(
            new PaceUp.Domain.Entities.Kudos(
                activity.Id,
                user.Id));

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await service.RemoveAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        Assert.Equal(
            0,
            await db.Notifications.CountAsync());
    }

    [Fact]
    public async Task GetAsync_ShouldThrowWhenActivityDoesNotExist()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () =>
                service.GetAsync(
                    user.Id,
                    Guid.NewGuid(),
                    CancellationToken.None));
    }

    [Fact]
    public async Task RemoveAsync_ShouldThrowWhenActivityDoesNotExist()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "user",
            "user@example.com",
            "User");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var service = new KudosService(db);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () =>
                service.RemoveAsync(
                    user.Id,
                    Guid.NewGuid(),
                    CancellationToken.None));
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

        public DbSet<Follow> Follows { get; } = null!;

        public DbSet<Activity> Activities =>
            Set<Activity>();

        public DbSet<PaceUp.Domain.Entities.Kudos> Kudos =>
            Set<PaceUp.Domain.Entities.Kudos>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<RefreshToken> RefreshTokens { get; } = null!;

        public DbSet<Notification> Notifications =>
            Set<Notification>();

        public DbSet<Challenge> Challenges =>
            Set<Challenge>();

        public DbSet<ChallengeParticipant> ChallengeParticipants =>
            Set<ChallengeParticipant>();

        protected override void OnModelCreating(
            ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<UserIdentity>()
                .HasKey(x => x.UserId);

            modelBuilder.Entity<Activity>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<PaceUp.Domain.Entities.Kudos>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Notification>()
                .HasKey(x => x.Id);
        }
    }
}