using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Activities;

public class ActivitiesApiTests
    : IClassFixture<PostgreSqlContainerFixture>
{
    private readonly PostgreSqlContainerFixture _database;
    private readonly PaceUpWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public ActivitiesApiTests(
        PostgreSqlContainerFixture database)
    {
        _database = database;

        _factory =
            new PaceUpWebApplicationFactory(
                _database);

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task CreateActivity_ShouldReturnCreatedActivity()
    {
        await AuthenticateAsync(_client);

        var request = new CreateActivityRequest(
            "Run",
            5.42,
            1938,
            412,
            new DateTime(
                2026,
                8,
                14,
                7,
                30,
                0,
                DateTimeKind.Utc));

        var response =
            await _client.PostAsJsonAsync(
                "/api/activities",
                request);

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var activity =
            await response.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(activity);

        Assert.NotEqual(
            Guid.Empty,
            activity.Id);

        Assert.Equal(
            "Run",
            activity.Type);

        Assert.Equal(
            5.42,
            activity.Distance);

        Assert.Equal(
            1938,
            activity.DurationSeconds);

        Assert.Equal(
            412,
            activity.Calories);

        Assert.Equal(
            request.StartedAt,
            activity.StartedAt);
    }

    [Fact]
    public async Task GetActivities_ShouldReturnCurrentUsersActivities()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow.AddDays(-1)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20,
                3600,
                800,
                DateTime.UtcNow));

        var response =
            await _client.GetAsync(
                "/api/activities");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
    await response.Content
        .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            2,
            result.TotalCount);

        Assert.Equal(
            1,
            result.Page);

        Assert.Equal(
            20,
            result.PageSize);

        Assert.Equal(
            1,
            result.TotalPages);

        Assert.Equal(
            2,
            result.Items.Count);

        Assert.Equal(
            "Ride",
            result.Items[0].Type);

        Assert.Equal(
            "Run",
            result.Items[1].Type);
    }

    [Fact]
    public async Task GetActivity_ShouldReturnOwnActivity()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    10,
                    3600,
                    700,
                    DateTime.UtcNow));

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(created);

        var response =
            await _client.GetAsync(
                $"/api/activities/{created.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var activity =
            await response.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(activity);

        Assert.Equal(
            created.Id,
            activity.Id);
    }

    [Fact]
    public async Task GetActivityStats_ShouldReturnCurrentUsersStatistics()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddDays(-2)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20.0,
                3600,
                800,
                DateTime.UtcNow.AddDays(-1)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Walk",
                3.5,
                2400,
                null,
                DateTime.UtcNow));

        var response =
            await _client.GetAsync(
                "/api/activities/stats");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var stats =
            await response.Content
                .ReadFromJsonAsync<ActivityStatsResponse>();

        Assert.NotNull(stats);

        Assert.Equal(
            3,
            stats.TotalActivities);

        Assert.Equal(
            28.5,
            stats.TotalDistance);

        Assert.Equal(
            7800,
            stats.TotalDurationSeconds);

        Assert.Equal(
            1100,
            stats.TotalCalories);
    }

    [Fact]
    public async Task GetActivityStats_WithoutToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync(
                "/api/activities/stats");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetActivity_WithoutToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync(
                $"/api/activities/{Guid.NewGuid()}");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateActivity_WithoutToken_ShouldReturnUnauthorized()
    {
        var request = new CreateActivityRequest(
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        var response =
            await _client.PostAsJsonAsync(
                "/api/activities",
                request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
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

    [Fact]
    public async Task UpdateActivity_ShouldUpdateOwnActivity()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            createResponse.StatusCode);

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(created);

        var updateRequest =
            new UpdateActivityRequest(
                "Ride",
                25.5,
                4200,
                950,
                DateTime.UtcNow.AddHours(-1));

        var updateResponse =
            await _client.PutAsJsonAsync(
                $"/api/activities/{created.Id}",
                updateRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            updateResponse.StatusCode);

        var updated =
            await updateResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(updated);

        Assert.Equal(
            created.Id,
            updated.Id);

        Assert.Equal(
            "Ride",
            updated.Type);

        Assert.Equal(
            25.5,
            updated.Distance);

        Assert.Equal(
            4200,
            updated.DurationSeconds);

        Assert.Equal(
            950,
            updated.Calories);
    }

    [Fact]
    public async Task UpdateActivity_WhenNotFound_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var request =
            new UpdateActivityRequest(
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow);

        var response =
            await _client.PutAsJsonAsync(
                $"/api/activities/{Guid.NewGuid()}",
                request);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task DeleteActivity_ShouldDeleteOwnActivity()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            createResponse.StatusCode);

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(created);

        var deleteResponse =
            await _client.DeleteAsync(
                $"/api/activities/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NoContent,
            deleteResponse.StatusCode);

        var getResponse =
            await _client.GetAsync(
                $"/api/activities/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            getResponse.StatusCode);
    }

    [Fact]
    public async Task DeleteActivity_WhenNotFound_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var response =
            await _client.DeleteAsync(
                $"/api/activities/{Guid.NewGuid()}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GetActivity_WhenOwnedByAnotherUser_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            createResponse.StatusCode);

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(created);

        await using var secondFactory =
            new PaceUpWebApplicationFactory(
                _database
            );

        using var secondClient =
            secondFactory.CreateClient();

        await AuthenticateAsync(secondClient);

        var response =
            await secondClient.GetAsync(
                $"/api/activities/{created.Id}"
            );

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode
        );
    }

    [Fact]
    public async Task UpdateActivity_WhenOwnedByAnotherUser_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            createResponse.StatusCode);

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(created);

        await using var secondFactory =
            new PaceUpWebApplicationFactory(
                _database);

        using var secondClient =
            secondFactory.CreateClient();

        await AuthenticateAsync(secondClient);

        var updateRequest =
            new UpdateActivityRequest(
                "Ride",
                100,
                7200,
                2000,
                DateTime.UtcNow);

        var response =
            await secondClient.PutAsJsonAsync(
                $"/api/activities/{created.Id}",
                updateRequest);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);

        var ownerResponse =
            await _client.GetAsync(
                $"/api/activities/{created.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            ownerResponse.StatusCode);

        var activity =
            await ownerResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(activity);

        Assert.Equal(
            "Run",
            activity.Type);

        Assert.Equal(
            5.0,
            activity.Distance);
    }

    [Fact]
    public async Task DeleteActivity_WhenOwnedByAnotherUser_ShouldReturnNotFound()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            createResponse.StatusCode);

        var created =
            await createResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(created);

        await using var secondFactory =
            new PaceUpWebApplicationFactory(
                _database);

        using var secondClient =
            secondFactory.CreateClient();

        await AuthenticateAsync(secondClient);

        var response =
            await secondClient.DeleteAsync(
                $"/api/activities/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);

        var ownerResponse =
            await _client.GetAsync(
                $"/api/activities/{created.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            ownerResponse.StatusCode);
    }

    [Fact]
    public async Task GetActivities_ShouldOnlyReturnCurrentUsersActivities()
    {
        await AuthenticateAsync(_client);

        var ownerActivityResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            ownerActivityResponse.StatusCode);

        var ownerActivity =
            await ownerActivityResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(ownerActivity);

        await using var secondFactory =
            new PaceUpWebApplicationFactory(
                _database);

        using var secondClient =
            secondFactory.CreateClient();

        await AuthenticateAsync(secondClient);

        var secondUserActivityResponse =
            await secondClient.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Ride",
                    20.0,
                    3600,
                    800,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            secondUserActivityResponse.StatusCode);

        var secondUserActivity =
            await secondUserActivityResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(secondUserActivity);

        var response =
            await secondClient.GetAsync(
                "/api/activities");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            1,
            result.TotalCount);

        Assert.Equal(
            1,
            result.Page);

        Assert.Equal(
            20,
            result.PageSize);

        Assert.Equal(
            1,
            result.TotalPages);

        Assert.Single(
            result.Items);

        Assert.Equal(
            secondUserActivity.Id,
            result.Items[0].Id);

        Assert.Equal(
            "Ride",
            result.Items[0].Type);

        Assert.Equal(
            20.0,
            result.Items[0].Distance);

        Assert.NotEqual(
            ownerActivity.Id,
            result.Items[0].Id);
    }
}