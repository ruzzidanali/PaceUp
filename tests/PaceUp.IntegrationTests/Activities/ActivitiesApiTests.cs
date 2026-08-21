using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.IntegrationTests.Infrastructure;
using Microsoft.AspNetCore.Mvc;

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
    public async Task GetActivityStats_WithDateRange_ShouldReturnStatisticsWithinRange()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                new DateTime(
                    2026, 7, 25,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                10.0,
                3600,
                600,
                new DateTime(
                    2026, 8, 10,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20.0,
                5400,
                800,
                new DateTime(
                    2026, 8, 12,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Walk",
                3.0,
                1800,
                150,
                new DateTime(
                    2026, 8, 20,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        var response =
            await _client.GetAsync(
                "/api/activities/stats" +
                "?from=2026-08-01T00:00:00Z" +
                "&to=2026-08-15T23:59:59Z");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var stats =
            await response.Content
                .ReadFromJsonAsync<ActivityStatsResponse>();

        Assert.NotNull(stats);

        Assert.Equal(
            2,
            stats.TotalActivities);

        Assert.Equal(
            30.0,
            stats.TotalDistance);

        Assert.Equal(
            9000,
            stats.TotalDurationSeconds);

        Assert.Equal(
            1400,
            stats.TotalCalories);

        Assert.Equal(
            2,
            stats.ActivitiesByType.Count);

        Assert.Equal(
            1,
            stats.ActivitiesByType["Run"]);

        Assert.Equal(
            1,
            stats.ActivitiesByType["Ride"]);
    }

    [Fact]
    public async Task GetActivityStats_WithTypeAndDateRange_ShouldReturnMatchingStatistics()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                new DateTime(
                    2026, 8, 10,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                10.0,
                3600,
                600,
                new DateTime(
                    2026, 8, 12,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                50.0,
                7200,
                1200,
                new DateTime(
                    2026, 8, 12,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                20.0,
                5400,
                900,
                new DateTime(
                    2026, 8, 20,
                    10, 0, 0,
                    DateTimeKind.Utc)));

        var response =
            await _client.GetAsync(
                "/api/activities/stats" +
                "?type=Run" +
                "&from=2026-08-01T00:00:00Z" +
                "&to=2026-08-15T23:59:59Z");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var stats =
            await response.Content
                .ReadFromJsonAsync<ActivityStatsResponse>();

        Assert.NotNull(stats);

        Assert.Equal(
            2,
            stats.TotalActivities);

        Assert.Equal(
            15.0,
            stats.TotalDistance);

        Assert.Equal(
            5400,
            stats.TotalDurationSeconds);

        Assert.Equal(
            900,
            stats.TotalCalories);

        Assert.Single(
            stats.ActivitiesByType);

        Assert.Equal(
            2,
            stats.ActivitiesByType["Run"]);

        Assert.DoesNotContain(
            "Ride",
            stats.ActivitiesByType.Keys);
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

    [Fact]
    public async Task GetActivities_WithPagination_ShouldReturnCorrectPage()
    {
        await AuthenticateAsync(_client);

        for (var i = 1; i <= 5; i++)
        {
            var response =
                await _client.PostAsJsonAsync(
                    "/api/activities",
                    new CreateActivityRequest(
                        "Run",
                        i,
                        1800,
                        300,
                        DateTime.UtcNow.AddMinutes(i)));

            Assert.Equal(
                HttpStatusCode.Created,
                response.StatusCode);
        }

        var paginationResponse =
            await _client.GetAsync(
                "/api/activities?page=2&pageSize=2");

        Assert.Equal(
            HttpStatusCode.OK,
            paginationResponse.StatusCode);

        var paginationResult =
            await paginationResponse.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(paginationResult);

        Assert.Equal(2, paginationResult.Page);
        Assert.Equal(2, paginationResult.PageSize);
        Assert.Equal(5, paginationResult.TotalCount);
        Assert.Equal(3, paginationResult.TotalPages);

        Assert.Equal(2, paginationResult.Items.Count);
    }

    [Fact]
    public async Task GetMine_WithFromDate_ShouldReturnActivitiesOnOrAfterDate()
    {
        await AuthenticateAsync(_client);

        var olderResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5,
                    1800,
                    300,
                    new DateTime(
                        2026,
                        8,
                        1,
                        10,
                        0,
                        0,
                        DateTimeKind.Utc)));

        var newerResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    7,
                    2400,
                    400,
                    new DateTime(
                        2026,
                        8,
                        15,
                        10,
                        0,
                        0,
                        DateTimeKind.Utc)));

        Assert.Equal(
            HttpStatusCode.Created,
            olderResponse.StatusCode);

        Assert.Equal(
            HttpStatusCode.Created,
            newerResponse.StatusCode);

        var response =
            await _client.GetAsync(
                "/api/activities?from=2026-08-10T00:00:00Z");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(result);

        Assert.Single(result.Items);

        Assert.Equal(
            7,
            result.Items[0].Distance);
    }

    [Fact]
    public async Task GetMine_WithToDate_ShouldReturnActivitiesOnOrBeforeDate()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5,
                1800,
                300,
                new DateTime(
                    2026,
                    8,
                    1,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                7,
                2400,
                400,
                new DateTime(
                    2026,
                    8,
                    15,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        var response =
            await _client.GetAsync(
                "/api/activities?to=2026-08-10T00:00:00Z");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(result);

        Assert.Single(result.Items);

        Assert.Equal(
            5,
            result.Items[0].Distance);
    }

    [Fact]
    public async Task GetMine_WithDateRange_ShouldReturnActivitiesWithinRange()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                3,
                1200,
                200,
                new DateTime(
                    2026,
                    7,
                    31,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5,
                1800,
                300,
                new DateTime(
                    2026,
                    8,
                    10,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                7,
                2400,
                400,
                new DateTime(
                    2026,
                    8,
                    20,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        var response =
            await _client.GetAsync(
                "/api/activities" +
                "?from=2026-08-01T00:00:00Z" +
                "&to=2026-08-15T23:59:59Z");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(result);

        Assert.Single(result.Items);

        Assert.Equal(
            5,
            result.Items[0].Distance);
    }

    [Fact]
    public async Task GetMine_WithTypeAndDateRange_ShouldApplyBothFilters()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5,
                1800,
                300,
                new DateTime(
                    2026,
                    8,
                    10,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                50,
                3600,
                1000,
                new DateTime(
                    2026,
                    8,
                    10,
                    12,
                    0,
                    0,
                    DateTimeKind.Utc)));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                8,
                3000,
                500,
                new DateTime(
                    2026,
                    8,
                    20,
                    10,
                    0,
                    0,
                    DateTimeKind.Utc)));

        var response =
            await _client.GetAsync(
                "/api/activities" +
                "?type=Run" +
                "&from=2026-08-01T00:00:00Z" +
                "&to=2026-08-15T23:59:59Z");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(result);

        Assert.Single(result.Items);

        Assert.Equal(
            "Run",
            result.Items[0].Type);

        Assert.Equal(
            5,
            result.Items[0].Distance);
    }

    [Fact]
    public async Task GetActivities_WithTypeFilter_ShouldReturnOnlyMatchingActivities()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                20.0,
                3600,
                800,
                DateTime.UtcNow));

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                10.0,
                3600,
                600,
                DateTime.UtcNow));

        var filterResponse =
            await _client.GetAsync(
                "/api/activities?type=Run");

        Assert.Equal(
            HttpStatusCode.OK,
            filterResponse.StatusCode);

        var filterResult =
            await filterResponse.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(filterResult);

        Assert.Equal(2, filterResult.TotalCount);
        Assert.Equal(2, filterResult.Items.Count);

        Assert.All(
            filterResult.Items,
            activity =>
                Assert.Equal(
                    "Run",
                    activity.Type));
    }

    [Fact]
    public async Task GetActivities_WithTypeFilterAndPagination_ShouldReturnCorrectResults()
    {
        await AuthenticateAsync(_client);

        for (var i = 1; i <= 5; i++)
        {
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    i,
                    1800,
                    300,
                    DateTime.UtcNow.AddMinutes(i)));
        }

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Ride",
                50,
                7200,
                1500,
                DateTime.UtcNow));

        var combinedResponse =
            await _client.GetAsync(
                "/api/activities?type=Run&page=2&pageSize=2");

        Assert.Equal(
            HttpStatusCode.OK,
            combinedResponse.StatusCode);

        var combinedResult =
            await combinedResponse.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(combinedResult);

        Assert.Equal(2, combinedResult.Page);
        Assert.Equal(2, combinedResult.PageSize);

        Assert.Equal(5, combinedResult.TotalCount);
        Assert.Equal(3, combinedResult.TotalPages);

        Assert.Equal(2, combinedResult.Items.Count);

        Assert.All(
            combinedResult.Items,
            activity =>
                Assert.Equal(
                    "Run",
                    activity.Type));
    }

    [Fact]
    public async Task GetActivities_WithPageSizeAboveMaximum_ShouldLimitTo100()
    {
        await AuthenticateAsync(_client);

        var pageSizeResponse =
            await _client.GetAsync(
                "/api/activities?page=1&pageSize=500");

        Assert.Equal(
            HttpStatusCode.OK,
            pageSizeResponse.StatusCode);

        var pageSizeResult =
            await pageSizeResponse.Content
                .ReadFromJsonAsync<PagedActivityResponse>();

        Assert.NotNull(pageSizeResult);

        Assert.Equal(
            100,
            pageSizeResult.PageSize);
    }

    [Fact]
    public async Task CreateActivity_WithInvalidType_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var request = new CreateActivityRequest(
            "InvalidActivityType",
            5,
            1800,
            300,
            DateTime.UtcNow);

        var response =
            await _client.PostAsJsonAsync(
                "/api/activities",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);

        var problemDetails =
            await response.Content
                .ReadFromJsonAsync<ValidationProblemDetails>();

        Assert.NotNull(problemDetails);

        Assert.Equal(
            400,
            problemDetails.Status);

        Assert.Equal(
            "One or more validation errors occurred.",
            problemDetails.Title);

        Assert.True(
            problemDetails.Errors.ContainsKey("Type"));

        Assert.Contains(
            "Activity type is not supported.",
            problemDetails.Errors["Type"]);
    }

    [Fact]
    public async Task CreateActivity_WithNegativeDistance_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var request = new CreateActivityRequest(
            "Run",
            -5,
            1800,
            300,
            DateTime.UtcNow);

        var response =
            await _client.PostAsJsonAsync(
                "/api/activities",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateActivity_WithZeroDuration_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var request = new CreateActivityRequest(
            "Run",
            5,
            0,
            300,
            DateTime.UtcNow);

        var response =
            await _client.PostAsJsonAsync(
                "/api/activities",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateActivity_WithNegativeCalories_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var request = new CreateActivityRequest(
            "Run",
            5,
            1800,
            -100,
            DateTime.UtcNow);

        var response =
            await _client.PostAsJsonAsync(
                "/api/activities",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task UpdateActivity_WithNegativeDistance_ShouldReturnBadRequest()
    {
        await AuthenticateAsync(_client);

        var createResponse =
            await _client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5,
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
                "Run",
                -10,
                1800,
                300,
                DateTime.UtcNow);

        var response =
            await _client.PutAsJsonAsync(
                $"/api/activities/{created.Id}",
                updateRequest);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task GetActivityStats_ShouldOnlyReturnCurrentUsersStatistics()
    {
        await AuthenticateAsync(_client);

        await _client.PostAsJsonAsync(
            "/api/activities",
            new CreateActivityRequest(
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow));

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
            1,
            stats.TotalActivities);

        Assert.Equal(
            5.0,
            stats.TotalDistance);

        Assert.Equal(
            1800,
            stats.TotalDurationSeconds);

        Assert.Equal(
            300,
            stats.TotalCalories);

        Assert.Single(
            stats.ActivitiesByType);

        Assert.Equal(
            1,
            stats.ActivitiesByType["Run"]);

        Assert.DoesNotContain(
            "Ride",
            stats.ActivitiesByType.Keys);
    }
}