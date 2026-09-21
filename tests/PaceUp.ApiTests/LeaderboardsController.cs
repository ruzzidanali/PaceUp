using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Controllers;
using PaceUp.Application.Abstractions.Leaderboards;
using PaceUp.Application.DTOs.Leaderboards;

namespace PaceUp.ApiTests;

public class LeaderboardsControllerTests
{
    [Fact]
    public async Task Get_ShouldReturnLeaderboardForAuthenticatedUser()
    {
        var userId = Guid.NewGuid();

        var expected =
            new List<LeaderboardEntryResponse>
            {
                new(
                    1,
                    userId,
                    "testuser",
                    "Test User",
                    null,
                    30,
                    true),
                new(
                    2,
                    Guid.NewGuid(),
                    "runner2",
                    "Runner Two",
                    null,
                    20,
                    false)
            };

        var leaderboardService =
            new FakeLeaderboardService(expected);

        var controller =
            new LeaderboardsController(
                leaderboardService);

        controller.ControllerContext =
            CreateControllerContext(userId);

        var result =
            await controller.Get(
                "weekly",
                10,
                CancellationToken.None);

        var okResult =
            Assert.IsType<OkObjectResult>(
                result.Result);

        var leaderboard =
    Assert.IsType<
        List<LeaderboardEntryResponse>>(
        okResult.Value);

        Assert.Equal(
            2,
            leaderboard.Count);

        Assert.Equal(
            userId,
            leaderboard[0].UserId);

        Assert.Equal(
            30,
            leaderboard[0].DistanceKm);

        Assert.True(
            leaderboard[0].IsCurrentUser);

        Assert.Equal(
            userId,
            leaderboardService.RequestedUserId);

        Assert.Equal(
            "weekly",
            leaderboardService.RequestedPeriod);

        Assert.Equal(
            10,
            leaderboardService.RequestedLimit);
    }

    [Fact]
    public async Task Get_ShouldReturnUnauthorized_WhenUserIdClaimIsInvalid()
    {
        var leaderboardService =
            new FakeLeaderboardService(
                Array.Empty<LeaderboardEntryResponse>());

        var controller =
            new LeaderboardsController(
                leaderboardService);

        controller.ControllerContext =
            CreateControllerContext(
                "not-a-guid");

        var result =
            await controller.Get(
                "weekly",
                10,
                CancellationToken.None);

        Assert.IsType<UnauthorizedResult>(
            result.Result);

        Assert.Null(
            leaderboardService.RequestedUserId);
    }

    [Fact]
    public async Task Get_ShouldReturnBadRequest_WhenServiceThrowsArgumentException()
    {
        var leaderboardService =
            new FakeLeaderboardService(
                Array.Empty<LeaderboardEntryResponse>())
            {
                ThrowArgumentException = true
            };

        var controller =
            new LeaderboardsController(
                leaderboardService);

        controller.ControllerContext =
            CreateControllerContext(
                Guid.NewGuid());

        var result =
            await controller.Get(
                "invalid",
                10,
                CancellationToken.None);

        var badRequestResult =
            Assert.IsType<BadRequestObjectResult>(
                result.Result);

        Assert.Equal(
            "Invalid leaderboard parameters.",
            badRequestResult.Value);
    }

    private static ControllerContext CreateControllerContext(
        Guid userId)
    {
        return CreateControllerContext(
            userId.ToString());
    }

    private static ControllerContext CreateControllerContext(
        string userId)
    {
        var claims = new[]
        {
            new Claim(
                ClaimTypes.NameIdentifier,
                userId)
        };

        var identity =
            new ClaimsIdentity(
                claims,
                "TestAuthentication");

        var principal =
            new ClaimsPrincipal(identity);

        return new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = principal
            }
        };
    }

    private sealed class FakeLeaderboardService
        : ILeaderboardService
    {
        private readonly IReadOnlyList<LeaderboardEntryResponse> _response;

        public Guid? RequestedUserId { get; private set; }

        public string? RequestedPeriod { get; private set; }

        public int? RequestedLimit { get; private set; }

        public bool ThrowArgumentException { get; init; }

        public FakeLeaderboardService(
            IReadOnlyList<LeaderboardEntryResponse> response)
        {
            _response = response;
        }

        public Task<IReadOnlyList<LeaderboardEntryResponse>> GetAsync(
            Guid userId,
            string period,
            int limit,
            CancellationToken cancellationToken)
        {
            RequestedUserId = userId;
            RequestedPeriod = period;
            RequestedLimit = limit;

            if (ThrowArgumentException)
            {
                throw new ArgumentException(
                    "Invalid leaderboard parameters.");
            }

            return Task.FromResult(
                _response);
        }
    }
}