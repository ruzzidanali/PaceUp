using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Goals;
using PaceUp.IntegrationTests.Infrastructure;
using PaceUp.Application.DTOs.Activities;

namespace PaceUp.IntegrationTests.Goals;

public class GoalsApiTests
    : IClassFixture<PostgreSqlContainerFixture>
{
    private readonly PostgreSqlContainerFixture _database;
    private readonly PaceUpWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public GoalsApiTests(
        PostgreSqlContainerFixture database)
    {
        _database = database;

        _factory =
            new PaceUpWebApplicationFactory(
                _database);

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task CreateGoal_ShouldReturnCreatedGoal()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        var response =
            await _client.PostAsJsonAsync(
                "/api/goals",
                request);

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var goal =
            await response.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        Assert.NotEqual(
            Guid.Empty,
            goal.Id);

        Assert.Equal(
            "Distance",
            goal.Type);

        Assert.Equal(
            50,
            goal.Target);
    }

    [Fact]
    public async Task GetGoals_ShouldReturnCurrentUsersGoals()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        await _client.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                50,
                startDate,
                startDate.AddDays(6)));

        await _client.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Calories",
                3000,
                startDate,
                startDate.AddDays(6)));

        var response =
            await _client.GetAsync(
                "/api/goals");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var goals =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<GoalResponse>>();

        Assert.NotNull(goals);

        Assert.Equal(
            2,
            goals.Count);
    }

    [Fact]
    public async Task GetGoal_ShouldReturnOwnGoal()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    50,
                    startDate,
                    startDate.AddDays(6)));

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(created);

        var response =
            await _client.GetAsync(
                $"/api/goals/{created.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var goal =
            await response.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        Assert.Equal(
            created.Id,
            goal.Id);
    }

    [Fact]
    public async Task GetGoal_WhenNotFound_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var response =
            await _client.GetAsync(
                $"/api/goals/{Guid.NewGuid()}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task UpdateGoal_ShouldUpdateOwnGoal()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    50,
                    startDate,
                    startDate.AddDays(6)));

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(created);

        var updateRequest =
            new UpdateGoalRequest(
                "Calories",
                3000,
                startDate,
                startDate.AddDays(13));

        var response =
            await _client.PutAsJsonAsync(
                $"/api/goals/{created.Id}",
                updateRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var updated =
            await response.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(updated);

        Assert.Equal(
            "Calories",
            updated.Type);

        Assert.Equal(
            3000,
            updated.Target);
    }

    [Fact]
    public async Task DeleteGoal_ShouldDeleteOwnGoal()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    50,
                    startDate,
                    startDate.AddDays(6)));

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(created);

        var deleteResponse =
            await _client.DeleteAsync(
                $"/api/goals/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NoContent,
            deleteResponse.StatusCode);

        var getResponse =
            await _client.GetAsync(
                $"/api/goals/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            getResponse.StatusCode);
    }

    [Fact]
    public async Task CreateGoal_WithInvalidType_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "InvalidGoalType",
            50,
            startDate,
            startDate.AddDays(6));

        var response =
            await _client.PostAsJsonAsync(
                "/api/goals",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateGoal_WithZeroTarget_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            0,
            startDate,
            startDate.AddDays(6));

        var response =
            await _client.PostAsJsonAsync(
                "/api/goals",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateGoal_WithEndDateBeforeStartDate_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            50,
            startDate,
            startDate.AddDays(-1));

        var response =
            await _client.PostAsJsonAsync(
                "/api/goals",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateGoal_WithoutToken_ShouldReturnUnauthorized()
    {
        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        var response =
            await _client.PostAsJsonAsync(
                "/api/goals",
                request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetGoals_WithoutToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync(
                "/api/goals");

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

    [Fact]
    public async Task GetGoalProgress_ShouldReturnDistanceProgress()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var createGoalResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    50,
                    startDate,
                    endDate));

        var goal =
            await createGoalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                10,
                1800,
                300,
                startDate.AddDays(1)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                15,
                2400,
                400,
                startDate.AddDays(2)));

        var response =
            await _client.GetAsync(
                $"/api/goals/{goal.Id}/progress");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var progress =
            await response.Content
                .ReadFromJsonAsync<GoalProgressResponse>();

        Assert.NotNull(progress);

        Assert.Equal(
            goal.Id,
            progress.GoalId);

        Assert.Equal(
            "Distance",
            progress.Type);

        Assert.Equal(
            50,
            progress.Target);

        Assert.Equal(
            25,
            progress.Current);

        Assert.Equal(
            25,
            progress.Remaining);

        Assert.Equal(
            50,
            progress.ProgressPercentage);

        Assert.False(
            progress.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgress_WhenCompleted_ShouldReturn100Percent()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var createGoalResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    20,
                    startDate,
                    endDate));

        var goal =
            await createGoalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                25,
                3600,
                500,
                startDate.AddDays(1)));

        var response =
            await _client.GetAsync(
                $"/api/goals/{goal.Id}/progress");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var progress =
            await response.Content
                .ReadFromJsonAsync<GoalProgressResponse>();

        Assert.NotNull(progress);

        Assert.Equal(
            25,
            progress.Current);

        Assert.Equal(
            0,
            progress.Remaining);

        Assert.Equal(
            100,
            progress.ProgressPercentage);

        Assert.True(
            progress.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgress_WhenGoalBelongsToAnotherUser_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var createGoalResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    50,
                    startDate,
                    endDate));

        var goal =
            await createGoalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        using var secondClient =
            _factory.CreateClient();

        await AuthenticateAsync(secondClient);

        var response =
            await secondClient.GetAsync(
                $"/api/goals/{goal.Id}/progress");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GetGoalProgress_WithoutToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync(
                $"/api/goals/{Guid.NewGuid()}/progress");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetGoalProgress_ShouldReturnDurationProgress()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var createGoalResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Duration",
                    7200,
                    startDate,
                    endDate));

        var goal =
            await createGoalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5,
                1800,
                300,
                startDate.AddDays(1)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20,
                2400,
                500,
                startDate.AddDays(2)));

        var response =
            await _client.GetAsync(
                $"/api/goals/{goal.Id}/progress");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var progress =
            await response.Content
                .ReadFromJsonAsync<GoalProgressResponse>();

        Assert.NotNull(progress);

        Assert.Equal(
            7200,
            progress.Target);

        Assert.Equal(
            4200,
            progress.Current);

        Assert.Equal(
            3000,
            progress.Remaining);

        Assert.Equal(
            58.333333333333336,
            progress.ProgressPercentage);

        Assert.False(
            progress.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgress_ShouldReturnCaloriesProgress()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var createGoalResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Calories",
                    2000,
                    startDate,
                    endDate));

        var goal =
            await createGoalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5,
                1800,
                500,
                startDate.AddDays(1)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20,
                3600,
                700,
                startDate.AddDays(2)));

        var response =
            await _client.GetAsync(
                $"/api/goals/{goal.Id}/progress");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var progress =
            await response.Content
                .ReadFromJsonAsync<GoalProgressResponse>();

        Assert.NotNull(progress);

        Assert.Equal(
            2000,
            progress.Target);

        Assert.Equal(
            1200,
            progress.Current);

        Assert.Equal(
            800,
            progress.Remaining);

        Assert.Equal(
            60,
            progress.ProgressPercentage);

        Assert.False(
            progress.IsCompleted);
    }

    [Fact]
    public async Task GetGoalProgress_ShouldReturnActivitiesProgress()
    {
        await AuthenticateAsync(_client);

        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var createGoalResponse =
            await _client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Activities",
                    5,
                    startDate,
                    endDate));

        var goal =
            await createGoalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        for (var i = 0; i < 3; i++)
        {
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5,
                    1800,
                    300,
                    startDate.AddDays(i + 1)));
        }

        var response =
            await _client.GetAsync(
                $"/api/goals/{goal.Id}/progress");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var progress =
            await response.Content
                .ReadFromJsonAsync<GoalProgressResponse>();

        Assert.NotNull(progress);

        Assert.Equal(
            5,
            progress.Target);

        Assert.Equal(
            3,
            progress.Current);

        Assert.Equal(
            2,
            progress.Remaining);

        Assert.Equal(
            60,
            progress.ProgressPercentage);

        Assert.False(
            progress.IsCompleted);
    }

    [Fact]
public async Task GetGoalProgress_ShouldIgnoreActivitiesOutsideGoalPeriod()
{
    await AuthenticateAsync(_client);

    var startDate = new DateTime(
        2026,
        8,
        10,
        0,
        0,
        0,
        DateTimeKind.Utc);

    var endDate = new DateTime(
        2026,
        8,
        16,
        23,
        59,
        59,
        DateTimeKind.Utc);

    var createGoalResponse =
        await _client.PostAsJsonAsync(
            "/api/goals",
            new CreateGoalRequest(
                "Distance",
                50,
                startDate,
                endDate));

    var goal =
        await createGoalResponse.Content
            .ReadFromJsonAsync<GoalResponse>();

    Assert.NotNull(goal);

    // Before goal period — should be ignored.
    await _client.PostAsJsonAsync(
        "/api/activities",
        new CreateActivityRequest(
            "Run",
            100,
            3600,
            500,
            startDate.AddDays(-1)));

    // Inside goal period — should be included.
    await _client.PostAsJsonAsync(
        "/api/activities",
        new CreateActivityRequest(
            "Run",
            20,
            1800,
            300,
            startDate.AddDays(2)));

    // After goal period — should be ignored.
    await _client.PostAsJsonAsync(
        "/api/activities",
        new CreateActivityRequest(
            "Run",
            200,
            3600,
            800,
            endDate.AddSeconds(1)));

    var response =
        await _client.GetAsync(
            $"/api/goals/{goal.Id}/progress");

    Assert.Equal(
        HttpStatusCode.OK,
        response.StatusCode);

    var progress =
        await response.Content
            .ReadFromJsonAsync<GoalProgressResponse>();

    Assert.NotNull(progress);

    Assert.Equal(
        50,
        progress.Target);

    Assert.Equal(
        20,
        progress.Current);

    Assert.Equal(
        30,
        progress.Remaining);

    Assert.Equal(
        40,
        progress.ProgressPercentage);

    Assert.False(
        progress.IsCompleted);
}
}