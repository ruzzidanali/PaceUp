using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Notifications;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Notifications;
using PaceUp.Application.Features.Achievements;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Achievements;

public class AchievementServiceTests
{
    [Fact]
    public async Task EvaluateAsync_ShouldUnlockFirstActivity()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var achievement = new Achievement(
            "FIRST_ACTIVITY",
            "First Steps",
            "Complete your first activity.",
            "directions_run",
            "ACTIVITY_COUNT",
            1);

        db.Achievements.Add(achievement);

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        var unlockedAchievement = Assert.Single(result);

        Assert.Equal(
            "FIRST_ACTIVITY",
            unlockedAchievement.Code);

        Assert.Equal(
            "First Steps",
            unlockedAchievement.Name);

        Assert.NotNull(
            unlockedAchievement.UnlockedAt);

        Assert.Single(
            notificationService.CreatedNotifications);

        var notification =
            notificationService.CreatedNotifications[0];

        Assert.Equal(
            user.Id,
            notification.RecipientUserId);

        Assert.Null(
            notification.ActorUserId);

        Assert.Equal(
            "AchievementUnlocked",
            notification.Type);

        Assert.Equal(
            achievement.Id,
            notification.TargetId);

        var saved = await db.UserAchievements
            .SingleAsync();

        Assert.Equal(
            user.Id,
            saved.UserId);

        Assert.Equal(
            achievement.Id,
            saved.AchievementId);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldUnlockActivityCountAchievement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "ACTIVITIES_5",
                "Getting Started",
                "Complete 5 activities.",
                "looks_5",
                "ACTIVITY_COUNT",
                5));

        for (var i = 0; i < 5; i++)
        {
            db.Activities.Add(
                new Activity(
                    user.Id,
                    "Run",
                    5,
                    1800,
                    300,
                    DateTime.UtcNow.AddDays(-i)));
        }

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        var achievement = Assert.Single(result);

        Assert.Equal(
            "ACTIVITIES_5",
            achievement.Code);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldNotUnlockActivityCountAchievementBelowRequirement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "ACTIVITIES_5",
                "Getting Started",
                "Complete 5 activities.",
                "looks_5",
                "ACTIVITY_COUNT",
                5));

        for (var i = 0; i < 4; i++)
        {
            db.Activities.Add(
                new Activity(
                    user.Id,
                    "Run",
                    5,
                    1800,
                    300,
                    DateTime.UtcNow.AddDays(-i)));
        }

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        Assert.Empty(result);

        Assert.Empty(
            notificationService.CreatedNotifications);

        Assert.Empty(
            await db.UserAchievements.ToListAsync());
    }

    [Fact]
    public async Task EvaluateAsync_ShouldUnlockDistanceAchievement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "TOTAL_DISTANCE_10KM",
                "10K Club",
                "Reach 10 km of total distance.",
                "route",
                "TOTAL_DISTANCE_KM",
                10));

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                6,
                1800,
                300,
                DateTime.UtcNow.AddDays(-1)),

            new Activity(
                user.Id,
                "Run",
                4,
                1500,
                250,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        var achievement = Assert.Single(result);

        Assert.Equal(
            "TOTAL_DISTANCE_10KM",
            achievement.Code);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldNotUnlockDistanceAchievementBelowRequirement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "TOTAL_DISTANCE_10KM",
                "10K Club",
                "Reach 10 km of total distance.",
                "route",
                "TOTAL_DISTANCE_KM",
                10));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                9.99,
                1800,
                300,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        Assert.Empty(result);

        Assert.Empty(
            notificationService.CreatedNotifications);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldUnlockDurationAchievement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "ACTIVITY_DURATION_60MIN",
                "One Hour",
                "Complete an activity lasting at least 60 minutes.",
                "timer",
                "ACTIVITY_DURATION_MINUTES",
                60));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                10,
                3600,
                600,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        var achievement = Assert.Single(result);

        Assert.Equal(
            "ACTIVITY_DURATION_60MIN",
            achievement.Code);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldNotUnlockDurationAchievementBelowRequirement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "ACTIVITY_DURATION_60MIN",
                "One Hour",
                "Complete an activity lasting at least 60 minutes.",
                "timer",
                "ACTIVITY_DURATION_MINUTES",
                60));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                10,
                3599,
                600,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        Assert.Empty(result);

        Assert.Empty(
            notificationService.CreatedNotifications);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldNotDuplicateExistingAchievement()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var achievement = new Achievement(
            "FIRST_ACTIVITY",
            "First Steps",
            "Complete your first activity.",
            "directions_run",
            "ACTIVITY_COUNT",
            1);

        db.Achievements.Add(achievement);

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        db.UserAchievements.Add(
            new UserAchievement(
                user.Id,
                achievement.Id));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        Assert.Empty(result);

        Assert.Empty(
            notificationService.CreatedNotifications);

        var savedAchievements =
            await db.UserAchievements.ToListAsync();

        Assert.Single(savedAchievements);
    }

    [Fact]
    public async Task EvaluateAsync_ShouldUnlockMultipleAchievementsAtOnce()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.AddRange(
            new Achievement(
                "FIRST_ACTIVITY",
                "First Steps",
                "Complete your first activity.",
                "directions_run",
                "ACTIVITY_COUNT",
                1),

            new Achievement(
                "TOTAL_DISTANCE_10KM",
                "10K Club",
                "Reach 10 km of total distance.",
                "route",
                "TOTAL_DISTANCE_KM",
                10));

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow.AddDays(-1)),

            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(
            2,
            notificationService.CreatedNotifications.Count);

        Assert.All(
            notificationService.CreatedNotifications,
            notification =>
            {
                Assert.Equal(
                    user.Id,
                    notification.RecipientUserId);

                Assert.Null(
                    notification.ActorUserId);

                Assert.Equal(
                    "AchievementUnlocked",
                    notification.Type);

                Assert.NotNull(
                    notification.TargetId);
            });

        Assert.Equal(
            2,
            result.Count);

        Assert.Contains(
            result,
            x => x.Code == "FIRST_ACTIVITY");

        Assert.Contains(
            result,
            x => x.Code == "TOTAL_DISTANCE_10KM");

        Assert.Equal(
            2,
            await db.UserAchievements.CountAsync());
    }

    [Fact]
    public async Task EvaluateAsync_ShouldReturnEmptyWhenNoAchievementIsQualified()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        db.Achievements.Add(
            new Achievement(
                "ACTIVITIES_10",
                "Dedicated",
                "Complete 10 activities.",
                "looks_10",
                "ACTIVITY_COUNT",
                10));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var notificationService = new FakeNotificationService();

        var service = new AchievementService(
            db,
            notificationService);

        var result = await service.EvaluateAsync(
            user.Id,
            CancellationToken.None);

        Assert.Empty(result);

        Assert.Empty(
            notificationService.CreatedNotifications);
    }

    private static User CreateUser()
    {
        return new User(
            "achievement_user",
            "achievement@example.com",
            "Achievement User");
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

        public DbSet<ActivityPoint> ActivityPoints =>
            Set<ActivityPoint>();

        public DbSet<Comment> Comments =>
            Set<Comment>();

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

        public DbSet<Achievement> Achievements =>
            Set<Achievement>();

        public DbSet<UserAchievement> UserAchievements =>
            Set<UserAchievement>();

        public DbSet<UserGamification> UserGamifications => Set<UserGamification>();

        public DbSet<XpTransaction> XpTransactions =>
            Set<XpTransaction>();

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

            modelBuilder.Entity<Achievement>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<UserAchievement>()
                .HasKey(x => x.Id);
        }
    }

    private sealed class FakeNotificationService : INotificationService
    {
        public List<CreatedNotification> CreatedNotifications { get; } = [];

        public Task CreateAsync(
            Guid recipientUserId,
            Guid? actorUserId,
            string type,
            Guid? targetId,
            CancellationToken cancellationToken)
        {
            CreatedNotifications.Add(
                new CreatedNotification(
                    recipientUserId,
                    actorUserId,
                    type,
                    targetId));

            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<NotificationResponse>> GetAsync(
            Guid userId,
            CancellationToken cancellationToken)
        {
            return Task.FromResult<IReadOnlyList<NotificationResponse>>([]);
        }

        public Task<bool> MarkAsReadAsync(
            Guid userId,
            Guid notificationId,
            CancellationToken cancellationToken)
        {
            return Task.FromResult(false);
        }

        public Task MarkAllAsReadAsync(
            Guid userId,
            CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }
    }

    private sealed record CreatedNotification(
        Guid RecipientUserId,
        Guid? ActorUserId,
        string Type,
        Guid? TargetId);
}