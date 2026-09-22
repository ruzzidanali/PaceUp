using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Features.Streaks;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Streaks;

public class StreakServiceTests
{
    [Fact]
    public async Task GetAsync_ShouldReturnZero_WhenUserHasNoActivities()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            0,
            result.CurrentStreak);

        Assert.Equal(
            0,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnOneDayStreak_WhenUserHasActivityToday()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);

        db.Activities.Add(
            CreateActivity(
                user.Id,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            1,
            result.CurrentStreak);

        Assert.Equal(
            1,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldCalculateConsecutiveCurrentStreak()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);

        var today = DateTime.UtcNow.Date;

        for (var daysAgo = 0; daysAgo < 4; daysAgo++)
        {
            db.Activities.Add(
                CreateActivity(
                    user.Id,
                    today.AddDays(-daysAgo)));
        }

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            4,
            result.CurrentStreak);

        Assert.Equal(
            4,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldCountMultipleActivitiesOnSameDayAsOneDay()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);

        var today = DateTime.UtcNow.Date;

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddHours(8)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddHours(14)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddHours(20)));

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            1,
            result.CurrentStreak);

        Assert.Equal(
            1,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldBreakCurrentStreak_WhenThereIsAGap()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);

        var today = DateTime.UtcNow.Date;

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-1)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-2)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-4)));

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            3,
            result.CurrentStreak);

        Assert.Equal(
            3,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnZeroCurrentStreak_WhenLatestActivityIsOlderThanYesterday()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);

        var today = DateTime.UtcNow.Date;

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-3)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-4)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-5)));

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            0,
            result.CurrentStreak);

        Assert.Equal(
            3,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldPreserveLongestStreak_WhenCurrentStreakIsShorter()
    {
        using var db = CreateDatabase();

        var user = CreateUser();

        db.Users.Add(user);

        var today = DateTime.UtcNow.Date;

        // Current streak: today + yesterday.
        db.Activities.Add(
            CreateActivity(
                user.Id,
                today));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-1)));

        // Older longest streak: four consecutive days.
        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-5)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-6)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-7)));

        db.Activities.Add(
            CreateActivity(
                user.Id,
                today.AddDays(-8)));

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            2,
            result.CurrentStreak);

        Assert.Equal(
            4,
            result.LongestStreak);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnZeroForAnotherUser()
    {
        using var db = CreateDatabase();

        var requestedUser = CreateUser();
        var anotherUser = CreateUser();

        db.Users.Add(requestedUser);
        db.Users.Add(anotherUser);

        db.Activities.Add(
            CreateActivity(
                anotherUser.Id,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new StreakService(db);

        var result =
            await service.GetAsync(
                requestedUser.Id,
                CancellationToken.None);

        Assert.Equal(
            0,
            result.CurrentStreak);

        Assert.Equal(
            0,
            result.LongestStreak);
    }

    private static User CreateUser()
    {
        return new User(
            $"streak_user_{Guid.NewGuid():N}",
            $"{Guid.NewGuid():N}@example.com",
            "Streak User");
    }

    private static Activity CreateActivity(
        Guid userId,
        DateTime startedAt)
    {
        return new Activity(
            userId,
            "Run",
            5,
            1800,
            300,
            startedAt);
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

        public DbSet<RefreshToken> RefreshTokens =>
            Set<RefreshToken>();

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

            modelBuilder.Entity<ActivityPoint>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Goal>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Follow>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Comment>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<PaceUp.Domain.Entities.Kudos>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<PasswordResetToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<RefreshToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Notification>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Challenge>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<ChallengeParticipant>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Achievement>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<UserAchievement>()
                .HasKey(x => x.Id);
        }
    }
}