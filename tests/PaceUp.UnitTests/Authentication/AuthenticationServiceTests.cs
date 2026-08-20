using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.Exceptions;
using PaceUp.Application.Features.Authentication;
using PaceUp.Domain.Entities;
using PaceUp.Infrastructure.Authentication;

namespace PaceUp.UnitTests.Authentication;

public class FakeEmailVerificationTokenService
    : IEmailVerificationTokenService
{
    private readonly string _token;

    public FakeEmailVerificationTokenService(
        string token)
    {
        _token = token;
    }

    public string GenerateToken()
    {
        return _token;
    }
}

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

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

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

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

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

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

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

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

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

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

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

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<UserIdentity>()
                .HasKey(x => x.UserId);

            modelBuilder.Entity<EmailVerificationToken>()
                .HasKey(x => x.Id);
        }
    }

    [Fact]
    public async Task ChangePasswordAsync_WithCorrectCurrentPassword_ShouldSucceed()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
            new FakeJwtTokenService();

        var user =
            new User(
                "change_password_user",
                "change@example.com",
                "Change Password User");

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash("OldPassword123!"));

        db.Users.Add(user);
        db.UserIdentities.Add(identity);

        await db.SaveChangesAsync();

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

        var request =
            new ChangePasswordRequest(
                "OldPassword123!",
                "NewPassword456!");

        await service.ChangePasswordAsync(
            user.Id,
            request,
            CancellationToken.None);

        var updatedIdentity =
            await db.UserIdentities
                .SingleAsync(
                    x => x.UserId == user.Id);

        Assert.True(
            passwordHasher.Verify(
                "NewPassword456!",
                updatedIdentity.PasswordHash));

        Assert.False(
            passwordHasher.Verify(
                "OldPassword123!",
                updatedIdentity.PasswordHash));
    }

    [Fact]
    public async Task ChangePasswordAsync_WithIncorrectCurrentPassword_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
            new FakeJwtTokenService();

        var user =
            new User(
                "change_password_user",
                "change@example.com",
                "Change Password User");

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash("OldPassword123!"));

        db.Users.Add(user);
        db.UserIdentities.Add(identity);

        await db.SaveChangesAsync();

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

        var request =
            new ChangePasswordRequest(
                "WrongPassword!",
                "NewPassword456!");

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.ChangePasswordAsync(
                user.Id,
                request,
                CancellationToken.None));
    }

    [Fact]
    public async Task ChangePasswordAsync_WhenUserIdentityDoesNotExist_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService);

        var request =
            new ChangePasswordRequest(
                "OldPassword123!",
                "NewPassword456!");

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.ChangePasswordAsync(
                Guid.NewGuid(),
                request,
                CancellationToken.None));
    }

    [Fact]
    public async Task RegisterAsync_ShouldCreateEmailVerificationToken()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var tokenService =
            new FakeEmailVerificationTokenService(
                "test-verification-token");

        var jwtTokenService =
            new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                tokenService);

        var request = new RegisterRequest(
            "verification_user",
            "verification@example.com",
            "Verification User",
            "Password123!");

        var result =
            await service.RegisterAsync(
                request,
                CancellationToken.None);

        var token =
            await db.EmailVerificationTokens
                .SingleAsync(
                    x => x.UserId == result.UserId);

        Assert.Equal(
            "test-verification-token",
            token.Token);

        Assert.True(
            token.ExpiresAt > DateTime.UtcNow);

        Assert.False(token.IsUsed());
    }
}