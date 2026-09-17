using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Controllers;
using PaceUp.Application.Abstractions.Achievements;
using PaceUp.Application.DTOs.Achievements;

namespace PaceUp.ApiTests;

public class AchievementsControllerTests
{
    [Fact]
    public async Task Get_ShouldReturnAchievementsForAuthenticatedUser()
    {
        var userId = Guid.NewGuid();

        var expected = new List<AchievementResponse>
        {
            new(
                Guid.NewGuid(),
                "FIRST_ACTIVITY",
                "First Steps",
                "Complete your first activity.",
                "directions_run",
                "ACTIVITY_COUNT",
                1,
                DateTime.UtcNow)
        };

        var achievementService =
            new FakeAchievementService(expected);

        var controller =
            new AchievementsController(
                achievementService);

        controller.ControllerContext =
            CreateControllerContext(userId);

        var result =
            await controller.Get(
                CancellationToken.None);

        var okResult =
            Assert.IsType<OkObjectResult>(result.Result);

        var achievements =
            Assert.IsAssignableFrom<
                IReadOnlyList<AchievementResponse>>(
                    okResult.Value);

        Assert.Single(achievements);
        Assert.Equal(
            "FIRST_ACTIVITY",
            achievements[0].Code);

        Assert.Equal(
            userId,
            achievementService.RequestedUserId);
    }

    [Fact]
    public async Task Get_ShouldReturnUnauthorized_WhenUserIdClaimIsInvalid()
    {
        var achievementService =
            new FakeAchievementService([]);

        var controller =
            new AchievementsController(
                achievementService);

        controller.ControllerContext =
            CreateControllerContext(
                "not-a-guid");

        var result =
            await controller.Get(
                CancellationToken.None);

        Assert.IsType<UnauthorizedResult>(
            result.Result);

        Assert.Null(
            achievementService.RequestedUserId);
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

    private sealed class FakeAchievementService
        : IAchievementService
    {
        private readonly IReadOnlyList<AchievementResponse>
            _achievements;

        public Guid? RequestedUserId { get; private set; }

        public FakeAchievementService(
            IReadOnlyList<AchievementResponse> achievements)
        {
            _achievements = achievements;
        }

        public Task<IReadOnlyList<AchievementResponse>> GetAsync(
            Guid userId,
            CancellationToken cancellationToken)
        {
            RequestedUserId = userId;

            return Task.FromResult(
                _achievements);
        }

        public Task<IReadOnlyList<AchievementResponse>> EvaluateAsync(
            Guid userId,
            CancellationToken cancellationToken)
        {
            return Task.FromResult<
                IReadOnlyList<AchievementResponse>>([]);
        }
    }
}