using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Features.Notifications;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Notifications;

public class NotificationServiceTests
{
    [Fact]
    public async Task GetAsync_ShouldReturnUserNotifications()
    {
        await using var db = CreateDatabase();

        var recipient =
            new User(
                "recipient",
                "recipient@example.com",
                "Recipient");

        var actor =
            new User(
                "actor",
                "actor@example.com",
                "Actor");

        db.Users.AddRange(recipient, actor);

        var notification =
            new Notification(
                recipient.Id,
                actor.Id,
                "NewFollower");

        db.Notifications.Add(notification);

        await db.SaveChangesAsync();

        var service =
            new NotificationService(db);

        var result =
            await service.GetAsync(
                recipient.Id,
                CancellationToken.None);

        Assert.Single(result);

        var item = result[0];

        Assert.Equal(
            notification.Id,
            item.Id);

        Assert.Equal(
            "NewFollower",
            item.Type);

        Assert.False(item.IsRead);

        Assert.Equal(
            actor.Id,
            item.ActorUserId);

        Assert.Equal(
            "actor",
            item.ActorUsername);

        Assert.Equal(
            "Actor",
            item.ActorDisplayName);
    }

    [Fact]
    public async Task GetAsync_ShouldNotReturnOtherUsersNotifications()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user",
                "user@example.com",
                "User");

        var otherUser =
            new User(
                "other",
                "other@example.com",
                "Other");

        var actor =
            new User(
                "actor",
                "actor@example.com",
                "Actor");

        db.Users.AddRange(
            user,
            otherUser,
            actor);

        db.Notifications.AddRange(
            new Notification(
                user.Id,
                actor.Id,
                "NewFollower"),
            new Notification(
                otherUser.Id,
                actor.Id,
                "NewFollower"));

        await db.SaveChangesAsync();

        var service =
            new NotificationService(db);

        var result =
            await service.GetAsync(
                user.Id,
                CancellationToken.None);

        Assert.Single(result);

        Assert.Equal(
            user.Id,
            (await db.Notifications.SingleAsync(
                x => x.Id == result[0].Id)).RecipientUserId);
    }

    [Fact]
    public async Task MarkAsReadAsync_ShouldMarkNotificationAsRead()
    {
        await using var db = CreateDatabase();

        var recipient =
            new User(
                "recipient",
                "recipient@example.com",
                "Recipient");

        var actor =
            new User(
                "actor",
                "actor@example.com",
                "Actor");

        db.Users.AddRange(
            recipient,
            actor);

        var notification =
            new Notification(
                recipient.Id,
                actor.Id,
                "NewFollower");

        db.Notifications.Add(notification);

        await db.SaveChangesAsync();

        var service =
            new NotificationService(db);

        var result =
            await service.MarkAsReadAsync(
                recipient.Id,
                notification.Id,
                CancellationToken.None);

        Assert.True(result);

        var saved =
            await db.Notifications
                .SingleAsync(
                    x => x.Id == notification.Id);

        Assert.True(saved.IsRead);
    }

    [Fact]
    public async Task MarkAsReadAsync_WhenNotificationBelongsToAnotherUser_ShouldReturnFalse()
    {
        await using var db = CreateDatabase();

        var owner =
            new User(
                "owner",
                "owner@example.com",
                "Owner");

        var otherUser =
            new User(
                "other",
                "other@example.com",
                "Other");

        var actor =
            new User(
                "actor",
                "actor@example.com",
                "Actor");

        db.Users.AddRange(
            owner,
            otherUser,
            actor);

        var notification =
            new Notification(
                owner.Id,
                actor.Id,
                "NewFollower");

        db.Notifications.Add(notification);

        await db.SaveChangesAsync();

        var service =
            new NotificationService(db);

        var result =
            await service.MarkAsReadAsync(
                otherUser.Id,
                notification.Id,
                CancellationToken.None);

        Assert.False(result);

        var saved =
            await db.Notifications
                .SingleAsync(
                    x => x.Id == notification.Id);

        Assert.False(saved.IsRead);
    }

    [Fact]
    public async Task MarkAsReadAsync_WhenNotificationDoesNotExist_ShouldReturnFalse()
    {
        await using var db = CreateDatabase();

        var service =
            new NotificationService(db);

        var result =
            await service.MarkAsReadAsync(
                Guid.NewGuid(),
                Guid.NewGuid(),
                CancellationToken.None);

        Assert.False(result);
    }

    [Fact]
    public async Task MarkAllAsReadAsync_ShouldOnlyMarkCurrentUsersNotifications()
    {
        await using var db = CreateDatabase();

        var user =
            new User(
                "user",
                "user@example.com",
                "User");

        var otherUser =
            new User(
                "other",
                "other@example.com",
                "Other");

        var actor =
            new User(
                "actor",
                "actor@example.com",
                "Actor");

        db.Users.AddRange(
            user,
            otherUser,
            actor);

        var userNotification1 =
            new Notification(
                user.Id,
                actor.Id,
                "NewFollower");

        var userNotification2 =
            new Notification(
                user.Id,
                actor.Id,
                "NewFollower");

        var otherNotification =
            new Notification(
                otherUser.Id,
                actor.Id,
                "NewFollower");

        db.Notifications.AddRange(
            userNotification1,
            userNotification2,
            otherNotification);

        await db.SaveChangesAsync();

        var service =
            new NotificationService(db);

        await service.MarkAllAsReadAsync(
            user.Id,
            CancellationToken.None);

        Assert.True(
            (await db.Notifications
                .SingleAsync(
                    x => x.Id == userNotification1.Id))
                .IsRead);

        Assert.True(
            (await db.Notifications
                .SingleAsync(
                    x => x.Id == userNotification2.Id))
                .IsRead);

        Assert.False(
            (await db.Notifications
                .SingleAsync(
                    x => x.Id == otherNotification.Id))
                .IsRead);
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

    private sealed class TestDbContext
        : DbContext,
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

        public DbSet<PaceUp.Domain.Entities.Kudos> Kudos =>
            Set<PaceUp.Domain.Entities.Kudos>();

        public DbSet<Goal> Goals =>
            Set<Goal>();

        public DbSet<Follow> Follows =>
            Set<Follow>();

        public DbSet<Notification> Notifications =>
            Set<Notification>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<RefreshToken> RefreshTokens =>
            Set<RefreshToken>();

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

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<PasswordResetToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<RefreshToken>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Goal>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Follow>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<Notification>()
                .HasKey(x => x.Id);
        }
    }
}