using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Feed;
using PaceUp.Application.DTOs.Users;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Feed;

public class FeedApiTests
    : IClassFixture<PaceUpIntegrationFixture>
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly HttpClient _client;

    public FeedApiTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _client = fixture.Factory.CreateClient();
    }

    [Fact]
    public async Task GetFeed_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync("/api/feed");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetFeed_WithAuthentication_ShouldReturnEmptyFeed()
    {
        var token =
            await RegisterAndLoginAsync(
                "feed_empty_user",
                "feed_empty@example.com");

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                "/api/feed?page=1&pageSize=20");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedFeedResponse>();

        Assert.NotNull(result);

        Assert.Empty(result.Activities);

        Assert.Equal(
            1,
            result.Page);

        Assert.Equal(
            20,
            result.PageSize);

        Assert.Equal(
            0,
            result.TotalCount);

        Assert.Equal(
            0,
            result.TotalPages);
    }

    [Fact]
    public async Task GetFeed_WithPagination_ShouldReturnRequestedPage()
    {
        var token =
            await RegisterAndLoginAsync(
                "feed_pagination_user",
                "feed_pagination@example.com");

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                "/api/feed?page=2&pageSize=5");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedFeedResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            2,
            result.Page);

        Assert.Equal(
            5,
            result.PageSize);
    }

    [Fact]
    public async Task GetFeed_ShouldIncludeOwnActivity()
    {
        var token =
            await RegisterAndLoginAsync(
                "feed_own_activity_user",
                "feed_own@example.com");

        SetBearerToken(token);

        var userId =
            await GetUserIdFromRegistrationAsync(
                "feed_own_activity_user",
                "feed_own@example.com");

        await CreateActivityAsync(
            userId,
            "Run",
            5.0,
            1800,
            350,
            DateTime.UtcNow.AddMinutes(-10));

        var response =
            await _client.GetAsync(
                "/api/feed?page=1&pageSize=20");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedFeedResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            1,
            result.TotalCount);

        Assert.Single(
            result.Activities);
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

    private async Task<Guid> GetUserIdFromRegistrationAsync(
        string username,
        string email)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var db =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var user =
            await db.Users
                .SingleAsync(
                    x =>
                        x.Username == username &&
                        x.Email == email);

        return user.Id;
    }

    private async Task CreateActivityAsync(
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
            new PaceUp.Domain.Entities.Activity(
                userId,
                type,
                distance,
                durationSeconds,
                calories,
                startedAt);

        db.Activities.Add(activity);

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
    public async Task GetFeed_ShouldIncludeOwnAndFollowedActivities_ButExcludeUnfollowedUsers()
    {
        var feedUserToken =
            await RegisterAndLoginAsync(
                "feed_owner_user",
                "feed_owner@example.com");

        var feedUserId =
            await GetCurrentUserIdAsync(
                feedUserToken);

        var followedUserToken =
            await RegisterAndLoginAsync(
                "feed_followed_user",
                "feed_followed@example.com");

        var followedUserId =
            await GetCurrentUserIdAsync(
                followedUserToken);

        var otherUserToken =
            await RegisterAndLoginAsync(
                "feed_other_user",
                "feed_other@example.com");

        var otherUserId =
            await GetCurrentUserIdAsync(
                otherUserToken);

        await FollowUserAsync(
            feedUserToken,
            followedUserId);

        await CreateActivityAsync(
            feedUserId,
            "Run",
            5.0,
            1800,
            350,
            DateTime.UtcNow.AddMinutes(-30));

        await CreateActivityAsync(
            followedUserId,
            "Run",
            10.0,
            3600,
            700,
            DateTime.UtcNow.AddMinutes(-20));

        await CreateActivityAsync(
            otherUserId,
            "Run",
            15.0,
            5400,
            1000,
            DateTime.UtcNow.AddMinutes(-10));

        SetBearerToken(feedUserToken);

        var response =
            await _client.GetAsync(
                "/api/feed?page=1&pageSize=20");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<PagedFeedResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            2,
            result.TotalCount);

        Assert.Equal(
            2,
            result.Activities.Count);

        Assert.Contains(
            result.Activities,
            x => x.Username == "feed_owner_user");

        Assert.Contains(
            result.Activities,
            x => x.Username == "feed_followed_user");

        Assert.DoesNotContain(
            result.Activities,
            x => x.Username == "feed_other_user");
    }

    private async Task FollowUserAsync(
        string accessToken,
        Guid userId)
    {
        SetBearerToken(accessToken);

        var response =
            await _client.PostAsync(
                $"/api/users/{userId}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);
    }

    private async Task<Guid> GetCurrentUserIdAsync(
    string accessToken)
    {
        SetBearerToken(accessToken);

        var response =
            await _client.GetAsync("/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(result);

        return result.Id;
    }
}