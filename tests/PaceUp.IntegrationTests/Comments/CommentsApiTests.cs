using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Comments;
using PaceUp.Application.DTOs.Users;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Comments;

public class CommentsApiTests
    : IClassFixture<PaceUpIntegrationFixture>,
      IAsyncLifetime
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly HttpClient _client;

    public CommentsApiTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _client = fixture.Factory.CreateClient();
    }

    public async Task InitializeAsync()
    {
        await _fixture.ResetDatabaseAsync();
    }

    public Task DisposeAsync()
    {
        return Task.CompletedTask;
    }

    [Fact]
    public async Task GetComments_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        var activityId = Guid.NewGuid();

        var response =
    await _client.GetAsync(
        $"/api/activities/{activityId}/comments");


        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetComments_WithExistingActivity_ShouldReturnEmptyList()
    {
        var token =
            await RegisterAndLoginAsync(
                "comments_empty",
                "comments_empty@example.com");

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
                $"/api/activities/{activityId}/comments");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedCommentResponse>();

        Assert.NotNull(result);

        Assert.Empty(result.Comments);

        Assert.Equal(
            0,
            result.TotalCount);

        Assert.Equal(
            0,
            result.TotalPages);
    }

    [Fact]
    public async Task GetComments_ForMissingActivity_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "comments_missing",
                "comments_missing@example.com");

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                $"/api/activities/{Guid.NewGuid()}/comments");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    private async Task<string> RegisterAndLoginAsync(
        string username,
        string email)
    {
        var registerRequest =
            new RegisterRequest(
                username,
                email,
                username,
                "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

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
            _fixture.Factory.Services
                .CreateScope();

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

    private void SetBearerToken(
        string accessToken)
    {
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);
    }
}