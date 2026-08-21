using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.DTOs.Users;
using PaceUp.Infrastructure.Persistence;
using PaceUp.IntegrationTests.Infrastructure;

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

        var request =
            new UpdateProfileImageRequest(
                "https://example.com/profile.jpg");

        var response =
            await client.PutAsJsonAsync(
                "/api/users/me/profile-image",
                request);

        Assert.Equal(
            HttpStatusCode.OK,
            response.StatusCode);

        var user =
            await response.Content
                .ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(user);

        Assert.Equal(
            "https://example.com/profile.jpg",
            user.ProfileImageUrl);
    }

    [Fact]
    public async Task UpdateProfileImage_WithoutToken_ShouldReturnUnauthorized()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database);

        using var client = factory.CreateClient();

        var request =
            new UpdateProfileImageRequest(
                "https://example.com/profile.jpg");

        var response =
            await client.PutAsJsonAsync(
                "/api/users/me/profile-image",
                request);

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            response.StatusCode);
    }
}