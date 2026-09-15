using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Routes;
using PaceUp.Application.DTOs.Users;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Routes;

public class RoutesApiTests
    : IClassFixture<PaceUpIntegrationFixture>,
      IAsyncLifetime
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly HttpClient _client;

    public RoutesApiTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _client = fixture.Factory.CreateClient();
    }

    public async Task InitializeAsync()
    {
        await _fixture.ResetDatabaseAsync();

        _client.DefaultRequestHeaders.Authorization = null;
    }

    public Task DisposeAsync()
    {
        return Task.CompletedTask;
    }

    [Fact]
    public async Task GetRoute_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        var activityId = Guid.NewGuid();

        var response =
            await _client.GetAsync(
                $"/api/activities/{activityId}/route");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetRoute_ForMissingActivity_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_missing",
                "route_missing@example.com");

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                $"/api/activities/{Guid.NewGuid()}/route");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GetRoute_WithExistingActivityAndNoPoints_ShouldReturnEmptyRoute()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_empty",
                "route_empty@example.com");

        var userId =
            await GetCurrentUserIdAsync(token);

        var activityId =
            await CreateActivityAsync(
                userId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                $"/api/activities/{activityId}/route");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<RouteResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            activityId,
            result.ActivityId);

        Assert.Empty(result.Points);
    }

    [Fact]
    public async Task GetRoute_WithPoints_ShouldReturnPointsOrderedByRecordedAt()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_points",
                "route_points@example.com");

        var userId =
            await GetCurrentUserIdAsync(token);

        var activityId =
            await CreateActivityAsync(
                userId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        var firstRecordedAt =
            DateTime.UtcNow.AddMinutes(-9);

        var secondRecordedAt =
            DateTime.UtcNow.AddMinutes(-8);

        var thirdRecordedAt =
            DateTime.UtcNow.AddMinutes(-7);

        await CreateActivityPointAsync(
            activityId,
            3.1401,
            101.6901,
            10,
            5,
            2.5,
            140,
            secondRecordedAt);

        await CreateActivityPointAsync(
            activityId,
            3.1400,
            101.6900,
            9,
            5,
            2.2,
            138,
            firstRecordedAt);

        await CreateActivityPointAsync(
            activityId,
            3.1402,
            101.6902,
            11,
            4,
            2.8,
            142,
            thirdRecordedAt);

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                $"/api/activities/{activityId}/route");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<RouteResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            activityId,
            result.ActivityId);

        Assert.Equal(
            3,
            result.Points.Count);

        Assert.True(
            Math.Abs(
                (firstRecordedAt - result.Points[0].RecordedAt).TotalMilliseconds) < 1);

        Assert.True(
            Math.Abs(
                (secondRecordedAt - result.Points[1].RecordedAt).TotalMilliseconds) < 1);

        Assert.True(
            Math.Abs(
                (thirdRecordedAt - result.Points[2].RecordedAt).TotalMilliseconds) < 1);

        Assert.Equal(
            3.1400,
            result.Points[0].Latitude);

        Assert.Equal(
            101.6900,
            result.Points[0].Longitude);
    }

    [Fact]
    public async Task GetRoute_ForActivityOwnedByAnotherUser_ShouldReturnNotFound()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "route_owner",
                "route_owner@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        var otherUserToken =
            await RegisterAndLoginAsync(
                "route_other",
                "route_other@example.com");

        SetBearerToken(otherUserToken);

        var response =
            await _client.GetAsync(
                $"/api/activities/{activityId}/route");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    private async Task<string> RegisterAndLoginAsync(
        string username,
        string email)
    {
        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                new RegisterRequest(
                    username,
                    email,
                    username,
                    "Password123!"));

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var loginResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequest(
                    email,
                    "Password123!"));

        Assert.Equal(
            HttpStatusCode.OK,
            loginResponse.StatusCode);

        var result =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(result);

        return result.AccessToken;
    }

    private async Task<Guid> GetCurrentUserIdAsync(
        string accessToken)
    {
        SetBearerToken(accessToken);

        var response =
            await _client.GetAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(result);

        return result.Id;
    }

    private async Task<Guid> CreateActivityAsync(
        Guid userId,
        string type,
        double distance,
        int durationSeconds,
        int? calories,
        DateTime startedAt)
    {
        using var scope =
            _fixture.Factory.Services.CreateScope();

        var db =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var activity =
            new Activity(
                userId,
                type,
                distance,
                durationSeconds,
                calories,
                startedAt);

        db.Activities.Add(activity);

        await db.SaveChangesAsync();

        return activity.Id;
    }

    private async Task CreateActivityPointAsync(
        Guid activityId,
        double latitude,
        double longitude,
        double? altitude,
        double? accuracy,
        double? speed,
        double? heartRate,
        DateTime recordedAt)
    {
        using var scope =
            _fixture.Factory.Services.CreateScope();

        var db =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var point =
            new ActivityPoint(
                activityId,
                latitude,
                longitude,
                altitude,
                accuracy,
                speed,
                heartRate,
                recordedAt);

        db.Set<ActivityPoint>().Add(point);

        await db.SaveChangesAsync();
    }

    private void SetBearerToken(
        string accessToken)
    {
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);
    }

    [Fact]
    public async Task CreateRoute_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        var activityId = Guid.NewGuid();

        var request = new CreateActivityRouteRequest(
            []);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateRoute_ForMissingActivity_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_create_missing",
                "route_create_missing@example.com");

        SetBearerToken(token);

        var request =
            new CreateActivityRouteRequest(
                [
                    new CreateActivityPointRequest(
                    3.1400,
                    101.6900,
                    10,
                    5,
                    2.5,
                    140,
                    DateTime.UtcNow)
                ]);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{Guid.NewGuid()}/route",
                request);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateRoute_ForActivityOwnedByAnotherUser_ShouldReturnNotFound()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "route_create_owner",
                "route_create_owner@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        var otherUserToken =
            await RegisterAndLoginAsync(
                "route_create_other",
                "route_create_other@example.com");

        SetBearerToken(otherUserToken);

        var request =
            new CreateActivityRouteRequest(
                [
                    new CreateActivityPointRequest(
                    3.1400,
                    101.6900,
                    10,
                    5,
                    2.5,
                    140,
                    DateTime.UtcNow)
                ]);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                request);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateRoute_WithPoints_ShouldPersistAndReturnPointsInOrder()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_create_points",
                "route_create_points@example.com");

        var userId =
            await GetCurrentUserIdAsync(token);

        var activityId =
            await CreateActivityAsync(
                userId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        var firstRecordedAt =
            DateTime.UtcNow.AddMinutes(-9);

        var secondRecordedAt =
            DateTime.UtcNow.AddMinutes(-8);

        var thirdRecordedAt =
            DateTime.UtcNow.AddMinutes(-7);

        var request =
            new CreateActivityRouteRequest(
                [
                    new CreateActivityPointRequest(
                    3.1401,
                    101.6901,
                    10,
                    5,
                    2.5,
                    140,
                    secondRecordedAt),

                new CreateActivityPointRequest(
                    3.1400,
                    101.6900,
                    9,
                    5,
                    2.2,
                    138,
                    firstRecordedAt),

                new CreateActivityPointRequest(
                    3.1402,
                    101.6902,
                    11,
                    4,
                    2.8,
                    142,
                    thirdRecordedAt)
                ]);

        SetBearerToken(token);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<RouteResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            activityId,
            result.ActivityId);

        Assert.Equal(
            3,
            result.Points.Count);

        Assert.Equal(
            3.1400,
            result.Points[0].Latitude);

        Assert.Equal(
            101.6900,
            result.Points[0].Longitude);

        Assert.Equal(
            3.1401,
            result.Points[1].Latitude);

        Assert.Equal(
            101.6901,
            result.Points[1].Longitude);

        Assert.Equal(
            3.1402,
            result.Points[2].Latitude);

        Assert.Equal(
            101.6902,
            result.Points[2].Longitude);
    }

    [Fact]
    public async Task CreateRoute_WithInvalidLatitude_ShouldReturnBadRequest()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_invalid_lat",
                "route_invalid_lat@example.com");

        var userId =
            await GetCurrentUserIdAsync(token);

        var activityId =
            await CreateActivityAsync(
                userId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        SetBearerToken(token);

        var request =
            new CreateActivityRouteRequest(
                [
                    new CreateActivityPointRequest(
                    91.0,
                    101.6900,
                    10,
                    5,
                    2.5,
                    140,
                    DateTime.UtcNow)
                ]);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateRoute_WithInvalidLongitude_ShouldReturnBadRequest()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_invalid_long",
                "route_invalid_long@example.com");

        var userId =
            await GetCurrentUserIdAsync(token);

        var activityId =
            await CreateActivityAsync(
                userId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        SetBearerToken(token);

        var request =
            new CreateActivityRouteRequest(
                [
                    new CreateActivityPointRequest(
                    3.1400,
                    181.0,
                    10,
                    5,
                    2.5,
                    140,
                    DateTime.UtcNow)
                ]);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateRoute_WithNegativeSpeed_ShouldReturnBadRequest()
    {
        var token =
            await RegisterAndLoginAsync(
                "route_invalid_speed",
                "route_invalid_speed@example.com");

        var userId =
            await GetCurrentUserIdAsync(token);

        var activityId =
            await CreateActivityAsync(
                userId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-10));

        SetBearerToken(token);

        var request =
            new CreateActivityRouteRequest(
                [
                    new CreateActivityPointRequest(
                    3.1400,
                    101.6900,
                    10,
                    5,
                    -2.5,
                    140,
                    DateTime.UtcNow)
                ]);

        var response =
            await _client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }
}