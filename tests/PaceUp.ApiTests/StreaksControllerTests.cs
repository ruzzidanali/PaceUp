using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Controllers;
using PaceUp.Application.Abstractions.Streaks;
using PaceUp.Application.DTOs.Streaks;

namespace PaceUp.ApiTests;

public class StreaksControllerTests
{
    [Fact]
    public async Task Get_ShouldReturnStreakForAuthenticatedUser()
    {
        var userId = Guid.NewGuid();

        var expected = new StreakResponse(
            3,
            7);

        var streakService =
            new FakeStreakService(expected);

        var controller =
            new StreaksController(
                streakService);

        controller.ControllerContext =
            CreateControllerContext(userId);

        var result =
            await controller.Get(
                CancellationToken.None);

        var okResult =
            Assert.IsType<OkObjectResult>(
                result.Result);

        var streak =
            Assert.IsType<StreakResponse>(
                okResult.Value);

        Assert.Equal(
            3,
            streak.CurrentStreak);

        Assert.Equal(
            7,
            streak.LongestStreak);

        Assert.Equal(
            userId,
            streakService.RequestedUserId);
    }

    [Fact]
    public async Task Get_ShouldReturnUnauthorized_WhenUserIdClaimIsInvalid()
    {
        var streakService =
            new FakeStreakService(
                new StreakResponse(0, 0));

        var controller =
            new StreaksController(
                streakService);

        controller.ControllerContext =
            CreateControllerContext(
                "not-a-guid");

        var result =
            await controller.Get(
                CancellationToken.None);

        Assert.IsType<UnauthorizedResult>(
            result.Result);

        Assert.Null(
            streakService.RequestedUserId);
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

    private sealed class FakeStreakService
        : IStreakService
    {
        private readonly StreakResponse _response;

        public Guid? RequestedUserId { get; private set; }

        public FakeStreakService(
            StreakResponse response)
        {
            _response = response;
        }

        public Task<StreakResponse> GetAsync(
            Guid userId,
            CancellationToken cancellationToken)
        {
            RequestedUserId = userId;

            return Task.FromResult(
                _response);
        }
    }
}