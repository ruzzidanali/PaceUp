using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Features.Xp;
using PaceUp.Domain.Entities;
using PaceUp.Domain.Constants;

namespace PaceUp.UnitTests.Xp;

public class XpServiceTests
{
    [Fact]
    public async Task AwardActivityXpAsync_ShouldCreateGamificationAndAwardXp()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var activity = CreateActivity(user.Id);
        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new XpService(db);

        await service.AwardActivityXpAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        var gamification =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            user.Id,
            gamification.UserId);

        Assert.Equal(
            10,
            gamification.TotalXp);

        Assert.Equal(
            1,
            gamification.Level);

        var transaction =
            await db.XpTransactions
                .SingleAsync();

        Assert.Equal(
            user.Id,
            transaction.UserId);

        Assert.Equal(
            10,
            transaction.Amount);

        Assert.Equal(
            "Activity",
            transaction.SourceType);

        Assert.Equal(
            activity.Id,
            transaction.SourceId);
    }

    [Fact]
    public async Task AwardActivityXpAsync_ShouldIncreaseExistingXp()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var activity = CreateActivity(user.Id);
        db.Activities.Add(activity);

        var gamification =
            new UserGamification(user.Id);

        gamification.AddXp(90);

        db.UserGamifications.Add(gamification);

        await db.SaveChangesAsync();

        var service = new XpService(db);

        await service.AwardActivityXpAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        var saved =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            100,
            saved.TotalXp);

        Assert.Equal(
            2,
            saved.Level);

        Assert.Single(
            await db.XpTransactions.ToListAsync());
    }

    [Fact]
    public async Task AwardActivityXpAsync_ShouldNotDuplicateXpForSameActivity()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var activity = CreateActivity(user.Id);
        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new XpService(db);

        await service.AwardActivityXpAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        await service.AwardActivityXpAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        var gamification =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            10,
            gamification.TotalXp);

        Assert.Equal(
            1,
            gamification.Level);

        Assert.Single(
            await db.XpTransactions.ToListAsync());
    }

    [Fact]
    public async Task AwardActivityXpAsync_ShouldAwardXpForDifferentActivities()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var firstActivity =
            CreateActivity(
                user.Id,
                DateTime.UtcNow.AddDays(-1));

        var secondActivity =
            CreateActivity(
                user.Id,
                DateTime.UtcNow);

        db.Activities.AddRange(
            firstActivity,
            secondActivity);

        await db.SaveChangesAsync();

        var service = new XpService(db);

        await service.AwardActivityXpAsync(
            user.Id,
            firstActivity.Id,
            CancellationToken.None);

        await service.AwardActivityXpAsync(
            user.Id,
            secondActivity.Id,
            CancellationToken.None);

        var gamification =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            20,
            gamification.TotalXp);

        Assert.Equal(
            1,
            gamification.Level);

        Assert.Equal(
            2,
            await db.XpTransactions.CountAsync());
    }

    [Fact]
    public async Task AwardActivityXpAsync_ShouldNotCreateGamificationWhenAlreadyAwarded()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        var activity = CreateActivity(user.Id);
        db.Activities.Add(activity);

        var gamification =
            new UserGamification(user.Id);

        gamification.AddXp(100);

        db.UserGamifications.Add(gamification);

        db.XpTransactions.Add(
            new XpTransaction(
                user.Id,
                10,
                "Activity",
                activity.Id));

        await db.SaveChangesAsync();

        var service = new XpService(db);

        await service.AwardActivityXpAsync(
            user.Id,
            activity.Id,
            CancellationToken.None);

        var saved =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            100,
            saved.TotalXp);

        Assert.Equal(
            2,
            saved.Level);

        Assert.Single(
            await db.XpTransactions.ToListAsync());
    }

    private static User CreateUser()
    {
        return new User(
            "xp_user",
            "xp@example.com",
            "XP User");
    }

    private static Activity CreateActivity(
        Guid userId,
        DateTime? startedAt = null)
    {
        return new Activity(
            userId,
            "Run",
            5,
            1800,
            300,
            startedAt ?? DateTime.UtcNow);
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

        public DbSet<ActivityPoint> ActivityPoints =>
            Set<ActivityPoint>();

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

        public DbSet<Notification> Notifications =>
            Set<Notification>();

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

        protected override void OnModelCreating(
            ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.ApplyConfigurationsFromAssembly(
                typeof(PaceUp.Infrastructure.Persistence.PaceUpDbContext)
                    .Assembly);
        }
    }

    [Fact]
    public async Task AwardChallengeXpAsync_FirstCompletion_CreatesGamificationAndAwards50Xp()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        await db.SaveChangesAsync();

        var challengeId = Guid.NewGuid();

        var service = new XpService(db);

        await service.AwardChallengeXpAsync(
            user.Id,
            challengeId,
            CancellationToken.None);

        var gamification =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            user.Id,
            gamification.UserId);

        Assert.Equal(
            50,
            gamification.TotalXp);

        Assert.Equal(
            1,
            gamification.Level);

        var transaction =
            await db.XpTransactions
                .SingleAsync();

        Assert.Equal(
            user.Id,
            transaction.UserId);

        Assert.Equal(
            50,
            transaction.Amount);

        Assert.Equal(
            XpSourceTypes.Challenge,
            transaction.SourceType);

        Assert.Equal(
            challengeId,
            transaction.SourceId);
    }

    [Fact]
    public async Task AwardChallengeXpAsync_SameChallengeTwice_DoesNotDuplicateXp()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        await db.SaveChangesAsync();

        var challengeId = Guid.NewGuid();

        var service = new XpService(db);

        await service.AwardChallengeXpAsync(
            user.Id,
            challengeId,
            CancellationToken.None);

        await service.AwardChallengeXpAsync(
            user.Id,
            challengeId,
            CancellationToken.None);

        var gamification =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            50,
            gamification.TotalXp);

        Assert.Equal(
            1,
            gamification.Level);

        var transactions =
            await db.XpTransactions
                .Where(x =>
                    x.UserId == user.Id &&
                    x.SourceType == XpSourceTypes.Challenge &&
                    x.SourceId == challengeId)
                .ToListAsync();

        Assert.Single(transactions);
    }

    [Fact]
    public async Task AwardChallengeXpAsync_DifferentChallenges_AwardsXpForEach()
    {
        await using var db = CreateDatabase();

        var user = CreateUser();
        db.Users.Add(user);

        await db.SaveChangesAsync();

        var firstChallengeId = Guid.NewGuid();
        var secondChallengeId = Guid.NewGuid();

        var service = new XpService(db);

        await service.AwardChallengeXpAsync(
            user.Id,
            firstChallengeId,
            CancellationToken.None);

        await service.AwardChallengeXpAsync(
            user.Id,
            secondChallengeId,
            CancellationToken.None);

        var gamification =
            await db.UserGamifications
                .SingleAsync();

        Assert.Equal(
            100,
            gamification.TotalXp);

        Assert.Equal(
            2,
            gamification.Level);

        var transactions =
            await db.XpTransactions
                .Where(x =>
                    x.UserId == user.Id &&
                    x.SourceType == XpSourceTypes.Challenge)
                .ToListAsync();

        Assert.Equal(
            2,
            transactions.Count);

        Assert.All(
            transactions,
            transaction =>
                Assert.Equal(
                    50,
                    transaction.Amount));
    }
}