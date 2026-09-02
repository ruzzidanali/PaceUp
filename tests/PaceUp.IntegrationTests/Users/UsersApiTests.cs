using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Users;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.DTOs.Goals;

namespace PaceUp.IntegrationTests.Users;

public class UsersApiTests
    : IClassFixture<PostgreSqlContainerFixture>
{
    private readonly PostgreSqlContainerFixture _database;

    public UsersApiTests(
        PostgreSqlContainerFixture database)
    {
        _database = database;
    }

    [Fact]
    public async Task CreateUser_ShouldReturnCreatedUser()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var request = new CreateUserRequest(
            "integration_user",
            "integration@example.com",
            "Integration User");

        var response = await client.PostAsJsonAsync(
            "/api/users",
            request);

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var user =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        Assert.Equal(
            "integration_user",
            user.Username);

        Assert.Equal(
            "integration@example.com",
            user.Email);

        using var scope =
            factory.Services.CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var savedUser =
            await dbContext.Users
                .SingleAsync(
                    x => x.Username == "integration_user");

        Assert.Equal(
            "integration@example.com",
            savedUser.Email);
    }

    [Fact]
    public async Task UpdateMyProfile_ShouldReturnUpdatedUser()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var request =
            new UpdateProfileRequest(
                "Updated Name",
                "Updated bio");

        var response =
            await client.PutAsJsonAsync(
                "/api/users/me",
                request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var user =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        Assert.Equal(
            "Updated Name",
            user.DisplayName);

        Assert.Equal(
            "Updated bio",
            user.Bio);
    }

    [Fact]
    public async Task UpdateMyProfile_WithEmptyDisplayName_ShouldReturnBadRequest()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var request =
            new UpdateProfileRequest(
                "",
                "Updated bio");

        var response =
            await client.PutAsJsonAsync(
                "/api/users/me",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task GetUser_ShouldReturnExistingUser()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var createRequest = new CreateUserRequest(
            "get_user",
            "get@example.com",
            "Get User");

        var createResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                createRequest);

        createResponse.EnsureSuccessStatusCode();

        var createdUser =
            await createResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(createdUser);

        var response =
            await client.GetAsync(
                $"/api/users/{createdUser.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var user =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        Assert.Equal(
            createdUser.Id,
            user.Id);

        Assert.Equal(
            "get_user",
            user.Username);
    }

    [Fact]
    public async Task CreateUser_WithDuplicateUsername_ShouldReturnConflict()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var firstRequest = new CreateUserRequest(
            "duplicate_user",
            "first@example.com",
            "First User");

        var firstResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                firstRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            firstResponse.StatusCode);

        var duplicateRequest = new CreateUserRequest(
            "duplicate_user",
            "second@example.com",
            "Second User");

        var secondResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                duplicateRequest);

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondResponse.StatusCode);
    }

    private static async Task AuthenticateAsync(
        HttpClient client)
    {
        var uniqueId = Guid.NewGuid().ToString("N");

        var registerRequest = new RegisterRequest(
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
            $"Registration failed with status {registerResponse.StatusCode}.");

        var loginRequest = new LoginRequest(
    $"test_auth_{uniqueId}@example.com",
    "Password123!");

        var loginResponse =
            await client.PostAsJsonAsync(
                "/api/auth/login",
                loginRequest);

        Assert.True(
            loginResponse.IsSuccessStatusCode,
            $"Login failed with status {loginResponse.StatusCode}.");

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
    public async Task GetUser_WithoutToken_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        var response =
            await client.GetAsync(
                $"/api/users/{Guid.NewGuid()}");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateUser_WithoutToken_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        var request = new CreateUserRequest(
            "unauthorized_user",
            "unauthorized@example.com",
            "Unauthorized User");

        var response =
            await client.PostAsJsonAsync(
                "/api/users",
                request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task UpdateMe_ShouldUpdateProfile()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var request = new UpdateProfileRequest(
            "Updated Integration User",
            "This is my updated bio.");

        var response =
            await client.PutAsJsonAsync(
                "/api/users/me",
                request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var user =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        Assert.Equal(
            "Updated Integration User",
            user.DisplayName);

        Assert.Equal(
            "This is my updated bio.",
            user.Bio);
    }

    [Fact]
public async Task UpdateProfileImage_ShouldReturnUpdatedUser()
{
    await using var factory =
        new PaceUpWebApplicationFactory(
            _database);

    using var client = factory.CreateClient();

    await AuthenticateAsync(client);

    using var content = new MultipartFormDataContent();

    var imageBytes = new byte[]
    {
        0xFF, 0xD8, 0xFF, 0xE0,
        0x00, 0x10,
        0x4A, 0x46, 0x49, 0x46,
        0x00, 0x01,
        0xFF, 0xD9
    };

    var imageContent =
        new ByteArrayContent(imageBytes);

    imageContent.Headers.ContentType =
        new MediaTypeHeaderValue("image/jpeg");

    content.Add(
        imageContent,
        "file",
        "profile.jpg");

    var response =
        await client.PutAsync(
            "/api/users/me/profile-image",
            content);

    Assert.Equal(
        HttpStatusCode.OK,
        response.StatusCode);

    var user =
        await response.Content
            .ReadFromJsonAsync<UserResponse>();

    Assert.NotNull(user);
    Assert.NotNull(user.ProfileImageUrl);

    Assert.Contains(
        "/uploads/profile-images/",
        user.ProfileImageUrl);

    Assert.EndsWith(
        ".jpg",
        user.ProfileImageUrl);
}

    [Fact]
public async Task UpdateProfileImage_WithoutToken_ShouldReturnUnauthorized()
{
    await using var factory =
        new PaceUpWebApplicationFactory(
            _database);

    using var client = factory.CreateClient();

    using var content = new MultipartFormDataContent();

    var imageBytes = new byte[]
    {
        0xFF, 0xD8, 0xFF, 0xE0,
        0x00, 0x10,
        0x4A, 0x46, 0x49, 0x46,
        0x00, 0x01,
        0xFF, 0xD9
    };

    var imageContent =
        new ByteArrayContent(imageBytes);

    imageContent.Headers.ContentType =
        new MediaTypeHeaderValue("image/jpeg");

    content.Add(
        imageContent,
        "file",
        "profile.jpg");

    var response =
        await client.PutAsync(
            "/api/users/me/profile-image",
            content);

    Assert.Equal(
        HttpStatusCode.Unauthorized,
        response.StatusCode);
}

    [Fact]
    public async Task DeleteMe_ShouldDeleteCurrentUser()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var meResponse =
            await client.GetAsync("/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            meResponse.StatusCode);

        var user =
            await meResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        var response =
            await client.DeleteAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);

        var getResponse =
            await client.GetAsync(
                $"/api/users/{user.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            getResponse.StatusCode);
    }

    [Fact]
    public async Task DeleteMe_WithoutToken_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        var response =
            await client.DeleteAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task DeleteMe_ShouldCascadeDeleteUserData()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        var meResponse =
            await client.GetAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            meResponse.StatusCode);

        var user =
            await meResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        var activityResponse =
            await client.PostAsJsonAsync(
                "/api/activities",
                new CreateActivityRequest(
                    "Run",
                    5.0,
                    1800,
                    300,
                    DateTime.UtcNow));

        Assert.Equal(
            HttpStatusCode.Created,
            activityResponse.StatusCode);

        var activity =
            await activityResponse.Content
                .ReadFromJsonAsync<ActivityResponse>();

        Assert.NotNull(activity);

        var goalResponse =
            await client.PostAsJsonAsync(
                "/api/goals",
                new CreateGoalRequest(
                    "Distance",
                    50.0,
                    DateTime.UtcNow.AddDays(-1),
                    DateTime.UtcNow.AddDays(30)));

        Assert.Equal(
            HttpStatusCode.Created,
            goalResponse.StatusCode);

        var goal =
            await goalResponse.Content
                .ReadFromJsonAsync<GoalResponse>();

        Assert.NotNull(goal);

        var deleteResponse =
            await client.DeleteAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.NoContent,
            deleteResponse.StatusCode);

        var userResponse =
            await client.GetAsync(
                $"/api/users/{user.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            userResponse.StatusCode);

        var activityGetResponse =
            await client.GetAsync(
                $"/api/activities/{activity.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            activityGetResponse.StatusCode);

        var goalGetResponse =
            await client.GetAsync(
                $"/api/goals/{goal.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            goalGetResponse.StatusCode);
    }

    [Fact]
    public async Task FollowUser_ShouldReturnNoContent()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var targetRequest = new CreateUserRequest(
            $"follow_target_{Guid.NewGuid():N}",
            $"follow_target_{Guid.NewGuid():N}@example.com",
            "Follow Target");

        var targetResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                targetRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            targetResponse.StatusCode);

        var target =
            await targetResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(target);

        var response =
            await client.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);
    }

    [Fact]
    public async Task FollowUser_ShouldAppearInFollowersAndFollowing()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var meResponse =
            await client.GetAsync("/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            meResponse.StatusCode);

        var me =
            await meResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(me);

        var targetRequest = new CreateUserRequest(
            $"followers_target_{Guid.NewGuid():N}",
            $"followers_target_{Guid.NewGuid():N}@example.com",
            "Followers Target");

        var targetResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                targetRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            targetResponse.StatusCode);

        var target =
            await targetResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(target);

        var followResponse =
            await client.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followResponse.StatusCode);

        var followingResponse =
            await client.GetAsync(
                $"/api/users/{me.Id}/following");

        Assert.Equal(
            HttpStatusCode.OK,
            followingResponse.StatusCode);

        var following =
            await followingResponse.Content
                .ReadFromJsonAsync<FollowListResponse>();

        Assert.NotNull(following);

        Assert.Contains(
            following.Users,
            x => x.UserId == target.Id);

        var followersResponse =
            await client.GetAsync(
                $"/api/users/{target.Id}/followers");

        Assert.Equal(
            HttpStatusCode.OK,
            followersResponse.StatusCode);

        var followers =
            await followersResponse.Content
                .ReadFromJsonAsync<FollowListResponse>();

        Assert.NotNull(followers);

        Assert.Contains(
            followers.Users,
            x => x.UserId == me.Id);
    }

    [Fact]
    public async Task UnfollowUser_ShouldReturnNoContent()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var targetRequest = new CreateUserRequest(
            $"unfollow_target_{Guid.NewGuid():N}",
            $"unfollow_target_{Guid.NewGuid():N}@example.com",
            "Unfollow Target");

        var targetResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                targetRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            targetResponse.StatusCode);

        var target =
            await targetResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(target);

        var followResponse =
            await client.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followResponse.StatusCode);

        var unfollowResponse =
            await client.DeleteAsync(
                $"/api/users/{target.Id}/follow");

        Assert.Equal(
            HttpStatusCode.NoContent,
            unfollowResponse.StatusCode);

        var followingResponse =
            await client.GetAsync(
                $"/api/users/{target.Id}/followers");

        Assert.Equal(
            HttpStatusCode.OK,
            followingResponse.StatusCode);

        var followers =
            await followingResponse.Content
                .ReadFromJsonAsync<FollowListResponse>();

        Assert.NotNull(followers);

        Assert.DoesNotContain(
            followers.Users,
            x => x.UserId == target.Id);
    }

    [Fact]
    public async Task FollowUser_WhenTargetDoesNotExist_ShouldReturnNotFound()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var response =
            await client.PostAsync(
                $"/api/users/{Guid.NewGuid()}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task UnfollowUser_WhenNotFollowing_ShouldReturnNotFound()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var targetRequest = new CreateUserRequest(
            $"not_following_{Guid.NewGuid():N}",
            $"not_following_{Guid.NewGuid():N}@example.com",
            "Not Following");

        var targetResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                targetRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            targetResponse.StatusCode);

        var target =
            await targetResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(target);

        var response =
            await client.DeleteAsync(
                $"/api/users/{target.Id}/follow");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task FollowUser_WhenFollowingSelf_ShouldReturnConflict()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var meResponse =
            await client.GetAsync("/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            meResponse.StatusCode);

        var me =
            await meResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(me);

        var response =
            await client.PostAsync(
                $"/api/users/{me.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.Conflict,
            response.StatusCode);
    }

    [Fact]
    public async Task FollowUser_WhenAlreadyFollowing_ShouldReturnConflict()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        await AuthenticateAsync(client);

        var targetRequest = new CreateUserRequest(
            $"duplicate_follow_{Guid.NewGuid():N}",
            $"duplicate_follow_{Guid.NewGuid():N}@example.com",
            "Duplicate Follow");

        var targetResponse =
            await client.PostAsJsonAsync(
                "/api/users",
                targetRequest);

        Assert.Equal(
            HttpStatusCode.Created,
            targetResponse.StatusCode);

        var target =
            await targetResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(target);

        var firstFollow =
            await client.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            firstFollow.StatusCode);

        var secondFollow =
            await client.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondFollow.StatusCode);
    }

    [Fact]
    public async Task FollowUser_WithoutToken_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client = factory.CreateClient();

        var response =
            await client.PostAsync(
                $"/api/users/{Guid.NewGuid()}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }
}