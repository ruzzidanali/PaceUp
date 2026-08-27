using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Notifications;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Challenges;
using PaceUp.Application.Exceptions;
using PaceUp.Application.Features.Challenges;
using PaceUp.Application.Features.Notifications;
using PaceUp.Domain.Constants;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Challenges;

public class ChallengeServiceTests
{
    [Fact]
    public async Task CreateAsync_ShouldCreateChallenge()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "creator",
            "creator@example.com");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var service = CreateService(db);

        var request =
            new CreateChallengeRequest(
                "Run 50 KM",
                "Complete 50 KM.",
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            await service.CreateAsync(
                user.Id,
                request,
                CancellationToken.None);

        Assert.NotEqual(
            Guid.Empty,
            result.Id);

        Assert.Equal(
            user.Id,
            result.CreatedByUserId);

        Assert.Equal(
            "Run 50 KM",
            result.Name);

        Assert.Equal(
            "Distance",
            result.Type);

        Assert.Equal(
            50,
            result.TargetValue);

        Assert.Equal(
            0,
            result.ParticipantCount);

        var saved =
            await db.Challenges
                .SingleAsync();

        Assert.Equal(
            result.Id,
            saved.Id);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnChallenges()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "creator",
            "creator@example.com");

        db.Users.Add(user);

        var first =
            new Challenge(
                user.Id,
                "First Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var second =
            new Challenge(
                user.Id,
                "Second Challenge",
                null,
                "Activities",
                10,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.AddRange(
            first,
            second);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var results =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            2,
            results.Count);

        Assert.Contains(
            results,
            x => x.Id == first.Id);

        Assert.Contains(
            results,
            x => x.Id == second.Id);
    }

    [Fact]
    public async Task GetByIdAsync_ShouldReturnChallenge()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "creator",
            "creator@example.com");

        db.Users.Add(user);

        var challenge =
            new Challenge(
                user.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetByIdAsync(
                user.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            challenge.Id,
            result.Id);

        Assert.Equal(
            "Run Challenge",
            result.Name);

        Assert.Equal(
            0,
            result.ParticipantCount);
    }

    [Fact]
    public async Task GetByIdAsync_WithUnknownChallenge_ShouldReturnNull()
    {
        using var db = CreateDatabase();

        var service = CreateService(db);

        var result =
            await service.GetByIdAsync(
                Guid.NewGuid(),
                Guid.NewGuid(),
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task UpdateAsync_ShouldUpdateChallengeOwnedByUser()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "creator",
            "creator@example.com");

        db.Users.Add(user);

        var challenge =
            new Challenge(
                user.Id,
                "Original",
                "Original description",
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var request =
            new UpdateChallengeRequest(
                "Updated",
                "Updated description",
                "Duration",
                3600,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(10));

        var result =
            await service.UpdateAsync(
                user.Id,
                challenge.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            "Updated",
            result.Name);

        Assert.Equal(
            "Updated description",
            result.Description);

        Assert.Equal(
            "Duration",
            result.Type);

        Assert.Equal(
            3600,
            result.TargetValue);
    }

    [Fact]
    public async Task UpdateAsync_WhenUserIsNotOwner_ShouldReturnNull()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var otherUser = CreateUser(
            "other",
            "other@example.com");

        db.Users.AddRange(
            owner,
            otherUser);

        var challenge =
            new Challenge(
                owner.Id,
                "Original",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var request =
            new UpdateChallengeRequest(
                "Hacked",
                null,
                "Distance",
                100,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            await service.UpdateAsync(
                otherUser.Id,
                challenge.Id,
                request,
                CancellationToken.None);

        Assert.Null(result);

        var saved =
            await db.Challenges
                .SingleAsync();

        Assert.Equal(
            "Original",
            saved.Name);
    }

    [Fact]
    public async Task DeleteAsync_ShouldDeleteChallengeOwnedByUser()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "creator",
            "creator@example.com");

        db.Users.Add(user);

        var challenge =
            new Challenge(
                user.Id,
                "Delete Me",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.DeleteAsync(
                user.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.True(result);

        Assert.Empty(
            await db.Challenges.ToListAsync());
    }

    [Fact]
    public async Task DeleteAsync_WhenUserIsNotOwner_ShouldReturnFalse()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var otherUser = CreateUser(
            "other",
            "other@example.com");

        db.Users.AddRange(
            owner,
            otherUser);

        var challenge =
            new Challenge(
                owner.Id,
                "Keep Me",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.DeleteAsync(
                otherUser.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.False(result);

        Assert.Single(
            await db.Challenges.ToListAsync());
    }

    [Fact]
    public async Task JoinAsync_ShouldCreateParticipant()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var participant = CreateUser(
            "participant",
            "participant@example.com");

        db.Users.AddRange(
            owner,
            participant);

        var challenge =
            new Challenge(
                owner.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.JoinAsync(
                participant.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.True(result);

        var saved =
            await db.ChallengeParticipants
                .SingleAsync();

        Assert.Equal(
            challenge.Id,
            saved.ChallengeId);

        Assert.Equal(
            participant.Id,
            saved.UserId);
    }

    [Fact]
    public async Task JoinAsync_WhenAlreadyJoined_ShouldThrowConflict()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var participant = CreateUser(
            "participant",
            "participant@example.com");

        db.Users.AddRange(
            owner,
            participant);

        var challenge =
            new Challenge(
                owner.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        var existing =
            new ChallengeParticipant(
                challenge.Id,
                participant.Id);

        db.ChallengeParticipants.Add(existing);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        await Assert.ThrowsAsync<ConflictException>(
            () =>
                service.JoinAsync(
                    participant.Id,
                    challenge.Id,
                    CancellationToken.None));
    }

    [Fact]
    public async Task JoinAsync_WhenChallengeEnded_ShouldThrowConflict()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var participant = CreateUser(
            "participant",
            "participant@example.com");

        db.Users.AddRange(
            owner,
            participant);

        var startDate =
            DateTime.UtcNow.Date.AddDays(-10);

        var endDate =
            DateTime.UtcNow.Date.AddDays(-1);

        var challenge =
            new Challenge(
                owner.Id,
                "Ended Challenge",
                null,
                "Distance",
                50,
                startDate,
                endDate);

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        await Assert.ThrowsAsync<ConflictException>(
            () =>
                service.JoinAsync(
                    participant.Id,
                    challenge.Id,
                    CancellationToken.None));
    }

    [Fact]
    public async Task JoinAsync_WithUnknownChallenge_ShouldReturnFalse()
    {
        using var db = CreateDatabase();

        var service = CreateService(db);

        var result =
            await service.JoinAsync(
                Guid.NewGuid(),
                Guid.NewGuid(),
                CancellationToken.None);

        Assert.False(result);
    }

    [Fact]
    public async Task LeaveAsync_ShouldRemoveParticipant()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var participant = CreateUser(
            "participant",
            "participant@example.com");

        db.Users.AddRange(
            owner,
            participant);

        var challenge =
            new Challenge(
                owner.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        var membership =
            new ChallengeParticipant(
                challenge.Id,
                participant.Id);

        db.ChallengeParticipants.Add(membership);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.LeaveAsync(
                participant.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.True(result);

        Assert.Empty(
            await db.ChallengeParticipants.ToListAsync());
    }

    [Fact]
    public async Task LeaveAsync_WhenNotParticipant_ShouldReturnFalse()
    {
        using var db = CreateDatabase();

        var service = CreateService(db);

        var result =
            await service.LeaveAsync(
                Guid.NewGuid(),
                Guid.NewGuid(),
                CancellationToken.None);

        Assert.False(result);
    }

    [Fact]
    public async Task GetProgressAsync_ShouldCalculateDistanceProgress()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "runner",
            "runner@example.com");

        db.Users.Add(user);

        var startDate =
            DateTime.UtcNow.Date;

        var endDate =
            startDate.AddDays(6);

        var challenge =
            new Challenge(
                user.Id,
                "50 KM Challenge",
                null,
                "Distance",
                50,
                startDate,
                endDate);

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.Add(
            new ChallengeParticipant(
                challenge.Id,
                user.Id));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                10,
                3600,
                500,
                startDate.AddDays(1)));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                15,
                5400,
                700,
                startDate.AddDays(2)));

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetProgressAsync(
                user.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            25,
            result.CurrentValue);

        Assert.Equal(
            25,
            result.RemainingValue);

        Assert.Equal(
            50,
            result.ProgressPercentage);

        Assert.False(
            result.IsCompleted);
    }

    [Fact]
    public async Task GetProgressAsync_ShouldCalculateDurationProgress()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "runner",
            "runner@example.com");

        db.Users.Add(user);

        var startDate =
            DateTime.UtcNow.Date;

        var challenge =
            new Challenge(
                user.Id,
                "One Hour Challenge",
                null,
                "Duration",
                3600,
                startDate,
                startDate.AddDays(6));

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.Add(
            new ChallengeParticipant(
                challenge.Id,
                user.Id));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                startDate.AddDays(1)));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Walk",
                3,
                1200,
                150,
                startDate.AddDays(2)));

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetProgressAsync(
                user.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            3000,
            result.CurrentValue);

        Assert.Equal(
            600,
            result.RemainingValue);

        Assert.Equal(
            (3000d / 3600d) * 100,
            result.ProgressPercentage);

        Assert.False(
            result.IsCompleted);
    }

    [Fact]
    public async Task GetProgressAsync_ShouldCalculateActivityCount()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "runner",
            "runner@example.com");

        db.Users.Add(user);

        var startDate =
            DateTime.UtcNow.Date;

        var challenge =
            new Challenge(
                user.Id,
                "10 Activities",
                null,
                "Activities",
                10,
                startDate,
                startDate.AddDays(6));

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.Add(
            new ChallengeParticipant(
                challenge.Id,
                user.Id));

        for (var i = 0; i < 4; i++)
        {
            db.Activities.Add(
                new Activity(
                    user.Id,
                    "Run",
                    5,
                    1800,
                    300,
                    startDate.AddDays(i)));
        }

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetProgressAsync(
                user.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            4,
            result.CurrentValue);

        Assert.Equal(
            6,
            result.RemainingValue);

        Assert.Equal(
            40,
            result.ProgressPercentage);

        Assert.False(
            result.IsCompleted);
    }

    [Fact]
    public async Task GetProgressAsync_WhenCompleted_ShouldCapProgressAt100()
    {
        using var db = CreateDatabase();

        var user = CreateUser(
            "runner",
            "runner@example.com");

        db.Users.Add(user);

        var startDate =
            DateTime.UtcNow.Date;

        var challenge =
            new Challenge(
                user.Id,
                "10 KM Challenge",
                null,
                "Distance",
                10,
                startDate,
                startDate.AddDays(6));

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.Add(
            new ChallengeParticipant(
                challenge.Id,
                user.Id));

        db.Activities.Add(
            new Activity(
                user.Id,
                "Run",
                15,
                3600,
                800,
                startDate.AddDays(1)));

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetProgressAsync(
                user.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            15,
            result.CurrentValue);

        Assert.Equal(
            0,
            result.RemainingValue);

        Assert.Equal(
            100,
            result.ProgressPercentage);

        Assert.True(
            result.IsCompleted);
    }

    [Fact]
    public async Task GetProgressAsync_WhenUserIsNotParticipant_ShouldReturnNull()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var otherUser = CreateUser(
            "other",
            "other@example.com");

        db.Users.AddRange(
            owner,
            otherUser);

        var challenge =
            new Challenge(
                owner.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetProgressAsync(
                otherUser.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetLeaderboardAsync_ShouldRankParticipantsByValue()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var first =
            CreateUser(
                "first",
                "first@example.com");

        var second =
            CreateUser(
                "second",
                "second@example.com");

        db.Users.AddRange(
            owner,
            first,
            second);

        var startDate =
            DateTime.UtcNow.Date;

        var challenge =
            new Challenge(
                owner.Id,
                "50 KM Challenge",
                null,
                "Distance",
                50,
                startDate,
                startDate.AddDays(6));

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.AddRange(
            new ChallengeParticipant(
                challenge.Id,
                owner.Id),

            new ChallengeParticipant(
                challenge.Id,
                first.Id),

            new ChallengeParticipant(
                challenge.Id,
                second.Id));

        db.Activities.AddRange(
            new Activity(
                owner.Id,
                "Run",
                10,
                1800,
                300,
                startDate.AddDays(1)),

            new Activity(
                first.Id,
                "Run",
                30,
                3600,
                700,
                startDate.AddDays(1)),

            new Activity(
                second.Id,
                "Run",
                20,
                2400,
                500,
                startDate.AddDays(1)));

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetLeaderboardAsync(
                owner.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            3,
            result.Participants.Count);

        Assert.Equal(
            first.Id,
            result.Participants[0].UserId);

        Assert.Equal(
            30,
            result.Participants[0].CurrentValue);

        Assert.Equal(
            1,
            result.Participants[0].Rank);

        Assert.Equal(
            second.Id,
            result.Participants[1].UserId);

        Assert.Equal(
            20,
            result.Participants[1].CurrentValue);

        Assert.Equal(
            2,
            result.Participants[1].Rank);

        Assert.Equal(
            owner.Id,
            result.Participants[2].UserId);

        Assert.Equal(
            10,
            result.Participants[2].CurrentValue);

        Assert.Equal(
            3,
            result.Participants[2].Rank);
    }

    [Fact]
    public async Task GetLeaderboardAsync_WhenUserIsNotParticipant_ShouldReturnNull()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        var otherUser = CreateUser(
            "other",
            "other@example.com");

        db.Users.AddRange(
            owner,
            otherUser);

        var challenge =
            new Challenge(
                owner.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.Add(
            new ChallengeParticipant(
                challenge.Id,
                owner.Id));

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetLeaderboardAsync(
                otherUser.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetLeaderboardAsync_WithNoActivity_ShouldRankParticipantWithZero()
    {
        using var db = CreateDatabase();

        var owner = CreateUser(
            "owner",
            "owner@example.com");

        db.Users.Add(owner);

        var challenge =
            new Challenge(
                owner.Id,
                "Run Challenge",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        db.Challenges.Add(challenge);

        db.ChallengeParticipants.Add(
            new ChallengeParticipant(
                challenge.Id,
                owner.Id));

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.GetLeaderboardAsync(
                owner.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Single(
            result.Participants);

        Assert.Equal(
            0,
            result.Participants[0].CurrentValue);

        Assert.Equal(
            1,
            result.Participants[0].Rank);
    }

    private static User CreateUser(
        string username,
        string email)
    {
        return new User(
            username,
            email,
            username);
    }

    [Fact]
    public async Task JoinAsync_ShouldCreateNotificationForChallengeCreator()
    {
        using var db = CreateDatabase();

        var creator = new User(
            "challenge_creator",
            "creator@example.com",
            "Challenge Creator");

        var participant = new User(
            "challenge_participant",
            "participant@example.com",
            "Challenge Participant");

        db.Users.AddRange(
            creator,
            participant);

        await db.SaveChangesAsync();

        var challenge = new Challenge(
            creator.Id,
            "Join Challenge",
            "Join this challenge.",
            ChallengeTypes.Distance,
            50,
            DateTime.UtcNow.AddDays(-1),
            DateTime.UtcNow.AddDays(7));

        db.Challenges.Add(challenge);

        await db.SaveChangesAsync();

        var service = CreateService(db);

        var result =
            await service.JoinAsync(
                participant.Id,
                challenge.Id,
                CancellationToken.None);

        Assert.True(result);

        var notification =
            await db.Notifications
                .SingleOrDefaultAsync(
                    x =>
                        x.RecipientUserId == creator.Id &&
                        x.ActorUserId == participant.Id &&
                        x.Type == NotificationTypes.ChallengeJoined);

        Assert.NotNull(notification);

        Assert.False(notification.IsRead);
    }

    [Fact]
public async Task JoinAsync_ShouldNotCreateNotificationWhenJoiningOwnChallenge()
{
    using var db = CreateDatabase();

    var creator = new User(
        "challenge_owner",
        "owner@example.com",
        "Challenge Owner");

    db.Users.Add(creator);

    await db.SaveChangesAsync();

    var challenge = new Challenge(
        creator.Id,
        "Own Challenge",
        "My own challenge.",
        ChallengeTypes.Distance,
        50,
        DateTime.UtcNow.AddDays(-1),
        DateTime.UtcNow.AddDays(7));

    db.Challenges.Add(challenge);

    await db.SaveChangesAsync();

    var service = CreateService(db);

    var result =
        await service.JoinAsync(
            creator.Id,
            challenge.Id,
            CancellationToken.None);

    Assert.True(result);

    var notifications =
        await db.Notifications
            .Where(
                x =>
                    x.RecipientUserId == creator.Id)
            .ToListAsync();

    Assert.Empty(notifications);
}

    private static ChallengeService CreateService(
    TestDbContext db)
    {
        var notificationService =
            new NotificationService(db);

        return new ChallengeService(
            db,
            notificationService);
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

        public DbSet<Challenge> Challenges =>
            Set<Challenge>();

        public DbSet<ChallengeParticipant> ChallengeParticipants =>
            Set<ChallengeParticipant>();

        public DbSet<Follow> Follows =>
            Set<Follow>();

        public DbSet<Notification> Notifications =>
            Set<Notification>();

        public DbSet<EmailVerificationToken>
            EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken>
            PasswordResetTokens =>
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

            modelBuilder.Entity<Goal>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Challenge>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<ChallengeParticipant>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<PasswordResetToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<RefreshToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Notification>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Follow>()
                .HasKey(x => x.Id);
        }
    }
}