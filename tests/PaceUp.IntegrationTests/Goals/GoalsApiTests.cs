using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Goals;
using PaceUp.IntegrationTests.Infrastructure;

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
}