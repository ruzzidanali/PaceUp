using Microsoft.EntityFrameworkCore;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.Features.Activities;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Activities;

public class ActivityServiceTests
{

    [Fact]
    public async Task GetStatsAsync_ShouldReturnCorrectStatistics()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "stats_user",
            "stats@example.com",
            "Stats User");

        db.Users.Add(user);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)),

            new Activity(
                user.Id,
                "Ride",
                20.0,
                3600,
                800,
                DateTime.UtcNow.AddDays(-1)),

            new Activity(
                user.Id,
                "Walk",
                3.5,
                2400,
                null,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var result =
            await service.GetStatsAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            3,
            result.TotalActivities);

        Assert.Equal(
            28.5,
            result.TotalDistance);

        Assert.Equal(
            7800,
            result.TotalDurationSeconds);

        Assert.Equal(
            1100,
            result.TotalCalories);
    }

    [Fact]
    public async Task GetStatsAsync_ShouldOnlyIncludeUsersActivities()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "stats_user",
            "stats@example.com",
            "Stats User");

        var otherUser = new User(
            "other_stats_user",
            "other_stats@example.com",
            "Other Stats User");

        db.Users.AddRange(
            user,
            otherUser);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow),

            new Activity(
                otherUser.Id,
                "Run",
                100.0,
                10000,
                5000,
                DateTime.UtcNow));

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var result =
            await service.GetStatsAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            1,
            result.TotalActivities);

        Assert.Equal(
            5.0,
            result.TotalDistance);

        Assert.Equal(
            1800,
            result.TotalDurationSeconds);

        Assert.Equal(
            300,
            result.TotalCalories);
    }

    [Fact]
    public async Task UpdateAsync_ShouldUpdateOwnActivity()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "update_user",
            "update@example.com",
            "Update User");

        db.Users.Add(user);

        var activity = new Activity(
            user.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow.AddDays(-1));

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var request = new UpdateActivityRequest(
            "Ride",
            25.5,
            4200,
            950,
            DateTime.UtcNow);

        var result =
            await service.UpdateAsync(
                user.Id,
                activity.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal("Ride", result.Type);
        Assert.Equal(25.5, result.Distance);
        Assert.Equal(4200, result.DurationSeconds);
        Assert.Equal(950, result.Calories);

        var saved =
            await db.Activities
                .SingleAsync(x => x.Id == activity.Id);

        Assert.Equal("Ride", saved.Type);
        Assert.Equal(25.5, saved.Distance);
    }

    [Fact]
    public async Task UpdateAsync_ShouldReturnNullForAnotherUsersActivity()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var otherUser = new User(
            "other",
            "other@example.com",
            "Other");

        db.Users.AddRange(
            owner,
            otherUser);

        var activity = new Activity(
            owner.Id,
            "Run",
            10,
            3600,
            700,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var request = new UpdateActivityRequest(
            "Ride",
            50,
            7200,
            1500,
            DateTime.UtcNow);

        var result =
            await service.UpdateAsync(
                otherUser.Id,
                activity.Id,
                request,
                CancellationToken.None);

        Assert.Null(result);

        var saved =
            await db.Activities
                .SingleAsync(x => x.Id == activity.Id);

        Assert.Equal("Run", saved.Type);
        Assert.Equal(10, saved.Distance);
    }

    [Fact]
    public async Task UpdateAsync_ShouldReturnNullForNonexistentActivity()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "update_user",
            "update@example.com",
            "Update User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var request = new UpdateActivityRequest(
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        var result =
            await service.UpdateAsync(
                user.Id,
                Guid.NewGuid(),
                request,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task DeleteAsync_ShouldDeleteOwnActivity()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "delete_user",
            "delete@example.com",
            "Delete User");

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

        var service = new ActivityService(db);

        var result =
            await service.DeleteAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.True(result);

        var deleted =
            await db.Activities
                .FirstOrDefaultAsync(
                    x => x.Id == activity.Id);

        Assert.Null(deleted);
    }

    [Fact]
    public async Task DeleteAsync_ShouldReturnFalseForAnotherUsersActivity()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var otherUser = new User(
            "other",
            "other@example.com",
            "Other");

        db.Users.AddRange(
            owner,
            otherUser);

        var activity = new Activity(
            owner.Id,
            "Run",
            10,
            3600,
            700,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var result =
            await service.DeleteAsync(
                otherUser.Id,
                activity.Id,
                CancellationToken.None);

        Assert.False(result);

        var existing =
            await db.Activities
                .SingleOrDefaultAsync(
                    x => x.Id == activity.Id);

        Assert.NotNull(existing);
    }

    [Fact]
    public async Task DeleteAsync_ShouldReturnFalseForNonexistentActivity()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "delete_user",
            "delete@example.com",
            "Delete User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var result =
            await service.DeleteAsync(
                user.Id,
                Guid.NewGuid(),
                CancellationToken.None);

        Assert.False(result);
    }

    [Fact]
    public async Task CreateAsync_ShouldCreateActivity()
    {
        await using var db = CreateDatabase();

        var service = new ActivityService(db);

        var user = new User(
            "activity_user",
            "activity@example.com",
            "Activity User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var request = new CreateActivityRequest(
            "Run",
            5.42,
            1938,
            412,
            new DateTime(
                2026,
                8,
                14,
                7,
                30,
                0,
                DateTimeKind.Utc));

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
            result.UserId);

        Assert.Equal(
            "Run",
            result.Type);

        Assert.Equal(
            5.42,
            result.Distance);

        Assert.Equal(
            1938,
            result.DurationSeconds);

        Assert.Equal(
            412,
            result.Calories);

        var savedActivity =
            await db.Activities
                .SingleAsync(
                    x => x.Id == result.Id);

        Assert.Equal(
            user.Id,
            savedActivity.UserId);
    }

    [Fact]
    public async Task GetByIdAsync_ShouldReturnActivityOwnedByUser()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "owner",
            "owner@example.com",
            "Owner");

        db.Users.Add(user);

        var activity = new Activity(
            user.Id,
            "Run",
            10,
            3600,
            700,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var result =
            await service.GetByIdAsync(
                user.Id,
                activity.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            activity.Id,
            result.Id);

        Assert.Equal(
            user.Id,
            result.UserId);
    }

    [Fact]
    public async Task GetByIdAsync_ShouldReturnNullForActivityOwnedByAnotherUser()
    {
        await using var db = CreateDatabase();

        var owner = new User(
            "owner",
            "owner@example.com",
            "Owner");

        var otherUser = new User(
            "other",
            "other@example.com",
            "Other");

        db.Users.AddRange(
            owner,
            otherUser);

        var activity = new Activity(
            owner.Id,
            "Run",
            10,
            3600,
            700,
            DateTime.UtcNow);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var result =
            await service.GetByIdAsync(
                otherUser.Id,
                activity.Id,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetUserActivitiesAsync_ShouldReturnOnlyUsersActivities()
    {
        await using var db = CreateDatabase();

        var user = new User(
            "user",
            "user@example.com",
            "User");

        var otherUser = new User(
            "other",
            "other@example.com",
            "Other");

        db.Users.AddRange(
            user,
            otherUser);

        var firstActivity = new Activity(
            user.Id,
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow.AddDays(-2));

        var secondActivity = new Activity(
            user.Id,
            "Ride",
            20,
            3600,
            800,
            DateTime.UtcNow.AddDays(-1));

        var otherActivity = new Activity(
            otherUser.Id,
            "Walk",
            3,
            1800,
            150,
            DateTime.UtcNow);

        db.Activities.AddRange(
            firstActivity,
            secondActivity,
            otherActivity);

        await db.SaveChangesAsync();

        var service = new ActivityService(db);

        var results =
            await service.GetUserActivitiesAsync(
                user.Id,
                CancellationToken.None);

        Assert.Equal(
            2,
            results.Count);

        Assert.All(
            results,
            x => Assert.Equal(
                user.Id,
                x.UserId));

        Assert.Equal(
            secondActivity.Id,
            results[0].Id);

        Assert.Equal(
            firstActivity.Id,
            results[1].Id);
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

        protected override void OnModelCreating(
    ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>()
                .HasKey(x => x.Id);

            modelBuilder.Entity<UserIdentity>()
                .HasKey(x => x.UserId);

            modelBuilder.Entity<Activity>()
                .HasKey(x => x.Id);
        }
    }
}