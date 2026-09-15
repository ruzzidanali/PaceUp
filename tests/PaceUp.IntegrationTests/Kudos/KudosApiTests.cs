using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Notifications;
using PaceUp.Application.DTOs.Users;
using PaceUp.Domain.Constants;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;
using PaceUp.Application.DTOs.Kudos;

namespace PaceUp.IntegrationTests.Kudos;

public class KudosApiTests
    : IClassFixture<PaceUpIntegrationFixture>
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly HttpClient _client;

    public KudosApiTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _client = fixture.Factory.CreateClient();
    }

    [Fact]
    public async Task GetKudos_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        var activityId = Guid.NewGuid();

        var response =
            await _client.GetAsync(
                $"/api/activities/{activityId}/kudos");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetKudos_WithExistingActivity_ShouldReturnCountAndStatus()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_get_owner",
                "kudos_get_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_get_giver",
                "kudos_get_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var giverId =
            await GetCurrentUserIdAsync(giverToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                5.0,
                1800,
                350,
                DateTime.UtcNow.AddMinutes(-10));

        await CreateKudosAsync(
            activityId,
            giverId);

        SetBearerToken(giverToken);

        var response =
            await _client.GetAsync(
                $"/api/activities/{activityId}/kudos");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<KudosResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            activityId,
            result.ActivityId);

        Assert.Equal(
            1,
            result.KudosCount);

        Assert.True(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task GetKudos_ForMissingActivity_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "kudos_missing_get",
                "kudos_missing_get@example.com");

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                $"/api/activities/{Guid.NewGuid()}/kudos");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GiveKudos_ShouldReturnUpdatedCountAndStatus()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_give_owner",
                "kudos_give_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_give_giver",
                "kudos_give_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                10.0,
                3600,
                700,
                DateTime.UtcNow.AddMinutes(-20));

        SetBearerToken(giverToken);

        var response =
            await _client.PostAsync(
                $"/api/activities/{activityId}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<KudosResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            activityId,
            result.ActivityId);

        Assert.Equal(
            1,
            result.KudosCount);

        Assert.True(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task GiveKudos_Twice_ShouldNotCreateDuplicate()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_duplicate_owner",
                "kudos_duplicate_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_duplicate_giver",
                "kudos_duplicate_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                5.0,
                1800,
                300,
                DateTime.UtcNow.AddMinutes(-15));

        SetBearerToken(giverToken);

        var firstResponse =
            await _client.PostAsync(
                $"/api/activities/{activityId}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.OK,
            firstResponse.StatusCode);

        var secondResponse =
            await _client.PostAsync(
                $"/api/activities/{activityId}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.OK,
            secondResponse.StatusCode);

        var result =
            await secondResponse.Content
                .ReadFromJsonAsync<KudosResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            1,
            result.KudosCount);

        Assert.True(
            result.HasGivenKudos);

        var kudosCount =
            await GetKudosCountAsync(activityId);

        Assert.Equal(
            1,
            kudosCount);
    }

    [Fact]
    public async Task GiveKudos_ToOwnActivity_ShouldReturnBadRequest()
    {
        var token =
            await RegisterAndLoginAsync(
                "kudos_self_owner",
                "kudos_self_owner@example.com");

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
            await _client.PostAsync(
                $"/api/activities/{activityId}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task GiveKudos_ForMissingActivity_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "kudos_missing_give",
                "kudos_missing_give@example.com");

        SetBearerToken(token);

        var response =
            await _client.PostAsync(
                $"/api/activities/{Guid.NewGuid()}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GiveKudos_ShouldCreateActivityKudosNotification()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_notification_owner",
                "kudos_notification_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_notification_giver",
                "kudos_notification_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                8.0,
                2400,
                500,
                DateTime.UtcNow.AddMinutes(-20));

        SetBearerToken(giverToken);

        var response =
            await _client.PostAsync(
                $"/api/activities/{activityId}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var notifications =
            await GetNotificationsAsync(ownerToken);

        Assert.Contains(
            notifications,
            x =>
                x.Type == NotificationTypes.ActivityKudos &&
                x.ActorUserId != ownerId);
    }

    [Fact]
    public async Task RemoveKudos_ShouldReturnUpdatedCountAndStatus()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_remove_owner",
                "kudos_remove_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_remove_giver",
                "kudos_remove_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                6.0,
                2000,
                400,
                DateTime.UtcNow.AddMinutes(-15));

        SetBearerToken(giverToken);

        var giveResponse =
            await _client.PostAsync(
                $"/api/activities/{activityId}/kudos",
                null);

        Assert.Equal(
            HttpStatusCode.OK,
            giveResponse.StatusCode);

        var removeResponse =
            await _client.DeleteAsync(
                $"/api/activities/{activityId}/kudos");

        Assert.Equal(
            HttpStatusCode.OK,
            removeResponse.StatusCode);

        var result =
            await removeResponse.Content
                .ReadFromJsonAsync<KudosResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            activityId,
            result.ActivityId);

        Assert.Equal(
            0,
            result.KudosCount);

        Assert.False(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task RemoveKudos_WithoutExistingKudos_ShouldBeIdempotent()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_remove_idempotent_owner",
                "kudos_remove_idempotent_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_remove_idempotent_giver",
                "kudos_remove_idempotent_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                4.0,
                1500,
                250,
                DateTime.UtcNow.AddMinutes(-10));

        SetBearerToken(giverToken);

        var response =
            await _client.DeleteAsync(
                $"/api/activities/{activityId}/kudos");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<KudosResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            0,
            result.KudosCount);

        Assert.False(
            result.HasGivenKudos);
    }

    [Fact]
    public async Task RemoveKudos_ForMissingActivity_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "kudos_missing_remove",
                "kudos_missing_remove@example.com");

        SetBearerToken(token);

        var response =
            await _client.DeleteAsync(
                $"/api/activities/{Guid.NewGuid()}/kudos");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task RemoveKudos_ShouldNotCreateNotification()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "kudos_no_remove_notification_owner",
                "kudos_no_remove_notification_owner@example.com");

        var giverToken =
            await RegisterAndLoginAsync(
                "kudos_no_remove_notification_giver",
                "kudos_no_remove_notification_giver@example.com");

        var ownerId =
            await GetCurrentUserIdAsync(ownerToken);

        var activityId =
            await CreateActivityAsync(
                ownerId,
                "Run",
                7.0,
                2100,
                450,
                DateTime.UtcNow.AddMinutes(-20));

        SetBearerToken(giverToken);

        await _client.PostAsync(
            $"/api/activities/{activityId}/kudos",
            null);

        var notificationsBefore =
            await GetNotificationsAsync(ownerToken);

        var kudosNotificationsBefore =
            notificationsBefore.Count(
                x =>
                    x.Type ==
                    NotificationTypes.ActivityKudos);

        await _client.DeleteAsync(
            $"/api/activities/{activityId}/kudos");

        var notificationsAfter =
            await GetNotificationsAsync(ownerToken);

        var kudosNotificationsAfter =
            notificationsAfter.Count(
                x =>
                    x.Type ==
                    NotificationTypes.ActivityKudos);

        Assert.Equal(
            kudosNotificationsBefore,
            kudosNotificationsAfter);
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

    private async Task CreateKudosAsync(
        Guid activityId,
        Guid userId)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var db =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        db.Kudos.Add(
    new PaceUp.Domain.Entities.Kudos(
        activityId,
        userId));

        await db.SaveChangesAsync();
    }

    private async Task<int> GetKudosCountAsync(
        Guid activityId)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var db =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        return await db.Kudos.CountAsync(
            x => x.ActivityId == activityId);
    }

    private async Task<List<NotificationResponse>> GetNotificationsAsync(
        string accessToken)
    {
        SetBearerToken(accessToken);

        var response =
            await _client.GetAsync(
                "/api/notifications");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<List<NotificationResponse>>();

        Assert.NotNull(result);

        return result;
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