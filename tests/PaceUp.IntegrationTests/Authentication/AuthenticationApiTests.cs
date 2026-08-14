using System.Net;
using System.Net.Http.Json;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.IntegrationTests.Infrastructure;
using System.Net.Http.Headers;
using PaceUp.Application.DTOs.Users;


namespace PaceUp.IntegrationTests.Authentication;

public class AuthenticationApiTests
    : IClassFixture<PaceUpIntegrationFixture>
{
    private readonly HttpClient _client;

    public AuthenticationApiTests(
        PaceUpIntegrationFixture fixture)
    {
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
}