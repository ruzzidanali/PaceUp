using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.PersonalRecords;
using PaceUp.Application.DTOs.Routes;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.PersonalRecords;

public class PersonalRecordsControllerTests
    : IClassFixture<PaceUpIntegrationFixture>
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly PaceUpWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public PersonalRecordsControllerTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _factory = fixture.Factory;
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetPersonalRecords_ShouldReturnCurrentUsersRecords()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        var firstActivity =
            await CreateActivityAsync(
                _client,
                "Run",
                10.0,
                3600,
                600);

        await CreateActivityAsync(
            _client,
            "Run",
            25.0,
            7200,
            1200);

        await AddRouteAsync(
            _client,
            firstActivity.Id,
            5.0,
            10.0);

        var response =
            await _client.GetAsync(
                "/api/personal-records");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var records =
            await response.Content
                .ReadFromJsonAsync<PersonalRecordResponse>();

        Assert.NotNull(records);

        Assert.Equal(
            25.0,
            records.LongestDistanceKm);

        Assert.Equal(
            7200,
            records.LongestDurationSeconds);

        Assert.Equal(
            36.0,
            records.FastestSpeedKmh!.Value,
            3);

        Assert.Equal(
            288,
            records.FastestPaceSecondsPerKm!.Value,
            3);

        Assert.Equal(
            1200,
            records.MostCalories);
    }

    [Fact]
    public async Task GetPersonalRecords_ShouldOnlyIncludeCurrentUsersActivities()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        await CreateActivityAsync(
            _client,
            "Run",
            5.0,
            1800,
            300);

        using var secondClient =
            _factory.CreateClient();

        await AuthenticateAsync(secondClient);

        await CreateActivityAsync(
            secondClient,
            "Ride",
            100.0,
            10000,
            5000);

        var response =
            await _client.GetAsync(
                "/api/personal-records");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var records =
            await response.Content
                .ReadFromJsonAsync<PersonalRecordResponse>();

        Assert.NotNull(records);

        Assert.Equal(
            5.0,
            records.LongestDistanceKm);

        Assert.Equal(
            1800,
            records.LongestDurationSeconds);

        Assert.Equal(
            300,
            records.MostCalories);

        Assert.Equal(
            360,
            records.FastestPaceSecondsPerKm!.Value,
            3);

        Assert.Null(
            records.FastestSpeedKmh);
    }

    [Fact]
    public async Task GetPersonalRecords_WithoutActivities_ShouldReturnEmptyRecords()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        var response =
            await _client.GetAsync(
                "/api/personal-records");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var records =
            await response.Content
                .ReadFromJsonAsync<PersonalRecordResponse>();

        Assert.NotNull(records);

        Assert.Null(
            records.LongestDistanceKm);

        Assert.Null(
            records.LongestDurationSeconds);

        Assert.Null(
            records.FastestSpeedKmh);

        Assert.Null(
            records.FastestPaceSecondsPerKm);

        Assert.Null(
            records.MostCalories);
    }

    [Fact]
    public async Task GetPersonalRecords_WithoutToken_ShouldReturnUnauthorized()
    {
        await _fixture.ResetDatabaseAsync();

        var response =
            await _client.GetAsync(
                "/api/personal-records");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    private static async Task<ActivityResponse> CreateActivityAsync(
        HttpClient client,
        string type,
        double distance,
        int durationSeconds,
        int calories)
    {
        var response =
            await client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    type,
                    distance,
                    durationSeconds,
                    calories,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var activity =
            await response.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(activity);

        return activity;
    }

    private static async Task AddRouteAsync(
        HttpClient client,
        Guid activityId,
        double firstSpeed,
        double secondSpeed)
    {
        var routeRequest =
            new CreateActivityRouteRequest(
                new[]
                {
                    new CreateActivityPointRequest(
                        1.0,
                        1.0,
                        null,
                        5.0,
                        firstSpeed,
                        null,
                        DateTime.UtcNow),

                    new CreateActivityPointRequest(
                        1.001,
                        1.001,
                        null,
                        5.0,
                        secondSpeed,
                        null,
                        DateTime.UtcNow.AddMinutes(30))
                });

        var response =
            await client.PostAsJsonAsync(
                $"/api/activities/{activityId}/route",
                routeRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);
    }

    private static async Task AuthenticateAsync(
        HttpClient client)
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"personal_records_{uniqueId}",
                $"personal_records_{uniqueId}@example.com",
                "Personal Records Test User",
                "Password123!");

        var registerResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.True(
            registerResponse.IsSuccessStatusCode,
            $"Registration failed: {registerResponse.StatusCode}");

        var loginResponse =
            await client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequest(
                    registerRequest.Email,
                    registerRequest.Password));

        Assert.True(
            loginResponse.IsSuccessStatusCode,
            $"Login failed: {loginResponse.StatusCode}");

        var authResponse =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                authResponse.AccessToken);
    }
}