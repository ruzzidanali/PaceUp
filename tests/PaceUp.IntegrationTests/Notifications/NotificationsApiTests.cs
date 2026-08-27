using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Notifications;
using PaceUp.Application.DTOs.Users;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Notifications;

public class NotificationsApiTests
    : IClassFixture<PostgreSqlContainerFixture>
{
    private readonly PostgreSqlContainerFixture _database;

    public NotificationsApiTests(
        PostgreSqlContainerFixture database)
    {
        _database = database;
    }

    [Fact]
    public async Task GetNotifications_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client =
            factory.CreateClient();

        var response =
            await client.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetNotifications_WithAuthentication_ShouldReturnEmptyList()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var client =
            factory.CreateClient();

        await AuthenticateAsync(client);

        var response =
            await client.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(result);
        Assert.Empty(result);
    }

    [Fact]
    public async Task FollowUser_ShouldCreateNewFollowerNotification()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var followerClient =
            factory.CreateClient();

        await AuthenticateAsync(
            followerClient);

        var follower =
            await GetCurrentUserAsync(
                followerClient);

        using var targetClient =
            factory.CreateClient();

        var target =
            await RegisterAndAuthenticateAsync(
                targetClient,
                "notification_target");

        var followResponse =
            await followerClient.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followResponse.StatusCode);

        var response =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var notifications =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(notifications);

        var notification =
            Assert.Single(notifications);

        Assert.Equal(
            "NewFollower",
            notification.Type);

        Assert.False(
            notification.IsRead);

        Assert.Equal(
            follower.Id,
            notification.ActorUserId);

        Assert.Equal(
            follower.Username,
            notification.ActorUsername);

        Assert.Equal(
            follower.DisplayName,
            notification.ActorDisplayName);
    }

    [Fact]
    public async Task MarkAsRead_ShouldMarkNotificationAsRead()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var followerClient =
            factory.CreateClient();

        await AuthenticateAsync(
            followerClient);

        var follower =
            await GetCurrentUserAsync(
                followerClient);

        using var targetClient =
            factory.CreateClient();

        var target =
            await RegisterAndAuthenticateAsync(
                targetClient,
                "read_notification_target");

        var followResponse =
            await followerClient.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followResponse.StatusCode);

        var notificationsResponse =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            notificationsResponse.StatusCode);

        var notifications =
            await notificationsResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(notifications);

        var notification =
            Assert.Single(notifications);

        Assert.False(
            notification.IsRead);

        var markReadResponse =
            await targetClient.PatchAsync(
                $"/api/notifications/{notification.Id}/read",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            markReadResponse.StatusCode);

        var afterResponse =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            afterResponse.StatusCode);

        var after =
            await afterResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(after);

        var updated =
            Assert.Single(after);

        Assert.True(
            updated.IsRead);
    }

    [Fact]
    public async Task MarkAsRead_WhenNotificationBelongsToAnotherUser_ShouldReturnNotFound()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var followerClient =
            factory.CreateClient();

        await AuthenticateAsync(
            followerClient);

        var follower =
            await GetCurrentUserAsync(
                followerClient);

        using var targetClient =
            factory.CreateClient();

        var target =
            await RegisterAndAuthenticateAsync(
                targetClient,
                "private_notification_target");

        var followResponse =
            await followerClient.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followResponse.StatusCode);

        var notificationsResponse =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            notificationsResponse.StatusCode);

        var notifications =
            await notificationsResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(notifications);

        var notification =
            Assert.Single(notifications);

        // followerClient must not be able to modify
        // target's notification.
        var unauthorizedReadResponse =
            await followerClient.PatchAsync(
                $"/api/notifications/{notification.Id}/read",
                null);

        Assert.Equal(
            HttpStatusCode.NotFound,
            unauthorizedReadResponse.StatusCode);

        var targetNotificationsResponse =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            targetNotificationsResponse.StatusCode);

        var targetNotifications =
            await targetNotificationsResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(targetNotifications);

        Assert.False(
            Assert.Single(targetNotifications).IsRead);
    }

    [Fact]
    public async Task MarkAllAsRead_ShouldOnlyMarkCurrentUsersNotifications()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var actorClient =
            factory.CreateClient();

        await AuthenticateAsync(
            actorClient);

        var targetClient =
            factory.CreateClient();

        var target =
            await RegisterAndAuthenticateAsync(
                targetClient,
                "mark_all_target");

        var otherTargetClient =
            factory.CreateClient();

        var otherTarget =
            await RegisterAndAuthenticateAsync(
                otherTargetClient,
                "mark_all_other_target");

        var actor =
            await GetCurrentUserAsync(
                actorClient);

        var followTargetResponse =
            await actorClient.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followTargetResponse.StatusCode);

        var followOtherResponse =
            await actorClient.PostAsync(
                $"/api/users/{otherTarget.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            followOtherResponse.StatusCode);

        var beforeResponse =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            beforeResponse.StatusCode);

        var before =
            await beforeResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(before);

        Assert.Single(before);

        Assert.False(
            before[0].IsRead);

        var otherBeforeResponse =
            await otherTargetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            otherBeforeResponse.StatusCode);

        var otherBefore =
            await otherBeforeResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(otherBefore);

        Assert.Single(otherBefore);

        Assert.False(
            otherBefore[0].IsRead);

        var readAllResponse =
            await targetClient.PostAsync(
                "/api/notifications/read-all",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            readAllResponse.StatusCode);

        var afterResponse =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            afterResponse.StatusCode);

        var after =
            await afterResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(after);

        Assert.Single(after);

        Assert.True(
            after[0].IsRead);

        var otherAfterResponse =
            await otherTargetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            otherAfterResponse.StatusCode);

        var otherAfter =
            await otherAfterResponse.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(otherAfter);

        Assert.Single(otherAfter);

        Assert.False(
            otherAfter[0].IsRead);
    }

    [Fact]
    public async Task FollowUser_WhenAlreadyFollowing_ShouldNotCreateDuplicateNotification()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(_database);

        using var followerClient =
            factory.CreateClient();

        await AuthenticateAsync(
            followerClient);

        using var targetClient =
            factory.CreateClient();

        var target =
            await RegisterAndAuthenticateAsync(
                targetClient,
                "duplicate_notification_target");

        var firstFollow =
            await followerClient.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            firstFollow.StatusCode);

        var secondFollow =
            await followerClient.PostAsync(
                $"/api/users/{target.Id}/follow",
                null);

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondFollow.StatusCode);

        var response =
            await targetClient.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var notifications =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<NotificationResponse>>();

        Assert.NotNull(notifications);

        Assert.Single(notifications);
    }

    private static async Task AuthenticateAsync(
        HttpClient client)
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var username =
            $"notification_test_{uniqueId}";

        var email =
            $"{username}@example.com";

        const string password =
            "Password123!";

        var registerResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                new RegisterRequest(
                    username,
                    email,
                    "Notification Test User",
                    password));

        Assert.True(
            registerResponse.IsSuccessStatusCode,
            $"Registration failed: {registerResponse.StatusCode}");

        var loginResponse =
            await client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequest(
                    email,
                    password));

        Assert.True(
            loginResponse.IsSuccessStatusCode,
            $"Login failed: {loginResponse.StatusCode}");

        var auth =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(auth);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                auth.AccessToken);
    }

    private static async Task<UserResponse> RegisterAndAuthenticateAsync(
        HttpClient client,
        string prefix)
    {
        var uniqueId =
            Guid.NewGuid().ToString("N")[..8];

        var safePrefix =
            prefix.Length > 15
                ? prefix[..15]
                : prefix;

        var username =
            $"{safePrefix}_{uniqueId}";

        var email =
            $"{username}@example.com";

        const string password =
            "Password123!";

        var registerResponse =
            await client.PostAsJsonAsync(
                "/api/auth/register",
                new RegisterRequest(
                    username,
                    email,
                    prefix,
                    password));

        Assert.True(
            registerResponse.IsSuccessStatusCode,
            $"Registration failed: {registerResponse.StatusCode}");

        var loginResponse =
            await client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequest(
                    email,
                    password));

        Assert.True(
            loginResponse.IsSuccessStatusCode,
            $"Login failed: {loginResponse.StatusCode}");

        var auth =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(auth);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                auth.AccessToken);

        return await GetCurrentUserAsync(client);
    }

    private static async Task<UserResponse> GetCurrentUserAsync(
        HttpClient client)
    {
        var response =
            await client.GetAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var user =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        return user;
    }
}