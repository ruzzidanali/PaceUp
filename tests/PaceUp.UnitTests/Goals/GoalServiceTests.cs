using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Goals;
using PaceUp.Application.Features.Goals;
using PaceUp.Domain.Entities;
using PaceUp.Domain.Constants;

namespace PaceUp.UnitTests.Goals;

public class GoalServiceTests
{
    [Fact]
    public async Task CreateAsync_ShouldCreateGoalForUser()
    {
        using var db = CreateDatabase();

        var user = new User(
            "goal_user",
            "goal@example.com",
            "Goal User");

        db.Users.Add(user);
        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var startDate = DateTime.UtcNow.Date;
        var request = new CreateGoalRequest(
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

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
            "Distance",
            result.Type);

        Assert.Equal(
            50,
            result.Target);
    }

    [Fact]
    public async Task GetUserGoalsAsync_ShouldReturnOnlyUsersGoals()
    {
        using var db = CreateDatabase();

        var user = new User(
            "goal_user",
            "goal@example.com",
            "Goal User");

        var otherUser = new User(
            "other_user",
            "other@example.com",
            "Other User");

        db.Users.AddRange(
            user,
            otherUser);

        var startDate = DateTime.UtcNow.Date;

        var ownGoal = new Goal(
            user.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        var otherGoal = new Goal(
            otherUser.Id,
            "Calories",
            3000,
            startDate,
            startDate.AddDays(6));

        db.Goals.AddRange(
            ownGoal,
            otherGoal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var results =
            await service.GetUserGoalsAsync(
                user.Id,
                CancellationToken.None);

        Assert.Single(results);

        Assert.Equal(
            ownGoal.Id,
            results[0].Id);

        Assert.Equal(
            user.Id,
            results[0].UserId);

        Assert.Equal(
            "Distance",
            results[0].Type);
    }

    [Fact]
    public async Task GetByIdAsync_WhenOwnGoalExists_ShouldReturnGoal()
    {
        using var db = CreateDatabase();

        var user = new User(
            "goal_user",
            "goal@example.com",
            "Goal User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;

        var goal = new Goal(
            user.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetByIdAsync(
                user.Id,
                goal.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            goal.Id,
            result.Id);
    }

    [Fact]
    public async Task GetByIdAsync_WhenGoalBelongsToAnotherUser_ShouldReturnNull()
    {
        using var db = CreateDatabase();

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

        var startDate = DateTime.UtcNow.Date;

        var goal = new Goal(
            owner.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetByIdAsync(
                otherUser.Id,
                goal.Id,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task UpdateAsync_ShouldUpdateOwnGoal()
    {
        using var db = CreateDatabase();

        var user = new User(
            "goal_user",
            "goal@example.com",
            "Goal User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;

        var goal = new Goal(
            user.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var request = new UpdateGoalRequest(
            "Calories",
            3000,
            startDate,
            startDate.AddDays(13));

        var result =
            await service.UpdateAsync(
                user.Id,
                goal.Id,
                request,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(
            "Calories",
            result.Type);

        Assert.Equal(
            3000,
            result.Target);

        Assert.Equal(
            startDate.AddDays(13),
            result.EndDate);
    }

    [Fact]
    public async Task UpdateAsync_WhenGoalBelongsToAnotherUser_ShouldReturnNull()
    {
        using var db = CreateDatabase();

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

        var startDate = DateTime.UtcNow.Date;

        var goal = new Goal(
            owner.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var request = new UpdateGoalRequest(
            "Calories",
            3000,
            startDate,
            startDate.AddDays(6));

        var result =
            await service.UpdateAsync(
                otherUser.Id,
                goal.Id,
                request,
                CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task DeleteAsync_ShouldDeleteOwnGoal()
    {
        using var db = CreateDatabase();

        var user = new User(
            "goal_user",
            "goal@example.com",
            "Goal User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;

        var goal = new Goal(
            user.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.DeleteAsync(
                user.Id,
                goal.Id,
                CancellationToken.None);

        Assert.True(result);

        var deletedGoal =
            await db.Goals
                .FindAsync(goal.Id);

        Assert.Null(deletedGoal);
    }

    [Fact]
    public async Task DeleteAsync_WhenGoalBelongsToAnotherUser_ShouldReturnFalse()
    {
        using var db = CreateDatabase();

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

        var startDate = DateTime.UtcNow.Date;

        var goal = new Goal(
            owner.Id,
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.DeleteAsync(
                otherUser.Id,
                goal.Id,
                CancellationToken.None);

        Assert.False(result);

        Assert.NotNull(
            await db.Goals.FindAsync(goal.Id));
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

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);
        }
    }

    [Fact]
    public async Task GetGoalProgressAsync_Distance_ShouldCalculateProgress()
    {
        using var db = CreateDatabase();

        var user = new User(
            "progress_user",
            "progress@example.com",
            "Progress User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            user.Id,
            GoalTypes.Distance,
            50,
            startDate,
            endDate);

        db.Goals.Add(goal);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                10,
                1800,
                300,
                startDate.AddDays(1)),

            new Activity(
                user.Id,
                "Run",
                15,
                2400,
                400,
                startDate.AddDays(3)),

            // Outside goal period; must not count.
            new Activity(
                user.Id,
                "Run",
                100,
                3600,
                1000,
                endDate.AddDays(1)));

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetGoalProgressAsync(
                user.Id,
                goal.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(25, result.Current);
        Assert.Equal(50, result.Target);
        Assert.Equal(25, result.Remaining);
        Assert.Equal(50, result.ProgressPercentage);
        Assert.False(result.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgressAsync_Duration_ShouldCalculateProgress()
    {
        using var db = CreateDatabase();

        var user = new User(
            "duration_user",
            "duration@example.com",
            "Duration User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            user.Id,
            GoalTypes.Duration,
            3600,
            startDate,
            endDate);

        db.Goals.Add(goal);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1200,
                300,
                startDate.AddDays(1)),

            new Activity(
                user.Id,
                "Ride",
                10,
                900,
                400,
                startDate.AddDays(2)));

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetGoalProgressAsync(
                user.Id,
                goal.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(2100, result.Current);
        Assert.Equal(3600, result.Target);
        Assert.Equal(1500, result.Remaining);
        Assert.Equal(
            58.333333333333336,
            result.ProgressPercentage,
            precision: 10);

        Assert.False(result.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgressAsync_Calories_ShouldIgnoreNullCalories()
    {
        using var db = CreateDatabase();

        var user = new User(
            "calorie_user",
            "calorie@example.com",
            "Calorie User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            user.Id,
            GoalTypes.Calories,
            1000,
            startDate,
            endDate);

        db.Goals.Add(goal);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                startDate.AddDays(1)),

            new Activity(
                user.Id,
                "Walk",
                3,
                1200,
                null,
                startDate.AddDays(2)),

            new Activity(
                user.Id,
                "Ride",
                20,
                3600,
                500,
                startDate.AddDays(3)));

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetGoalProgressAsync(
                user.Id,
                goal.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(800, result.Current);
        Assert.Equal(200, result.Remaining);
        Assert.Equal(80, result.ProgressPercentage);
        Assert.False(result.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgressAsync_Activities_ShouldCountActivities()
    {
        using var db = CreateDatabase();

        var user = new User(
            "activity_goal_user",
            "activitygoal@example.com",
            "Activity Goal User");

        db.Users.Add(user);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            user.Id,
            GoalTypes.Activities,
            5,
            startDate,
            endDate);

        db.Goals.Add(goal);

        db.Activities.AddRange(
            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                startDate.AddDays(1)),

            new Activity(
                user.Id,
                "Walk",
                3,
                1200,
                150,
                startDate.AddDays(2)),

            new Activity(
                user.Id,
                "Ride",
                20,
                3600,
                500,
                startDate.AddDays(3)),

            new Activity(
                user.Id,
                "Run",
                5,
                1800,
                300,
                startDate.AddDays(4)),

            new Activity(
                user.Id,
                "Walk",
                2,
                900,
                100,
                startDate.AddDays(5)));

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetGoalProgressAsync(
                user.Id,
                goal.Id,
                CancellationToken.None);

        Assert.NotNull(result);

        Assert.Equal(5, result.Current);
        Assert.Equal(5, result.Target);
        Assert.Equal(0, result.Remaining);
        Assert.Equal(100, result.ProgressPercentage);
        Assert.True(result.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgressAsync_WhenGoalBelongsToAnotherUser_ShouldReturnNull()
    {
        using var db = CreateDatabase();

        var owner = new User(
            "progress_owner",
            "owner@example.com",
            "Owner");

        var otherUser = new User(
            "progress_other",
            "other@example.com",
            "Other");

        db.Users.AddRange(
            owner,
            otherUser);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            owner.Id,
            GoalTypes.Distance,
            50,
            startDate,
            endDate);

        db.Goals.Add(goal);

        await db.SaveChangesAsync();

        var service = new GoalService(db);

        var result =
            await service.GetGoalProgressAsync(
                otherUser.Id,
                goal.Id,
                CancellationToken.None);

        Assert.Null(result);
    }
}