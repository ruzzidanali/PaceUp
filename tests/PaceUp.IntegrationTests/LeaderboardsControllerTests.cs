using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Leaderboards;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Leaderboards;

public class LeaderboardsControllerTests
    : IClassFixture<PostgreSqlContainerFixture>
{
    private readonly PostgreSqlContainerFixture _database;
    private readonly PaceUpWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public LeaderboardsControllerTests(
        PostgreSqlContainerFixture database)
    {
        _database = database;

        _factory =
            new PaceUpWebApplicationFactory(
                _database);

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetLeaderboards_ShouldReturnWeeklyRanking()
    {
        await AuthenticateAsync(_client);

        var today = DateTime.UtcNow.Date;

        var firstActivityResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    20,
                    3600,
                    500,
                    today.AddHours(8)));

        Assert.Equal(
            HttpStatusCode.Created,
            firstActivityResponse.StatusCode);

        var secondActivityResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    10,
                    1800,
                    250,
                    today.AddHours(10)));

        Assert.Equal(
            HttpStatusCode.Created,
            secondActivityResponse.StatusCode);

        var leaderboardResponse =
            await _client.GetAsync(
                "/api/leaderboards?period=weekly&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            leaderboardResponse.StatusCode);

        var leaderboard =
            await leaderboardResponse.Content
                .ReadFromJsonAsync<
                    List<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        var currentUserEntry =
            Assert.Single(
                leaderboard,
                x => x.IsCurrentUser);

        Assert.Equal(
            30,
            currentUserEntry.DistanceKm);

        Assert.True(
            currentUserEntry.Rank >= 1);
    }

    [Fact]
    public async Task GetLeaderboards_ShouldAssignSameRank_WhenUsersHaveEqualDistance()
    {
        await AuthenticateAsync(_client);

        var today = DateTime.UtcNow.Date;

        var firstUserActivity =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    20,
                    3600,
                    500,
                    today.AddHours(8)));

        Assert.Equal(
            HttpStatusCode.Created,
            firstUserActivity.StatusCode);

        using var secondClient =
            _factory.CreateClient();

        await AuthenticateAsync(secondClient);

        var secondUserActivity =
            await secondClient.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    20,
                    3600,
                    500,
                    today.AddHours(9)));

        Assert.Equal(
            HttpStatusCode.Created,
            secondUserActivity.StatusCode);

        using var thirdClient =
            _factory.CreateClient();

        await AuthenticateAsync(thirdClient);

        var thirdUserActivity =
            await thirdClient.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    10,
                    1800,
                    250,
                    today.AddHours(10)));

        Assert.Equal(
            HttpStatusCode.Created,
            thirdUserActivity.StatusCode);

        var leaderboardResponse =
            await _client.GetAsync(
                "/api/leaderboards?period=weekly&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            leaderboardResponse.StatusCode);

        var leaderboard =
            await leaderboardResponse.Content
                .ReadFromJsonAsync<
                    List<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        var currentUserEntry =
            Assert.Single(
                leaderboard,
                x => x.IsCurrentUser);

        Assert.Equal(
            20,
            currentUserEntry.DistanceKm);

        var equalDistanceEntries =
            leaderboard
                .Where(x => x.DistanceKm == 20)
                .ToList();

        Assert.True(
            equalDistanceEntries.Count >= 2);

        var equalDistanceRank =
            equalDistanceEntries[0].Rank;

        Assert.All(
            equalDistanceEntries,
            entry =>
                Assert.Equal(
                    equalDistanceRank,
                    entry.Rank));

        var lowerDistanceEntries =
            leaderboard
                .Where(x => x.DistanceKm < 20)
                .ToList();

        Assert.NotEmpty(
            lowerDistanceEntries);

        Assert.All(
            lowerDistanceEntries,
            entry =>
                Assert.True(
                    entry.Rank > equalDistanceRank));
    }

    [Fact]
    public async Task GetLeaderboards_ShouldReturnOnlyCurrentMonthActivities_WhenPeriodIsMonthly()
    {
        await AuthenticateAsync(_client);

        var today = DateTime.UtcNow.Date;

        var currentMonthActivity =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    20,
                    3600,
                    500,
                    today.AddHours(8)));

        Assert.Equal(
            HttpStatusCode.Created,
            currentMonthActivity.StatusCode);

        var previousMonth =
            new DateTime(
                today.Year,
                today.Month,
                1,
                0,
                0,
                0,
                DateTimeKind.Utc)
            .AddDays(-1);

        var previousMonthActivity =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    50,
                    7200,
                    1000,
                    previousMonth.AddHours(8)));

        Assert.Equal(
            HttpStatusCode.Created,
            previousMonthActivity.StatusCode);

        var leaderboardResponse =
            await _client.GetAsync(
                "/api/leaderboards?period=monthly&limit=10");

        var leaderboardBody =
            await leaderboardResponse.Content
                .ReadAsStringAsync();

        Assert.True(
            leaderboardResponse.IsSuccessStatusCode,
            $"Leaderboard request failed: " +
            $"{leaderboardResponse.StatusCode} - {leaderboardBody}");

        var leaderboard =
            await leaderboardResponse.Content
                .ReadFromJsonAsync<
                    List<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        foreach (var entry in leaderboard)
        {
            Console.WriteLine(
                $"Rank={entry.Rank}, " +
                $"UserId={entry.UserId}, " +
                $"Distance={entry.DistanceKm}, " +
                $"Current={entry.IsCurrentUser}");
        }

        var currentUserEntry =
            Assert.Single(
                leaderboard,
                x => x.IsCurrentUser);

        Assert.Equal(
            20,
            currentUserEntry.DistanceKm);
    }

    [Fact]
    public async Task GetLeaderboards_ShouldIncludeAllActivities_WhenPeriodIsAllTime()
    {
        await AuthenticateAsync(_client);

        var today = DateTime.UtcNow.Date;

        var currentActivity =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    20,
                    3600,
                    500,
                    today.AddHours(8)));

        Assert.Equal(
            HttpStatusCode.Created,
            currentActivity.StatusCode);

        var oldActivity =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    50,
                    7200,
                    1000,
                    today.AddYears(-2).AddHours(8)));

        Assert.Equal(
            HttpStatusCode.Created,
            oldActivity.StatusCode);

        var leaderboardResponse =
            await _client.GetAsync(
                "/api/leaderboards?period=all-time&limit=10");

        Assert.Equal(
            HttpStatusCode.OK,
            leaderboardResponse.StatusCode);

        var leaderboard =
            await leaderboardResponse.Content
                .ReadFromJsonAsync<
                    List<LeaderboardEntryResponse>>();

        Assert.NotNull(leaderboard);

        var currentUserEntry =
            Assert.Single(
                leaderboard,
                x => x.IsCurrentUser);

        Assert.Equal(
            70,
            currentUserEntry.DistanceKm);
    }

    private static async Task AuthenticateAsync(HttpClient client)
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"test_auth_{uniqueId}",
                $"test_auth_{uniqueId}@example.com",
                "Test Auth User",
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
