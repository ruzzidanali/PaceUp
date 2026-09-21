using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Features.Leaderboards;
using PaceUp.Infrastructure.Persistence;
using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Leaderboards;

public class LeaderboardServiceTests
{
    [Fact]
    public async Task GetAsync_ShouldAggregateDistancePerUser()
    {
        await using var dbContext = CreateDbContext();

        var firstUser = new User(
            "runner1",
            "runner1@example.com",
            "Runner One");

        var secondUser = new User(
            "runner2",
            "runner2@example.com",
            "Runner Two");

        dbContext.Users.AddRange(
            firstUser,
            secondUser);

        dbContext.Activities.AddRange(
            CreateActivity(
                firstUser.Id,
                20,
                DateTime.UtcNow.Date.AddHours(8)),
            CreateActivity(
                firstUser.Id,
                10,
                DateTime.UtcNow.Date.AddHours(10)),
            CreateActivity(
                secondUser.Id,
                25,
                DateTime.UtcNow.Date.AddHours(9)));

        await dbContext.SaveChangesAsync();

        var service =
            new LeaderboardService(dbContext);

        var result =
            await service.GetAsync(
                firstUser.Id,
                "weekly",
                10,
                CancellationToken.None);

        Assert.Equal(
            2,
            result.Count);

        Assert.Equal(
            firstUser.Id,
            result[0].UserId);

        Assert.Equal(
            30,
            result[0].DistanceKm);

        Assert.Equal(
            secondUser.Id,
            result[1].UserId);

        Assert.Equal(
            25,
            result[1].DistanceKm);
    }

    [Fact]
    public async Task GetAsync_ShouldAssignSameRank_WhenDistancesAreEqual()
    {
        await using var dbContext = CreateDbContext();

        var firstUser = new User(
            "runner1",
            "runner1@example.com",
            "Runner One");

        var secondUser = new User(
            "runner2",
            "runner2@example.com",
            "Runner Two");

        var thirdUser = new User(
            "runner3",
            "runner3@example.com",
            "Runner Three");

        dbContext.Users.AddRange(
            firstUser,
            secondUser,
            thirdUser);

        dbContext.Activities.AddRange(
            CreateActivity(
                firstUser.Id,
                20,
                DateTime.UtcNow.Date.AddHours(8)),
            CreateActivity(
                secondUser.Id,
                20,
                DateTime.UtcNow.Date.AddHours(9)),
            CreateActivity(
                thirdUser.Id,
                10,
                DateTime.UtcNow.Date.AddHours(10)));

        await dbContext.SaveChangesAsync();

        var service =
            new LeaderboardService(dbContext);

        var result =
            await service.GetAsync(
                firstUser.Id,
                "weekly",
                10,
                CancellationToken.None);

        Assert.Equal(
            3,
            result.Count);

        Assert.Equal(
            1,
            result[0].Rank);

        Assert.Equal(
            1,
            result[1].Rank);

        Assert.Equal(
            3,
            result[2].Rank);
    }

    [Fact]
    public async Task GetAsync_ShouldReturnOnlyCurrentMonthActivities()
    {
        await using var dbContext = CreateDbContext();

        var user = new User(
            "runner1",
            "runner1@example.com",
            "Runner One");

        dbContext.Users.Add(user);

        var today =
            DateTime.UtcNow.Date;

        var firstDayOfMonth =
            new DateTime(
                today.Year,
                today.Month,
                1,
                0,
                0,
                0,
                DateTimeKind.Utc);

        dbContext.Activities.AddRange(
            CreateActivity(
                user.Id,
                20,
                today.AddHours(8)),
            CreateActivity(
                user.Id,
                50,
                firstDayOfMonth.AddDays(-1).AddHours(8)));

        await dbContext.SaveChangesAsync();

        var service =
            new LeaderboardService(dbContext);

        var result =
            await service.GetAsync(
                user.Id,
                "monthly",
                10,
                CancellationToken.None);

        var currentUser =
            Assert.Single(
                result,
                x => x.UserId == user.Id);

        Assert.Equal(
            20,
            currentUser.DistanceKm);
    }

    [Fact]
    public async Task GetAsync_ShouldIncludeAllActivities_ForAllTime()
    {
        await using var dbContext = CreateDbContext();

        var user = new User(
            "runner1",
            "runner1@example.com",
            "Runner One");

        dbContext.Users.Add(user);

        var today =
            DateTime.UtcNow.Date;

        dbContext.Activities.AddRange(
            CreateActivity(
                user.Id,
                20,
                today.AddHours(8)),
            CreateActivity(
                user.Id,
                50,
                today.AddYears(-2).AddHours(8)));

        await dbContext.SaveChangesAsync();

        var service =
            new LeaderboardService(dbContext);

        var result =
            await service.GetAsync(
                user.Id,
                "all-time",
                10,
                CancellationToken.None);

        var currentUser =
            Assert.Single(
                result,
                x => x.UserId == user.Id);

        Assert.Equal(
            70,
            currentUser.DistanceKm);
    }

    [Fact]
    public async Task GetAsync_ShouldRespectLimit()
    {
        await using var dbContext = CreateDbContext();

        var firstUser = new User(
            "runner1",
            "runner1@example.com",
            "Runner One");

        var secondUser = new User(
            "runner2",
            "runner2@example.com",
            "Runner Two");

        var thirdUser = new User(
            "runner3",
            "runner3@example.com",
            "Runner Three");

        dbContext.Users.AddRange(
            firstUser,
            secondUser,
            thirdUser);

        dbContext.Activities.AddRange(
            CreateActivity(
                firstUser.Id,
                10,
                DateTime.UtcNow.Date.AddHours(8)),
            CreateActivity(
                secondUser.Id,
                20,
                DateTime.UtcNow.Date.AddHours(9)),
            CreateActivity(
                thirdUser.Id,
                30,
                DateTime.UtcNow.Date.AddHours(10)));

        await dbContext.SaveChangesAsync();

        var service =
            new LeaderboardService(dbContext);

        var result =
            await service.GetAsync(
                firstUser.Id,
                "weekly",
                2,
                CancellationToken.None);

        Assert.Equal(
            2,
            result.Count);

        Assert.Equal(
            30,
            result[0].DistanceKm);

        Assert.Equal(
            20,
            result[1].DistanceKm);
    }

    [Fact]
    public async Task GetAsync_ShouldThrowArgumentException_ForInvalidPeriod()
    {
        await using var dbContext = CreateDbContext();

        var service =
            new LeaderboardService(dbContext);

        await Assert.ThrowsAsync<ArgumentException>(
            () =>
                service.GetAsync(
                    Guid.NewGuid(),
                    "yearly",
                    10,
                    CancellationToken.None));
    }

    [Fact]
    public async Task GetAsync_ShouldThrowArgumentException_ForInvalidLimit()
    {
        await using var dbContext = CreateDbContext();

        var service =
            new LeaderboardService(dbContext);

        await Assert.ThrowsAsync<ArgumentException>(
            () =>
                service.GetAsync(
                    Guid.NewGuid(),
                    "weekly",
                    0,
                    CancellationToken.None));
    }

    private static PaceUpDbContext CreateDbContext()
    {
        var options =
            new DbContextOptionsBuilder<PaceUpDbContext>()
                .UseInMemoryDatabase(
                    Guid.NewGuid().ToString())
                .Options;

        return new PaceUpDbContext(options);
    }

    private static Activity CreateActivity(
        Guid userId,
        double distance,
        DateTime startedAt)
    {
        return new Activity(
            userId,
            "Run",
            distance,
            3600,
            500,
            startedAt);
    }
}