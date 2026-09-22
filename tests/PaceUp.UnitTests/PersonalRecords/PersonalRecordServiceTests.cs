using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Features.PersonalRecords;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.PersonalRecords;

public class PersonalRecordServiceTests
{
    [Fact]
    public async Task GetAsync_ShouldReturnNullRecords_WhenUserHasNoActivities()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "record_user",
            "record@example.com",
            "Record User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Null(result.LongestDistanceKm);
        Assert.Null(result.LongestDurationSeconds);
        Assert.Null(result.FastestSpeedKmh);
        Assert.Null(result.FastestPaceSecondsPerKm);
        Assert.Null(result.MostCalories);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnLongestDistance()
    {
        await using var db = CreateDatabase();

        var user = CreateUser(db);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)),
            new Activity(
                user.Id,
                "Run",
                12,
                3600,
                700,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(12, result.LongestDistanceKm);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnLongestDuration()
    {
        await using var db = CreateDatabase();

        var user = CreateUser(db);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)),
            new Activity(
                user.Id,
                "Run",
                8,
                4200,
                500,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(
            4200,
            result.LongestDurationSeconds);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnMostCalories()
    {
        await using var db = CreateDatabase();

        var user = CreateUser(db);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)),
            new Activity(
                user.Id,
                "Run",
                8,
                3600,
                750,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(
            750,
            result.MostCalories);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnFastestPace()
    {
        await using var db = CreateDatabase();

        var user = CreateUser(db);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)),
            new Activity(
                user.Id,
                "Run",
                5,
                1500,
                300,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(
            300,
            result.FastestPaceSecondsPerKm);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnFastestGpsSpeed()
    {
        await using var db = CreateDatabase();

        var user = CreateUser(db);

        var activity = new Activity(
            user.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        db.Activities.Add(activity);
        await db.SaveChangesAsync();

        db.ActivityPoints.AddRange(
            new ActivityPoint(
                activity.Id,
                3.1390,
                101.6869,
                null,
                null,
                2.0,
                null,
                DateTime.UtcNow),

            new ActivityPoint(
                activity.Id,
                3.1400,
                101.6879,
                null,
                null,
                4.0,
                null,
                DateTime.UtcNow.AddSeconds(10)));

        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(
            14.4,
            result.FastestSpeedKmh);
    }

    [Fact]
    public async Task GetAsync_ShouldOnlyUseCurrentUsersActivities()
    {
        await using var db = CreateDatabase();

        var user = CreateUser(db);

        var otherUser = new User(
            "other_user",
            "other@example.com",
            "Other User");

        db.Users.Add(otherUser);
        await db.SaveChangesAsync();

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow));

        db.Activities.Add(
            new Activity(
                otherUser.Id,
                "Run",
                100,
                10000,
                5000,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new PersonalRecordService(db);

        var result = await service.GetAsync(
            user.Id,
            CancellationToken.None);

        Assert.Equal(5, result.LongestDistanceKm);
        Assert.Equal(1800, result.LongestDurationSeconds);
        Assert.Equal(300, result.MostCalories);
    }

    private static User CreateUser(
        TestDbContext db)
    {
        var user = new User(
            "record_user_" + Guid.NewGuid().ToString("N"),
            Guid.NewGuid() + "@example.com",
            "Record User");

        db.Users.Add(user);

        return user;
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

    private sealed class TestDbContext : DbContext, IApplicationDbContext
    {
        public TestDbContext(
            DbContextOptions<TestDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users => Set<User>();

        public DbSet<UserIdentity> UserIdentities =>
            Set<UserIdentity>();

        public DbSet<Activity> Activities =>
            Set<Activity>();

        public DbSet<ActivityPoint> ActivityPoints =>
            Set<ActivityPoint>();

        public DbSet<Goal> Goals => Set<Goal>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<RefreshToken> RefreshTokens =>
            Set<RefreshToken>();

        public DbSet<Notification> Notifications =>
            Set<Notification>();

        public DbSet<Follow> Follows =>
            Set<Follow>();

        public DbSet<PaceUp.Domain.Entities.Kudos> Kudos =>
            Set<PaceUp.Domain.Entities.Kudos>();

        public DbSet<Comment> Comments =>
            Set<Comment>();

        public DbSet<Challenge> Challenges =>
            Set<Challenge>();

        public DbSet<ChallengeParticipant> ChallengeParticipants =>
            Set<ChallengeParticipant>();

        public DbSet<Achievement> Achievements =>
            Set<Achievement>();

        public DbSet<UserAchievement> UserAchievements =>
            Set<UserAchievement>();

        public DbSet<UserGamification> UserGamifications =>
            Set<UserGamification>();

        public DbSet<XpTransaction> XpTransactions =>
            Set<XpTransaction>();

        public override Task<int> SaveChangesAsync(
            CancellationToken cancellationToken = default)
        {
            return base.SaveChangesAsync(cancellationToken);
        }

        protected override void OnModelCreating(
            ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.ApplyConfigurationsFromAssembly(
                typeof(PaceUp.Infrastructure.Persistence.PaceUpDbContext)
                    .Assembly);
        }
    }
}