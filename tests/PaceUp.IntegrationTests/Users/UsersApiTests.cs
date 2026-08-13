using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
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
                _database.ConnectionString);

        using var client = factory.CreateClient();

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
    public async Task GetUser_ShouldReturnExistingUser()
    {
        await using var factory =
            new PaceUpWebApplicationFactory(
                _database.ConnectionString);

        using var client = factory.CreateClient();

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
                _database.ConnectionString);

        using var client = factory.CreateClient();

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
}