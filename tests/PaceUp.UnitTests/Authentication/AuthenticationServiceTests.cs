using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.Exceptions;
using PaceUp.Application.Features.Authentication;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Authentication;

namespace PaceUp.UnitTests.Authentication;

public class AuthenticationServiceTests
{
    [Fact]
    public async Task RegisterAsync_ShouldCreateUserAndIdentity()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
    new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService);

        var request = new RegisterRequest(
            "ruzzidan",
            "ruzzidan@example.com",
            "Ruzzidan",
            "Password123!");

        var result =
            await service.RegisterAsync(
                request,
                CancellationToken.None);

        var user =
            await db.Users
                .SingleAsync(
                    x => x.Id == result.UserId);

        var identity =
            await db.UserIdentities
                .SingleAsync(
                    x => x.UserId == result.UserId);

        Assert.Equal(
            "ruzzidan",
            user.Username);

        Assert.Equal(
            "ruzzidan@example.com",
            user.Email);

        Assert.Equal(
    "test-access-token",
    result.AccessToken);

        Assert.True(
            result.ExpiresAt > DateTime.UtcNow);

        Assert.NotEqual(
            request.Password,
            identity.PasswordHash);

        Assert.True(
            passwordHasher.Verify(
                request.Password,
                identity.PasswordHash));
    }

    [Fact]
    public async Task LoginAsync_WithCorrectPassword_ShouldSucceed()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
    new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService);

        var registerRequest = new RegisterRequest(
            "login_user",
            "login@example.com",
            "Login User",
            "Password123!");

        await service.RegisterAsync(
            registerRequest,
            CancellationToken.None);

        var loginRequest = new LoginRequest(
            "login@example.com",
            "Password123!");

        var result =
            await service.LoginAsync(
                loginRequest,
                CancellationToken.None);

        Assert.Equal(
            "login_user",
            result.Username);

        Assert.Equal(
            "login@example.com",
            result.Email);

        Assert.Equal(
    "test-access-token",
    result.AccessToken);
    }

    [Fact]
    public async Task LoginAsync_WithWrongPassword_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
    new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService);

        await service.RegisterAsync(
            new RegisterRequest(
                "wrong_password_user",
                "wrong@example.com",
                "Wrong Password",
                "CorrectPassword123!"),
            CancellationToken.None);

        var loginRequest = new LoginRequest(
            "wrong@example.com",
            "WrongPassword123!");

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () =>
                service.LoginAsync(
                    loginRequest,
                    CancellationToken.None));
    }

    [Fact]
    public async Task RegisterAsync_WithDuplicateUsername_ShouldThrowConflict()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
    new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService);

        await service.RegisterAsync(
            new RegisterRequest(
                "duplicate_user",
                "first@example.com",
                "First User",
                "Password123!"),
            CancellationToken.None);

        await Assert.ThrowsAsync<ConflictException>(
            () =>
                service.RegisterAsync(
                    new RegisterRequest(
                        "duplicate_user",
                        "second@example.com",
                        "Second User",
                        "Password123!"),
                    CancellationToken.None));
    }

    [Fact]
    public async Task RegisterAsync_WithDuplicateEmail_ShouldThrowConflict()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
    new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService);

        await service.RegisterAsync(
            new RegisterRequest(
                "first_user",
                "same@example.com",
                "First User",
                "Password123!"),
            CancellationToken.None);

        await Assert.ThrowsAsync<ConflictException>(
            () =>
                service.RegisterAsync(
                    new RegisterRequest(
                        "second_user",
                        "same@example.com",
                        "Second User",
                        "Password123!"),
                    CancellationToken.None));
    }

    private static TestDbContext CreateDatabase()
    {
        var options =
            new DbContextOptionsBuilder<TestDbContext>()
                .UseInMemoryDatabase(
                    Guid.NewGuid().ToString())
                .Options;

        return new TestDbContext(options);
    }

    private sealed class TestDbContext
    : DbContext,
      IApplicationDbContext
    {
        public TestDbContext(
            DbContextOptions<TestDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users =>
            Set<User>();

        public DbSet<Activity> Activities =>
            Set<Activity>();

        public DbSet<Goal> Goals =>
            Set<Goal>();

        public DbSet<UserIdentity> UserIdentities =>
            Set<UserIdentity>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<UserIdentity>()
                .HasKey(x => x.UserId);
        }
    }
}