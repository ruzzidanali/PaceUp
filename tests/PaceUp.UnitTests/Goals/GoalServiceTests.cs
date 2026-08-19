using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Goals;
using PaceUp.Application.Features.Goals;
using PaceUp.Domain.Entities;

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
        }
    }
}