using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Leaderboards;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Leaderboards;

public class LeaderboardsControllerTests
    : IClassFixture<PaceUpIntegrationFixture>
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly PaceUpWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public LeaderboardsControllerTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;

        _factory = fixture.Factory;

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetLeaderboard_ShouldReturnLeaderboard()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        await CreateActivityAsync(
            _client,
            10,
            DateTime.UtcNow);

        await CreateActivityAsync(
            _client,
            15,
            DateTime.UtcNow);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=all-time&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var leaderboard =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        Assert.Single(leaderboard);

        Assert.Equal(
            1,
            leaderboard[0].Rank);

        Assert.Equal(
            25,
            leaderboard[0].DistanceKm);

        Assert.True(
            leaderboard[0].IsCurrentUser);
    }

    [Fact]
    public async Task GetLeaderboard_ShouldRankUsersByDistance()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        await CreateActivityAsync(
            _client,
            10,
            DateTime.UtcNow);

        using var secondClient =
            _factory.CreateClient();

        await AuthenticateAsync(secondClient);

        await CreateActivityAsync(
            secondClient,
            25,
            DateTime.UtcNow);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=all-time&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var leaderboard =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        Assert.Equal(
            2,
            leaderboard.Count);

        Assert.Equal(
            25,
            leaderboard[0].DistanceKm);

        Assert.Equal(
            1,
            leaderboard[0].Rank);

        Assert.Equal(
            10,
            leaderboard[1].DistanceKm);

        Assert.Equal(
            2,
            leaderboard[1].Rank);
    }

    [Fact]
    public async Task GetLeaderboard_ShouldAssignSameRankForEqualDistances()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        await CreateActivityAsync(
            _client,
            20,
            DateTime.UtcNow);

        using var secondClient =
            _factory.CreateClient();

        await AuthenticateAsync(secondClient);

        await CreateActivityAsync(
            secondClient,
            20,
            DateTime.UtcNow);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=all-time&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var leaderboard =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        Assert.Equal(
            2,
            leaderboard.Count);

        Assert.Equal(
            1,
            leaderboard[0].Rank);

        Assert.Equal(
            1,
            leaderboard[1].Rank);

        Assert.Equal(
            leaderboard[0].DistanceKm,
            leaderboard[1].DistanceKm);
    }

    [Fact]
    public async Task GetLeaderboard_ShouldRespectLimit()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        await CreateActivityAsync(
            _client,
            10,
            DateTime.UtcNow);

        using var secondClient =
            _factory.CreateClient();

        await AuthenticateAsync(secondClient);

        await CreateActivityAsync(
            secondClient,
            20,
            DateTime.UtcNow);

        using var thirdClient =
            _factory.CreateClient();

        await AuthenticateAsync(thirdClient);

        await CreateActivityAsync(
            thirdClient,
            30,
            DateTime.UtcNow);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=all-time&limit=2");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var leaderboard =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        Assert.Equal(
            2,
            leaderboard.Count);

        Assert.Equal(
            30,
            leaderboard[0].DistanceKm);

        Assert.Equal(
            20,
            leaderboard[1].DistanceKm);
    }

    [Fact]
    public async Task GetLeaderboard_ShouldOnlyIncludeCurrentMonthActivities()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        var currentMonthActivity =
            new DateTime(
                DateTime.UtcNow.Year,
                DateTime.UtcNow.Month,
                10,
                12,
                0,
                0,
                DateTimeKind.Utc);

        await CreateActivityAsync(
            _client,
            15,
            currentMonthActivity);

        var previousMonth =
            new DateTime(
                DateTime.UtcNow.Year,
                DateTime.UtcNow.Month,
                1,
                12,
                0,
                0,
                DateTimeKind.Utc)
                .AddMonths(-1);

        await CreateActivityAsync(
            _client,
            100,
            previousMonth);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=monthly&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var leaderboard =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        Assert.Single(leaderboard);

        Assert.Equal(
            15,
            leaderboard[0].DistanceKm);
    }

    [Fact]
    public async Task GetLeaderboard_WithoutToken_ShouldReturnUnauthorized()
    {
        await _fixture.ResetDatabaseAsync();

        var response =
            await _client.GetAsync(
                "/api/leaderboards");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetLeaderboard_WithInvalidPeriod_ShouldReturnBadRequest()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=yearly&limit=10");

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task GetLeaderboard_WithInvalidLimit_ShouldReturnBadRequest()
    {
        await _fixture.ResetDatabaseAsync();

        await AuthenticateAsync(_client);

        var response =
            await _client.GetAsync(
                "/api/leaderboards?period=all-time&limit=0");

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    private static async Task CreateActivityAsync(
        HttpClient client,
        double distance,
        DateTime startedAt)
    {
        var response =
            await client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    distance,
                    3600,
                    500,
                    startedAt));

        Assert.True(
            response.IsSuccessStatusCode,
            $"Activity creation failed: {response.StatusCode}");
    }

    private static async Task AuthenticateAsync(
        HttpClient client)
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"leaderboard_{uniqueId}",
                $"leaderboard_{uniqueId}@example.com",
                "Leaderboard Test User",
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