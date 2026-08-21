using System.Net;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.IntegrationTests.Infrastructure;
using System.Net.Http.Headers;
using PaceUp.Application.DTOs.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Infrastructure.Persistence;


namespace PaceUp.IntegrationTests.Authentication;

public class AuthenticationApiTests
    : IClassFixture<PaceUpIntegrationFixture>
{
    private readonly PaceUpIntegrationFixture _fixture;
    private readonly HttpClient _client;

    public AuthenticationApiTests(
    PaceUpIntegrationFixture fixture)
    {
        _fixture = fixture;
        _client = fixture.Factory.CreateClient();
    }

    [Fact]
    public async Task Register_ShouldReturnCreatedUser()
    {
        var request = new RegisterRequest(
            "api_test_user",
            "api_test@example.com",
            "API Test User",
            "Password123!");

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var result =
            await response.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            request.Username,
            result.Username);

        Assert.Equal(
            request.Email,
            result.Email);

        Assert.Equal(
            request.DisplayName,
            result.DisplayName);
    }

    [Fact]
    public async Task Login_ShouldReturnUser()
    {
        var registerRequest = new RegisterRequest(
            "login_api_user",
            "login_api@example.com",
            "Login API User",
            "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var loginRequest = new LoginRequest(
            "login_api@example.com",
            "Password123!");

        var loginResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/login",
                loginRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            loginResponse.StatusCode);

        var result =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(result);

        Assert.Equal(
            registerRequest.Username,
            result.Username);
    }

    [Fact]
    public async Task Login_WithWrongPassword_ShouldReturnUnauthorized()
    {
        var registerRequest = new RegisterRequest(
            "wrong_password_api_user",
            "wrong_password_api@example.com",
            "Wrong Password API User",
            "CorrectPassword123!");

        await _client.PostAsJsonAsync(
            "/api/auth/register",
            registerRequest);

        var loginRequest = new LoginRequest(
            "wrong_password_api@example.com",
            "WrongPassword123!");

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/login",
                loginRequest);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetMe_WithValidToken_ShouldReturnCurrentUser()
    {
        var registerRequest = new RegisterRequest(
            "me_api_user",
            "me_api@example.com",
            "Me API User",
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
                    registerRequest.Email,
                    registerRequest.Password));

        Assert.Equal(
            HttpStatusCode.OK,
            loginResponse.StatusCode);

        var authResponse =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);
        Assert.False(
            string.IsNullOrWhiteSpace(
                authResponse.AccessToken));

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                authResponse.AccessToken);

        var meResponse =
            await _client.GetAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.OK,
            meResponse.StatusCode);

        var user =
            await meResponse.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        Assert.Equal(
            registerRequest.Username,
            user.Username);

        Assert.Equal(
            registerRequest.Email,
            user.Email);

        Assert.Equal(
            registerRequest.DisplayName,
            user.DisplayName);
    }

    [Fact]
    public async Task GetMe_WithoutToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.GetAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task GetMe_WithInvalidToken_ShouldReturnUnauthorized()
    {
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                "this-is-not-a-valid-jwt");

        var response =
            await _client.GetAsync(
                "/api/users/me");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShouldChangePassword()
    {

        var uniqueId = Guid.NewGuid().ToString("N");

        var registerRequest = new RegisterRequest(
            $"change_password_{uniqueId}",
            $"change_password_{uniqueId}@example.com",
            "Change Password User",
            "OldPassword123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var loginRequest = new LoginRequest(
            registerRequest.Email,
            "OldPassword123!");

        var loginResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/login",
                loginRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            loginResponse.StatusCode);

        var authResponse =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                authResponse.AccessToken);

        var changePasswordRequest =
            new ChangePasswordRequest(
                "OldPassword123!",
                "NewPassword456!");

        var changeResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/change-password",
                changePasswordRequest);

        Assert.Equal(
            HttpStatusCode.NoContent,
            changeResponse.StatusCode);

        var newLoginResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequest(
                    registerRequest.Email,
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.OK,
            newLoginResponse.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_WithWrongCurrentPassword_ShouldReturnUnauthorized()
    {

        var uniqueId = Guid.NewGuid().ToString("N");

        var registerRequest = new RegisterRequest(
            $"wrong_password_{uniqueId}",
            $"wrong_password_{uniqueId}@example.com",
            "Wrong Password User",
            "OldPassword123!");

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
                    registerRequest.Email,
                    "OldPassword123!"));

        var authResponse =
            await loginResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                authResponse.AccessToken);

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/change-password",
                new ChangePasswordRequest(
                    "WrongPassword!",
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_WithoutToken_ShouldReturnUnauthorized()
    {

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/change-password",
                new ChangePasswordRequest(
                    "OldPassword123!",
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task VerifyEmail_WithValidToken_ShouldVerifyEmail()
    {
        var uniqueId = Guid.NewGuid().ToString("N");

        var registerRequest = new RegisterRequest(
            $"verify_email_{uniqueId}",
            $"verify_email_{uniqueId}@example.com",
            "Verify Email User",
            "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var authResponse =
            await registerResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        var token =
            await GetVerificationTokenAsync(
                authResponse.UserId);

        var verifyResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/verify-email",
                new VerifyEmailRequest(token));

        Assert.Equal(
            HttpStatusCode.OK,
            verifyResponse.StatusCode);

        var result =
            await verifyResponse.Content
                .ReadFromJsonAsync<EmailVerificationResponse>();

        Assert.NotNull(result);
        Assert.True(result.Verified);

        await AssertEmailVerifiedAsync(
            authResponse.UserId);
    }

    [Fact]
    public async Task VerifyEmail_WithInvalidToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/verify-email",
                new VerifyEmailRequest(
                    "invalid-verification-token"));

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task VerifyEmail_WithUsedToken_ShouldReturnConflict()
    {
        var uniqueId = Guid.NewGuid().ToString("N");

        var registerRequest = new RegisterRequest(
            $"used_token_{uniqueId}",
            $"used_token_{uniqueId}@example.com",
            "Used Token User",
            "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var authResponse =
            await registerResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        var token =
            await GetVerificationTokenAsync(
                authResponse.UserId);

        var firstResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/verify-email",
                new VerifyEmailRequest(token));

        Assert.Equal(
            HttpStatusCode.OK,
            firstResponse.StatusCode);

        var secondResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/verify-email",
                new VerifyEmailRequest(token));

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondResponse.StatusCode);
    }

    [Fact]
    public async Task VerifyEmail_WithExpiredToken_ShouldReturnUnauthorized()
    {
        var uniqueId = Guid.NewGuid().ToString("N");

        var registerRequest = new RegisterRequest(
            $"expired_token_{uniqueId}",
            $"expired_token_{uniqueId}@example.com",
            "Expired Token User",
            "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var authResponse =
            await registerResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        var token =
            await GetVerificationTokenAsync(
                authResponse.UserId);

        await SetTokenExpiredAsync(
            authResponse.UserId,
            token);

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/verify-email",
                new VerifyEmailRequest(token));

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    private async Task<string> GetVerificationTokenAsync(
    Guid userId)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var verificationToken =
            await dbContext.EmailVerificationTokens
                .SingleAsync(
                    x => x.UserId == userId);

        return verificationToken.Token;
    }

    private async Task<string> GetPasswordResetTokenAsync(
    Guid userId)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var resetToken =
            await dbContext.PasswordResetTokens
                .SingleAsync(
                    x => x.UserId == userId);

        return resetToken.Token;
    }

    private async Task SetPasswordResetTokenExpiredAsync(
    Guid userId,
    string token)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var resetToken =
            await dbContext.PasswordResetTokens
                .SingleAsync(
                    x =>
                        x.UserId == userId &&
                        x.Token == token);

        resetToken.Expire();

        await dbContext.SaveChangesAsync();
    }

    private async Task SetTokenExpiredAsync(
    Guid userId,
    string token)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var verificationToken =
            await dbContext.EmailVerificationTokens
                .SingleAsync(
                    x =>
                        x.UserId == userId &&
                        x.Token == token);

        verificationToken.Expire();

        await dbContext.SaveChangesAsync();
    }

    private async Task AssertEmailVerifiedAsync(
    Guid userId)
    {
        using var scope =
            _fixture.Factory.Services
                .CreateScope();

        var dbContext =
            scope.ServiceProvider
                .GetRequiredService<PaceUpDbContext>();

        var identity =
            await dbContext.UserIdentities
                .SingleAsync(
                    x => x.UserId == userId);

        Assert.True(identity.EmailVerified);
    }

    [Fact]
    public async Task ForgotPassword_ShouldReturnNoContent()
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"forgot_api_{uniqueId}",
                $"forgot_api_{uniqueId}@example.com",
                "Forgot API User",
                "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/forgot-password",
                new ForgotPasswordRequest(
                    registerRequest.Email));

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);
    }

    [Fact]
    public async Task ForgotPassword_WithUnknownEmail_ShouldReturnNoContent()
    {
        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/forgot-password",
                new ForgotPasswordRequest(
                    $"unknown_{Guid.NewGuid():N}@example.com"));

        Assert.Equal(
            HttpStatusCode.NoContent,
            response.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_ShouldChangePassword()
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"reset_api_{uniqueId}",
                $"reset_api_{uniqueId}@example.com",
                "Reset API User",
                "OldPassword123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var authResponse =
            await registerResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        var forgotPasswordResponse = await _client.PostAsJsonAsync("/api/auth/forgot-password",
            new ForgotPasswordRequest(registerRequest.Email));

        Assert.Equal(HttpStatusCode.NoContent,
            forgotPasswordResponse.StatusCode);

        var token =
            await GetPasswordResetTokenAsync(
                authResponse.UserId);

        var resetResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/reset-password",
                new ResetPasswordRequest(
                    token,
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.OK,
            resetResponse.StatusCode);

        var result =
            await resetResponse.Content
                .ReadFromJsonAsync<PasswordResetResponse>();

        Assert.NotNull(result);

        Assert.True(
            result.Reset);

        var loginResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequest(
                    registerRequest.Email,
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.OK,
            loginResponse.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_WithInvalidToken_ShouldReturnUnauthorized()
    {
        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/reset-password",
                new ResetPasswordRequest(
                    "invalid-reset-token",
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_WithExpiredToken_ShouldReturnUnauthorized()
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"expired_reset_api_{uniqueId}",
                $"expired_reset_api_{uniqueId}@example.com",
                "Expired Reset API User",
                "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var authResponse =
            await registerResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        var forgotResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/forgot-password",
                new ForgotPasswordRequest(
                    registerRequest.Email));

        Assert.Equal(
            HttpStatusCode.NoContent,
            forgotResponse.StatusCode);

        var token =
            await GetPasswordResetTokenAsync(
                authResponse.UserId);

        await SetPasswordResetTokenExpiredAsync(
            authResponse.UserId,
            token);

        var response =
            await _client.PostAsJsonAsync(
                "/api/auth/reset-password",
                new ResetPasswordRequest(
                    token,
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_WithUsedToken_ShouldReturnConflict()
    {
        var uniqueId =
            Guid.NewGuid().ToString("N");

        var registerRequest =
            new RegisterRequest(
                $"used_reset_api_{uniqueId}",
                $"used_reset_api_{uniqueId}@example.com",
                "Used Reset API User",
                "Password123!");

        var registerResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/register",
                registerRequest);

        Assert.Equal(
            HttpStatusCode.OK,
            registerResponse.StatusCode);

        var authResponse =
            await registerResponse.Content
                .ReadFromJsonAsync<AuthResponse>();

        Assert.NotNull(authResponse);

        var forgotResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/forgot-password",
                new ForgotPasswordRequest(
                    registerRequest.Email));

        Assert.Equal(
            HttpStatusCode.NoContent,
            forgotResponse.StatusCode);

        var token =
            await GetPasswordResetTokenAsync(
                authResponse.UserId);

        var firstResetResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/reset-password",
                new ResetPasswordRequest(
                    token,
                    "NewPassword456!"));

        Assert.Equal(
            HttpStatusCode.OK,
            firstResetResponse.StatusCode);

        var secondResetResponse =
            await _client.PostAsJsonAsync(
                "/api/auth/reset-password",
                new ResetPasswordRequest(
                    token,
                    "AnotherPassword789!"));

        Assert.Equal(
            HttpStatusCode.Conflict,
            secondResetResponse.StatusCode);
    }

}