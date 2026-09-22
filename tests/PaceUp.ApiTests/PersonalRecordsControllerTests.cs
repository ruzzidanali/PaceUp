using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Controllers;
using PaceUp.Application.Abstractions.PersonalRecords;
using PaceUp.Application.DTOs.PersonalRecords;

namespace PaceUp.ApiTests;

public class PersonalRecordsControllerTests
{
    [Fact]
    public async Task Get_ShouldReturnPersonalRecordsForAuthenticatedUser()
    {
        var userId = Guid.NewGuid();

        var expected =
            new PersonalRecordResponse(
                LongestDistanceKm: 42.5,
                LongestDurationSeconds: 7200,
                FastestSpeedKmh: 25.2,
                FastestPaceSecondsPerKm: 300,
                MostCalories: 850);

        var personalRecordService =
            new FakePersonalRecordService(expected);

        var controller =
            new PersonalRecordsController(
                personalRecordService);

        controller.ControllerContext =
            CreateControllerContext(userId);

        var result =
            await controller.Get(
                CancellationToken.None);

        var okResult =
            Assert.IsType<OkObjectResult>(
                result.Result);

        var records =
            Assert.IsType<PersonalRecordResponse>(
                okResult.Value);

        Assert.Equal(
            expected.LongestDistanceKm,
            records.LongestDistanceKm);

        Assert.Equal(
            expected.LongestDurationSeconds,
            records.LongestDurationSeconds);

        Assert.Equal(
            expected.FastestSpeedKmh,
            records.FastestSpeedKmh);

        Assert.Equal(
            expected.FastestPaceSecondsPerKm,
            records.FastestPaceSecondsPerKm);

        Assert.Equal(
            expected.MostCalories,
            records.MostCalories);

        Assert.Equal(
            userId,
            personalRecordService.RequestedUserId);
    }

    [Fact]
    public async Task Get_ShouldReturnUnauthorized_WhenUserIdClaimIsInvalid()
    {
        var personalRecordService =
            new FakePersonalRecordService(
                new PersonalRecordResponse(
                    null,
                    null,
                    null,
                    null,
                    null));

        var controller =
            new PersonalRecordsController(
                personalRecordService);

        controller.ControllerContext =
            CreateControllerContext(
                "not-a-guid");

        var result =
            await controller.Get(
                CancellationToken.None);

        Assert.IsType<UnauthorizedResult>(
            result.Result);

        Assert.Null(
            personalRecordService.RequestedUserId);
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

    private sealed class FakePersonalRecordService
        : IPersonalRecordService
    {
        private readonly PersonalRecordResponse _response;

        public Guid? RequestedUserId { get; private set; }

        public FakePersonalRecordService(
            PersonalRecordResponse response)
        {
            _response = response;
        }

        public Task<PersonalRecordResponse> GetAsync(
            Guid userId,
            CancellationToken cancellationToken)
        {
            RequestedUserId = userId;

            return Task.FromResult(
                _response);
        }
    }
}