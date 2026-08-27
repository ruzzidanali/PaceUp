using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Challenges;
using PaceUp.Application.DTOs.Users;
using PaceUp.Application.DTOs.Notifications;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.Challenges;

public class ChallengesApiTests
    : IClassFixture<PaceUpIntegrationFixture>,
      IAsyncLifetime
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly HttpClient _client;

    public ChallengesApiTests(
        PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _client = fixture.Factory.CreateClient();
    }

    public async Task InitializeAsync()
    {
        await _fixture.ResetDatabaseAsync();

        _client.DefaultRequestHeaders.Authorization = null;
    }

    public Task DisposeAsync()
    {
        return Task.CompletedTask;
    }

    [Fact]
    public async Task GetChallenges_WithoutAuthentication_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync("/api/challenges");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task CreateChallenge_ShouldReturnCreatedChallenge()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_create_user",
                "challenge_create@example.com");

        SetBearerToken(token);

        var request =
            CreateRequest(
                "Run 50 KM",
                "Complete 50 kilometres.",
                "Distance",
                50);

        var response =
            await _client.PostAsJsonAsync(
                "/api/challenges",
                request);

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var challenge =
            await response.Content
                .ReadFromJsonAsync<ChallengeResponse>();

        Assert.NotNull(challenge);

        Assert.Equal(
            "Run 50 KM",
            challenge.Name);

        Assert.Equal(
            "Complete 50 kilometres.",
            challenge.Description);

        Assert.Equal(
            "Distance",
            challenge.Type);

        Assert.Equal(
            50,
            challenge.TargetValue);

        Assert.Equal(
            0,
            challenge.ParticipantCount);
    }

    [Fact]
    public async Task CreateChallenge_WithInvalidRequest_ShouldReturnBadRequest()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_invalid_user",
                "challenge_invalid@example.com");

        SetBearerToken(token);

        var request =
            CreateRequest(
                "",
                null,
                "Distance",
                0);

        var response =
            await _client.PostAsJsonAsync(
                "/api/challenges",
                request);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    [Fact]
    public async Task GetChallenges_ShouldReturnCreatedChallenges()
    {
        await _fixture.ResetDatabaseAsync();

        var token =
            await RegisterAndLoginAsync(
                "challenge_get_user",
                "challenge_get@example.com");

        SetBearerToken(token);

        await CreateChallengeAsync(
            "Distance Challenge",
            "Distance challenge.",
            "Distance",
            50);

        await CreateChallengeAsync(
            "Duration Challenge",
            "Duration challenge.",
            "Duration",
            3600);

        var response =
            await _client.GetAsync(
                "/api/challenges");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var challenges =
            await response.Content
                .ReadFromJsonAsync<
                    IReadOnlyList<ChallengeResponse>>();

        Assert.NotNull(challenges);

        Assert.Equal(
            2,
            challenges.Count);

        Assert.Contains(
            challenges,
            x => x.Name == "Distance Challenge");

        Assert.Contains(
            challenges,
            x => x.Name == "Duration Challenge");
    }

    [Fact]
    public async Task GetChallengeById_ShouldReturnChallenge()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_get_by_id_user",
                "challenge_get_by_id@example.com");

        SetBearerToken(token);

        var created =
            await CreateChallengeAsync(
                "Get By Id Challenge",
                "Description",
                "Distance",
                100);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var challenge =
            await response.Content
                .ReadFromJsonAsync<ChallengeResponse>();

        Assert.NotNull(challenge);

        Assert.Equal(
            created.Id,
            challenge.Id);

        Assert.Equal(
            "Get By Id Challenge",
            challenge.Name);
    }

    [Fact]
    public async Task GetChallengeById_WhenChallengeDoesNotExist_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_missing_user",
                "challenge_missing@example.com");

        SetBearerToken(token);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{Guid.NewGuid()}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task UpdateChallenge_ShouldReturnUpdatedChallenge()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_update_user",
                "challenge_update@example.com");

        SetBearerToken(token);

        var created =
            await CreateChallengeAsync(
                "Original Challenge",
                "Original description.",
                "Distance",
                50);

        var request =
            new UpdateChallengeRequest(
                "Updated Challenge",
                "Updated description.",
                "Duration",
                7200,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(10));

        var response =
            await _client.PutAsJsonAsync(
                $"/api/challenges/{created.Id}",
                request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var challenge =
            await response.Content
                .ReadFromJsonAsync<ChallengeResponse>();

        Assert.NotNull(challenge);

        Assert.Equal(
            "Updated Challenge",
            challenge.Name);

        Assert.Equal(
            "Updated description.",
            challenge.Description);

        Assert.Equal(
            "Duration",
            challenge.Type);

        Assert.Equal(
            7200,
            challenge.TargetValue);
    }

    [Fact]
    public async Task UpdateChallenge_WhenNotOwner_ShouldReturnNotFound()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "challenge_owner_user",
                "challenge_owner@example.com");

        SetBearerToken(ownerToken);

        var created =
            await CreateChallengeAsync(
                "Owner Challenge",
                null,
                "Distance",
                50);

        var otherToken =
            await RegisterAndLoginAsync(
                "challenge_other_user",
                "challenge_other@example.com");

        SetBearerToken(otherToken);

        var request =
            new UpdateChallengeRequest(
                "Hijacked Challenge",
                null,
                "Distance",
                100,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(7));

        var response =
            await _client.PutAsJsonAsync(
                $"/api/challenges/{created.Id}",
                request);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task DeleteChallenge_ShouldReturnNoContent()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_delete_user",
                "challenge_delete@example.com");

        SetBearerToken(token);

        var created =
            await CreateChallengeAsync(
                "Delete Challenge",
                null,
                "Distance",
                25);

        var response =
            await _client.DeleteAsync(
                $"/api/challenges/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);

        var getResponse =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            getResponse.StatusCode);
    }

    [Fact]
    public async Task DeleteChallenge_WhenNotOwner_ShouldReturnNotFound()
    {
        var ownerToken =
            await RegisterAndLoginAsync(
                "challenge_delete_owner",
                "challenge_delete_owner@example.com");

        SetBearerToken(ownerToken);

        var created =
            await CreateChallengeAsync(
                "Protected Challenge",
                null,
                "Distance",
                25);

        var otherToken =
            await RegisterAndLoginAsync(
                "challenge_delete_other",
                "challenge_delete_other@example.com");

        SetBearerToken(otherToken);

        var response =
            await _client.DeleteAsync(
                $"/api/challenges/{created.Id}");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task JoinChallenge_ShouldReturnNoContent()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_join_creator",
                "challenge_join_creator@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Join Challenge",
                null,
                "Distance",
                50);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_join_user",
                "challenge_join_user@example.com");

        SetBearerToken(participantToken);

        var response =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);

        var challenge =
            await GetChallengeAsync(
                created.Id);

        Assert.NotNull(challenge);

        Assert.Equal(
            1,
            challenge.ParticipantCount);
    }

    [Fact]
    public async Task JoinChallenge_ShouldCreateNotificationForChallengeCreator()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_notification_creator",
                "challenge_notification_creator@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Notification Challenge",
                "Challenge notification test.",
                "Distance",
                50);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_notification_user",
                "challenge_notification_user@example.com");

        SetBearerToken(participantToken);

        var joinResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            joinResponse.StatusCode);

        SetBearerToken(creatorToken);

        var response =
            await _client.GetAsync(
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

        var notification =
            notifications[0];

        Assert.Equal(
            "ChallengeJoined",
            notification.Type);

        Assert.False(
            notification.IsRead);
    }

    [Fact]
    public async Task JoinChallenge_Twice_ShouldReturnConflict()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_duplicate_creator",
                "challenge_duplicate_creator@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Duplicate Join Challenge",
                null,
                "Distance",
                50);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_duplicate_user",
                "challenge_duplicate_user@example.com");

        SetBearerToken(participantToken);

        var firstResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            firstResponse.StatusCode);

        var secondResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondResponse.StatusCode);
    }

    [Fact]
    public async Task JoinChallenge_WhenChallengeDoesNotExist_ShouldReturnNotFound()
    {
        var token =
            await RegisterAndLoginAsync(
                "challenge_join_missing",
                "challenge_join_missing@example.com");

        SetBearerToken(token);

        var response =
            await _client.PostAsync(
                $"/api/challenges/{Guid.NewGuid()}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task LeaveChallenge_ShouldReturnNoContent()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_leave_creator",
                "challenge_leave_creator@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Leave Challenge",
                null,
                "Distance",
                50);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_leave_user",
                "challenge_leave_user@example.com");

        SetBearerToken(participantToken);

        var joinResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            joinResponse.StatusCode);

        var leaveResponse =
            await _client.DeleteAsync(
                $"/api/challenges/{created.Id}/join");

        Assert.Equal(
            HttpStatusCode.NoContent,
            leaveResponse.StatusCode);

        var challenge =
            await GetChallengeAsync(
                created.Id);

        Assert.NotNull(challenge);

        Assert.Equal(
            0,
            challenge.ParticipantCount);
    }

    [Fact]
    public async Task LeaveChallenge_WhenNotParticipant_ShouldReturnNotFound()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_leave_missing_creator",
                "challenge_leave_missing_creator@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Leave Missing Challenge",
                null,
                "Distance",
                50);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_leave_missing_user",
                "challenge_leave_missing_user@example.com");

        SetBearerToken(participantToken);

        var response =
            await _client.DeleteAsync(
                $"/api/challenges/{created.Id}/join");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GetProgress_WhenParticipant_ShouldReturnProgress()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_progress_creator",
                "challenge_progress_creator@example.com");

        SetBearerToken(creatorToken);

        var startDate =
            DateTime.UtcNow.Date.AddDays(-1);

        var endDate =
            DateTime.UtcNow.Date.AddDays(7);

        var created =
            await CreateChallengeAsync(
                "Progress Challenge",
                null,
                "Distance",
                10,
                startDate,
                endDate);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_progress_user",
                "challenge_progress_user@example.com");

        SetBearerToken(participantToken);

        var joinResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            joinResponse.StatusCode);

        var userId =
            await GetCurrentUserIdAsync(
                participantToken);

        await CreateActivityAsync(
            userId,
            "Run",
            4,
            1800,
            300,
            DateTime.UtcNow);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}/progress");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var progress =
            await response.Content
                .ReadFromJsonAsync<ChallengeProgressResponse>();

        Assert.NotNull(progress);

        Assert.Equal(
            created.Id,
            progress.ChallengeId);

        Assert.Equal(
            participantToken is not null
                ? userId
                : Guid.Empty,
            progress.UserId);

        Assert.Equal(
            "Distance",
            progress.Type);

        Assert.Equal(
            10,
            progress.TargetValue);

        Assert.Equal(
            4,
            progress.CurrentValue);

        Assert.Equal(
            6,
            progress.RemainingValue);

        Assert.Equal(
            40,
            progress.ProgressPercentage);

        Assert.False(
            progress.IsCompleted);
    }

    [Fact]
    public async Task GetProgress_WhenNotParticipant_ShouldReturnNotFound()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_progress_owner",
                "challenge_progress_owner@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Private Progress Challenge",
                null,
                "Distance",
                10);

        var otherToken =
            await RegisterAndLoginAsync(
                "challenge_progress_other",
                "challenge_progress_other@example.com");

        SetBearerToken(otherToken);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}/progress");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GetLeaderboard_ShouldReturnParticipantsOrderedByProgress()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_leaderboard_creator",
                "challenge_leaderboard_creator@example.com");

        SetBearerToken(creatorToken);

        var startDate =
            DateTime.UtcNow.Date.AddDays(-1);

        var endDate =
            DateTime.UtcNow.Date.AddDays(7);

        var created =
            await CreateChallengeAsync(
                "Leaderboard Challenge",
                null,
                "Distance",
                100,
                startDate,
                endDate);

        var firstUserToken =
            await RegisterAndLoginAsync(
                "challenge_leaderboard_first",
                "challenge_leaderboard_first@example.com");

        var firstUserId =
            await GetCurrentUserIdAsync(
                firstUserToken);

        SetBearerToken(firstUserToken);

        var firstJoinResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            firstJoinResponse.StatusCode);

        await CreateActivityAsync(
            firstUserId,
            "Run",
            10,
            3600,
            500,
            DateTime.UtcNow);

        var secondUserToken =
            await RegisterAndLoginAsync(
                "challenge_leaderboard_second",
                "challenge_leaderboard_second@example.com");

        var secondUserId =
            await GetCurrentUserIdAsync(
                secondUserToken);

        SetBearerToken(secondUserToken);

        var secondJoinResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            secondJoinResponse.StatusCode);

        await CreateActivityAsync(
            secondUserId,
            "Run",
            20,
            3600,
            700,
            DateTime.UtcNow);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}/leaderboard");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var leaderboard =
            await response.Content
                .ReadFromJsonAsync<ChallengeLeaderboardResponse>();

        Assert.NotNull(leaderboard);

        Assert.Equal(
            created.Id,
            leaderboard.ChallengeId);

        Assert.Equal(
            2,
            leaderboard.Participants.Count);

        Assert.Equal(
            "challenge_leaderboard_second",
            leaderboard.Participants[0].Username);

        Assert.Equal(
            20,
            leaderboard.Participants[0].CurrentValue);

        Assert.Equal(
            1,
            leaderboard.Participants[0].Rank);

        Assert.Equal(
            "challenge_leaderboard_first",
            leaderboard.Participants[1].Username);

        Assert.Equal(
            10,
            leaderboard.Participants[1].CurrentValue);

        Assert.Equal(
            2,
            leaderboard.Participants[1].Rank);
    }

    [Fact]
    public async Task GetLeaderboard_WhenNotParticipant_ShouldReturnNotFound()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_leaderboard_owner",
                "challenge_leaderboard_owner@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Private Leaderboard Challenge",
                null,
                "Distance",
                100);

        var otherToken =
            await RegisterAndLoginAsync(
                "challenge_leaderboard_other",
                "challenge_leaderboard_other@example.com");

        SetBearerToken(otherToken);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}/leaderboard");

        Assert.Equal(
            HttpStatusCode.NotFound,
            response.StatusCode);
    }

    [Fact]
    public async Task GetChallenge_ShouldReturnParticipantCount()
    {
        var creatorToken =
            await RegisterAndLoginAsync(
                "challenge_count_creator",
                "challenge_count_creator@example.com");

        SetBearerToken(creatorToken);

        var created =
            await CreateChallengeAsync(
                "Participant Count Challenge",
                null,
                "Distance",
                100);

        var participantToken =
            await RegisterAndLoginAsync(
                "challenge_count_user",
                "challenge_count_user@example.com");

        SetBearerToken(participantToken);

        var joinResponse =
            await _client.PostAsync(
                $"/api/challenges/{created.Id}/join",
                null);

        Assert.Equal(
            HttpStatusCode.NoContent,
            joinResponse.StatusCode);

        var response =
            await _client.GetAsync(
                $"/api/challenges/{created.Id}");

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var challenge =
            await response.Content
                .ReadFromJsonAsync<ChallengeResponse>();

        Assert.NotNull(challenge);

        Assert.Equal(
            1,
            challenge.ParticipantCount);
    }

    private CreateChallengeRequest CreateRequest(
        string name,
        string? description,
        string type,
        double target,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        var start =
            startDate ??
            DateTime.UtcNow.Date;

        return new CreateChallengeRequest(
            name,
            description,
            type,
            target,
            start,
            endDate ?? start.AddDays(7));
    }

    private async Task<ChallengeResponse> CreateChallengeAsync(
        string name,
        string? description,
        string type,
        double target,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        var request =
            CreateRequest(
                name,
                description,
                type,
                target,
                startDate,
                endDate);

        var response =
            await _client.PostAsJsonAsync(
                "/api/challenges",
                request);

        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var challenge =
            await response.Content
                .ReadFromJsonAsync<ChallengeResponse>();

        Assert.NotNull(challenge);

        return challenge;
    }

    private async Task<ChallengeResponse?> GetChallengeAsync(
        Guid challengeId)
    {
        var response =
            await _client.GetAsync(
                $"/api/challenges/{challengeId}");

        if (response.StatusCode ==
            HttpStatusCode.NotFound)
        {
            return null;
        }

        response.EnsureSuccessStatusCode();

        return await response.Content
            .ReadFromJsonAsync<ChallengeResponse>();
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
}