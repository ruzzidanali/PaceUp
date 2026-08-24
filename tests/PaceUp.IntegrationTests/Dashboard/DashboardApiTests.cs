using System.Net;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Dashboard;
using PaceUp.Application.DTOs.Goals;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Dashboard;

public class DashboardApiTests
    : IClassFixture<PostgreSqlContainerFixture>
{
    private readonly PostgreSqlContainerFixture _database;

    public DashboardApiTests(
        PostgreSqlContainerFixture database)
    {
        _database = database;
    }

    [Fact]
    public async Task GetDashboard_ShouldReturnEmptyDashboardForNewUser()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        var response =
            await client.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var dashboard =
            await response.Content
                .ReadFromJsonAsync<DashboardResponse>();

        Assert.NotNull(dashboard);

        Assert.Equal(
            0,
            dashboard.ActivitySummary.TotalActivities);

        Assert.Equal(
            0,
            dashboard.ActivitySummary.TotalDistance);

        Assert.Equal(
            0,
            dashboard.ActivitySummary.TotalDurationSeconds);

        Assert.Equal(
            0,
            dashboard.ActivitySummary.TotalCalories);

        Assert.Empty(
            dashboard.RecentActivities);

        Assert.Empty(
            dashboard.ActiveGoals);
    }

    [Fact]
    public async Task GetDashboard_ShouldReturnActivitySummary()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        await client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)));

        await client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20.0,
                3600,
                800,
                DateTime.UtcNow.AddDays(-1)));

        var response =
            await client.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var dashboard =
            await response.Content
                .ReadFromJsonAsync<DashboardResponse>();

        Assert.NotNull(dashboard);

        Assert.Equal(
            2,
            dashboard.ActivitySummary.TotalActivities);

        Assert.Equal(
            25.0,
            dashboard.ActivitySummary.TotalDistance);

        Assert.Equal(
            5400,
            dashboard.ActivitySummary.TotalDurationSeconds);

        Assert.Equal(
            1100,
            dashboard.ActivitySummary.TotalCalories);
    }

    [Fact]
    public async Task GetDashboard_ShouldReturnLatestFiveActivities()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        for (var i = 1; i <= 7; i++)
        {
            await client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    i,
                    1000,
                    100,
                    DateTime.UtcNow.AddMinutes(-i)));
        }

        var response =
            await client.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var dashboard =
            await response.Content
                .ReadFromJsonAsync<DashboardResponse>();

        Assert.NotNull(dashboard);

        Assert.Equal(
            5,
            dashboard.RecentActivities.Count);

        Assert.Equal(
            1,
            dashboard.RecentActivities[0].Distance);

        Assert.Equal(
            5,
            dashboard.RecentActivities[4].Distance);
    }

    [Fact]
    public async Task GetDashboard_ShouldReturnActiveGoalWithProgress()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        var startDate =
            DateTime.UtcNow.AddDays(-7);

        var endDate =
            DateTime.UtcNow.AddDays(7);

        await client.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                100,
                startDate,
                endDate));

        await client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                25,
                3600,
                500,
                DateTime.UtcNow.AddDays(-2)));

        var response =
            await client.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var dashboard =
            await response.Content
                .ReadFromJsonAsync<DashboardResponse>();

        Assert.NotNull(dashboard);

        Assert.Single(
            dashboard.ActiveGoals);

        var goal =
            dashboard.ActiveGoals[0];

        Assert.Equal(
            "Distance",
            goal.Type);

        Assert.Equal(
            100,
            goal.Target);

        Assert.Equal(
            25,
            goal.Current);

        Assert.Equal(
            75,
            goal.Remaining);

        Assert.Equal(
            25,
            goal.ProgressPercentage);

        Assert.False(
            goal.IsCompleted);
    }

    [Fact]
    public async Task GetDashboard_ShouldExcludeExpiredAndFutureGoals()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        await client.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                100,
                DateTime.UtcNow.AddDays(-10),
                DateTime.UtcNow.AddDays(-1)));

        await client.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                100,
                DateTime.UtcNow.AddDays(1),
                DateTime.UtcNow.AddDays(10)));

        var response =
            await client.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var dashboard =
            await response.Content
                .ReadFromJsonAsync<DashboardResponse>();

        Assert.NotNull(dashboard);

        Assert.Empty(
            dashboard.ActiveGoals);
    }

    [Fact]
    public async Task GetDashboard_WithoutToken_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        var response =
            await client.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    private static async Task AuthenticateAsync(
        HttpClient client)
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"dashboard_{uniqueId}",
                $"dashboard_{uniqueId}@example.com",
                "Dashboard User",
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
            new System.Net.Http.Headers.AuthenticationHeaderValue(
                "Bearer",
                authResponse.AccessToken);
    }

    [Fact]
    public async Task GetDashboard_ShouldOnlyReturnCurrentUsersData()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var firstClient =
            factory.CreateClient();

        await AuthenticateAsync(firstClient);

        await firstClient.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow));

        await firstClient.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                100,
                DateTime.UtcNow.AddDays(-1),
                DateTime.UtcNow.AddDays(7)));

        await using var secondFactory =
            new PaceUpWebApplicationFactory(
                _database);

        using var secondClient =
            secondFactory.CreateClient();

        await AuthenticateAsync(secondClient);

        await secondClient.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                100.0,
                10000,
                5000,
                DateTime.UtcNow));

        await secondClient.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                500,
                DateTime.UtcNow.AddDays(-1),
                DateTime.UtcNow.AddDays(7)));

        var response =
            await firstClient.GetAsync(
                "/api/dashboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var dashboard =
            await response.Content
                .ReadFromJsonAsync<DashboardResponse>();

        Assert.NotNull(dashboard);

        Assert.Equal(
            1,
            dashboard.ActivitySummary.TotalActivities);

        Assert.Equal(
            5.0,
            dashboard.ActivitySummary.TotalDistance);

        Assert.Equal(
            1800,
            dashboard.ActivitySummary.TotalDurationSeconds);

        Assert.Equal(
            300,
            dashboard.ActivitySummary.TotalCalories);

        Assert.Single(
            dashboard.RecentActivities);

        Assert.Equal(
            "Run",
            dashboard.RecentActivities[0].Type);

        Assert.Single(
            dashboard.ActiveGoals);

        Assert.Equal(
            "Distance",
            dashboard.ActiveGoals[0].Type);

        Assert.Equal(
            100,
            dashboard.ActiveGoals[0].Target);
    }
}