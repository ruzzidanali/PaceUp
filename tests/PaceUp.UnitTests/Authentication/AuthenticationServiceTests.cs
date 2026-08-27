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

public class FakePasswordResetTokenService
    : IPasswordResetTokenService
{
    private readonly string _token;

    public FakePasswordResetTokenService(
        string token)
    {
        _token = token;
    }

    public string GenerateToken()
    {
        return _token;
    }
}

public class FakeRefreshTokenService
    : IRefreshTokenService
{
    private readonly string _token;

    public FakeRefreshTokenService(
        string token)
    {
        _token = token;
    }

    public Task<string> CreateAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return Task.FromResult(_token);
    }

    public Task<Guid?> ValidateAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        return Task.FromResult<Guid?>(null);
    }

    public Task RevokeAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    public Task<string?> RotateAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        return Task.FromResult<string?>(null);
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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
            "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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
    public async Task LoginAsync_WithWrongPassword_ShouldIncrementFailedLoginAttempts()
    {
        await using var db = CreateDatabase();

        var passwordHasher = new Argon2PasswordHasher();
        var tokenService = new FakeJwtTokenService();
        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "test-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var registerRequest = new RegisterRequest(
            "failed_login_user",
            "failed_login@example.com",
            "Failed Login User",
            "Password123!");

        await service.RegisterAsync(
            registerRequest,
            CancellationToken.None);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.LoginAsync(
                new LoginRequest(
                    registerRequest.Email,
                    "WrongPassword!"),
                CancellationToken.None));

        var identity =
            await db.UserIdentities
                .SingleAsync();

        Assert.Equal(
            1,
            identity.FailedLoginAttempts);

        Assert.Null(identity.LockedUntil);
    }

    [Fact]
    public async Task LoginAsync_AfterFiveFailedAttempts_ShouldLockAccount()
    {
        await using var db = CreateDatabase();

        var passwordHasher = new Argon2PasswordHasher();
        var tokenService = new FakeJwtTokenService();
        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "test-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var registerRequest = new RegisterRequest(
            "lockout_user",
            "lockout@example.com",
            "Lockout User",
            "Password123!");

        await service.RegisterAsync(
            registerRequest,
            CancellationToken.None);

        for (var attempt = 0; attempt < 5; attempt++)
        {
            await Assert.ThrowsAsync<UnauthorizedAccessException>(
                () => service.LoginAsync(
                    new LoginRequest(
                        registerRequest.Email,
                        "WrongPassword!"),
                    CancellationToken.None));
        }

        var identity =
            await db.UserIdentities
                .SingleAsync();

        Assert.Equal(
            5,
            identity.FailedLoginAttempts);

        Assert.NotNull(identity.LockedUntil);
        Assert.True(
            identity.LockedUntil > DateTime.UtcNow);
    }
    [Fact]
    public async Task LoginAsync_WhenAccountIsLocked_ShouldRejectCorrectPassword()
    {
        await using var db = CreateDatabase();

        var passwordHasher = new Argon2PasswordHasher();
        var tokenService = new FakeJwtTokenService();
        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "test-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var registerRequest = new RegisterRequest(
            "locked_correct_password",
            "locked_correct@example.com",
            "Locked Correct Password",
            "Password123!");

        var result =
            await service.RegisterAsync(
                registerRequest,
                CancellationToken.None);

        var identity =
            await db.UserIdentities
                .SingleAsync(
                    x => x.UserId == result.UserId);

        for (var attempt = 0; attempt < 5; attempt++)
        {
            await Assert.ThrowsAsync<UnauthorizedAccessException>(
                () => service.LoginAsync(
                    new LoginRequest(
                        registerRequest.Email,
                        "WrongPassword!"),
                    CancellationToken.None));
        }

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.LoginAsync(
                new LoginRequest(
                    registerRequest.Email,
                    registerRequest.Password),
                CancellationToken.None));
    }

    [Fact]
    public async Task LoginAsync_WithCorrectPassword_ShouldResetFailedLoginAttempts()
    {
        await using var db = CreateDatabase();

        var passwordHasher = new Argon2PasswordHasher();
        var tokenService = new FakeJwtTokenService();
        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "test-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var registerRequest = new RegisterRequest(
            "reset_failed_attempts",
            "reset_failed@example.com",
            "Reset Failed Attempts",
            "Password123!");

        var result =
            await service.RegisterAsync(
                registerRequest,
                CancellationToken.None);

        for (var attempt = 0; attempt < 3; attempt++)
        {
            await Assert.ThrowsAsync<UnauthorizedAccessException>(
                () => service.LoginAsync(
                    new LoginRequest(
                        registerRequest.Email,
                        "WrongPassword!"),
                    CancellationToken.None));
        }

        var identityBeforeLogin =
            await db.UserIdentities
                .SingleAsync(
                    x => x.UserId == result.UserId);

        Assert.Equal(
            3,
            identityBeforeLogin.FailedLoginAttempts);

        var loginResult =
            await service.LoginAsync(
                new LoginRequest(
                    registerRequest.Email,
                    registerRequest.Password),
                CancellationToken.None);

        Assert.NotNull(loginResult);

        var identityAfterLogin =
            await db.UserIdentities
                .SingleAsync(
                    x => x.UserId == result.UserId);

        Assert.Equal(
            0,
            identityAfterLogin.FailedLoginAttempts);

        Assert.Null(
            identityAfterLogin.LockedUntil);
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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

    [Fact]
    public async Task ForgotPasswordAsync_WithExistingEmail_ShouldCreateResetToken()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "forgot_password_user",
                "forgot@example.com",
                "Forgot Password User");

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var passwordHasher =
            new Argon2PasswordHasher();

        var jwtTokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        await service.ForgotPasswordAsync(
            user.Email,
            CancellationToken.None);

        var resetToken =
            await db.PasswordResetTokens
                .SingleAsync(
                    x => x.UserId == user.Id);

        Assert.Equal(
            "reset-token",
            resetToken.Token);

        Assert.True(
            resetToken.ExpiresAt > DateTime.UtcNow);
    }

    [Fact]
    public async Task ForgotPasswordAsync_WithUnknownEmail_ShouldNotCreateToken()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var jwtTokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        await service.ForgotPasswordAsync(
            "does-not-exist@example.com",
            CancellationToken.None);

        var tokenCount =
            await db.PasswordResetTokens.CountAsync();

        Assert.Equal(
            0,
            tokenCount);
    }

    [Fact]
    public async Task ResetPasswordAsync_WithValidToken_ShouldChangePassword()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "reset_password_user",
                "reset@example.com",
                "Reset Password User");

        var passwordHasher =
            new Argon2PasswordHasher();

        var oldPasswordHash =
            passwordHasher.Hash(
                "OldPassword123!");

        var identity =
            new UserIdentity(
                user.Id,
                oldPasswordHash);

        var resetToken =
            new PasswordResetToken(
                user.Id,
                "valid-reset-token",
                DateTime.UtcNow.AddHours(1));

        db.Users.Add(user);
        db.UserIdentities.Add(identity);
        db.PasswordResetTokens.Add(resetToken);

        await db.SaveChangesAsync();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                new FakeJwtTokenService(),
                new FakeEmailVerificationTokenService(
                    "verification-token"),
                new FakePasswordResetTokenService(
                    "reset-token"),
                new FakeRefreshTokenService(
                    "test-refresh-token"));

        var request =
            new ResetPasswordRequest(
                "valid-reset-token",
                "NewPassword456!");

        var result =
            await service.ResetPasswordAsync(
                request,
                CancellationToken.None);

        Assert.True(
            result.Reset);

        var savedIdentity =
            await db.UserIdentities
                .SingleAsync(
                    x => x.UserId == user.Id);

        Assert.True(
            passwordHasher.Verify(
                "NewPassword456!",
                savedIdentity.PasswordHash));

        Assert.False(
            passwordHasher.Verify(
                "OldPassword123!",
                savedIdentity.PasswordHash));

        var savedToken =
            await db.PasswordResetTokens
                .SingleAsync(
                    x => x.Id == resetToken.Id);

        Assert.True(
            savedToken.IsUsed());
    }

    [Fact]
    public async Task ResetPasswordAsync_WithInvalidToken_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                new FakeJwtTokenService(),
                new FakeEmailVerificationTokenService(
                    "verification-token"),
                new FakePasswordResetTokenService(
                    "reset-token"),
                new FakeRefreshTokenService(
                    "test-refresh-token"));

        var request =
            new ResetPasswordRequest(
                "invalid-token",
                "NewPassword456!");

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.ResetPasswordAsync(
                request,
                CancellationToken.None));
    }

    [Fact]
    public async Task ResetPasswordAsync_WithExpiredToken_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "expired_reset_user",
                "expired-reset@example.com",
                "Expired Reset User");

        var passwordHasher =
            new Argon2PasswordHasher();

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash(
                    "OldPassword123!"));

        var resetToken =
            new PasswordResetToken(
                user.Id,
                "expired-token",
                DateTime.UtcNow.AddMinutes(-1));

        db.Users.Add(user);
        db.UserIdentities.Add(identity);
        db.PasswordResetTokens.Add(resetToken);

        await db.SaveChangesAsync();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                new FakeJwtTokenService(),
                new FakeEmailVerificationTokenService(
                    "verification-token"),
                new FakePasswordResetTokenService(
                    "reset-token"),
                new FakeRefreshTokenService(
                    "test-refresh-token"));

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.ResetPasswordAsync(
                new ResetPasswordRequest(
                    "expired-token",
                    "NewPassword456!"),
                CancellationToken.None));
    }

    [Fact]
    public async Task ResetPasswordAsync_WithUsedToken_ShouldThrowConflict()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "used_reset_user",
                "used-reset@example.com",
                "Used Reset User");

        var passwordHasher =
            new Argon2PasswordHasher();

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash(
                    "OldPassword123!"));

        var resetToken =
            new PasswordResetToken(
                user.Id,
                "used-token",
                DateTime.UtcNow.AddHours(1));

        resetToken.MarkAsUsed();

        db.Users.Add(user);
        db.UserIdentities.Add(identity);
        db.PasswordResetTokens.Add(resetToken);

        await db.SaveChangesAsync();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                new FakeJwtTokenService(),
                new FakeEmailVerificationTokenService(
                    "verification-token"),
                new FakePasswordResetTokenService(
                    "reset-token"),
                new FakeRefreshTokenService(
                    "test-refresh-token"));

        await Assert.ThrowsAsync<ConflictException>(
            () => service.ResetPasswordAsync(
                new ResetPasswordRequest(
                    "used-token",
                    "NewPassword456!"),
                CancellationToken.None));
    }

    [Fact]
    public async Task ResetPasswordAsync_WhenIdentityDoesNotExist_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var user =
            new User(
                "missing_identity_user",
                "missing-identity@example.com",
                "Missing Identity User");

        var resetToken =
            new PasswordResetToken(
                user.Id,
                "missing-identity-token",
                DateTime.UtcNow.AddHours(1));

        db.Users.Add(user);
        db.PasswordResetTokens.Add(resetToken);

        await db.SaveChangesAsync();

        var service =
            new AuthenticationService(
                db,
                new Argon2PasswordHasher(),
                new FakeJwtTokenService(),
                new FakeEmailVerificationTokenService(
                    "verification-token"),
                new FakePasswordResetTokenService(
                    "reset-token"),
                new FakeRefreshTokenService(
                    "test-refresh-token"));

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.ResetPasswordAsync(
                new ResetPasswordRequest(
                    "missing-identity-token",
                    "NewPassword456!"),
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

        public DbSet<Follow> Follows { get; } = null!;

        public DbSet<UserIdentity> UserIdentities =>
            Set<UserIdentity>();

        public DbSet<EmailVerificationToken> EmailVerificationTokens =>
            Set<EmailVerificationToken>();

        public DbSet<PasswordResetToken> PasswordResetTokens =>
            Set<PasswordResetToken>();

        public DbSet<Notification> Notifications =>
            Set<Notification>();

        public DbSet<Challenge> Challenges =>
            Set<Challenge>();

        public DbSet<ChallengeParticipant> ChallengeParticipants =>
            Set<ChallengeParticipant>();

        public DbSet<RefreshToken> RefreshTokens { get; } = null!;

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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                tokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

        var emailVerificationTokenService =
    new FakeEmailVerificationTokenService(
        "test-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var jwtTokenService =
            new FakeJwtTokenService();

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

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

    [Fact]
    public async Task ResendVerificationAsync_ShouldCreateNewToken()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var jwtTokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "new-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var user =
            new User(
                "resend_user",
                "resend@example.com",
                "Resend User");

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash("Password123!"));

        db.Users.Add(user);
        db.UserIdentities.Add(identity);

        await db.SaveChangesAsync();

        await service.ResendVerificationAsync(
            user.Id,
            CancellationToken.None);

        var token =
            await db.EmailVerificationTokens
                .SingleAsync(
                    x => x.UserId == user.Id);

        Assert.Equal(
            "new-verification-token",
            token.Token);

        Assert.False(token.IsExpired());
        Assert.False(token.IsUsed());
    }

    [Fact]
    public async Task ResendVerificationAsync_ShouldExpireExistingToken()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var jwtTokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "new-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var user =
            new User(
                "resend_expire_user",
                "resend_expire@example.com",
                "Resend Expire User");

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash("Password123!"));

        var existingToken =
            new EmailVerificationToken(
                user.Id,
                "old-verification-token",
                DateTime.UtcNow.AddHours(24));

        db.Users.Add(user);
        db.UserIdentities.Add(identity);
        db.EmailVerificationTokens.Add(existingToken);

        await db.SaveChangesAsync();

        await service.ResendVerificationAsync(
            user.Id,
            CancellationToken.None);

        Assert.True(existingToken.IsExpired());

        var tokens =
            await db.EmailVerificationTokens
                .Where(x => x.UserId == user.Id)
                .ToListAsync();

        Assert.Equal(2, tokens.Count);

        Assert.Contains(
            tokens,
            x => x.Token == "new-verification-token");

        Assert.Contains(
            tokens,
            x =>
                x.Token == "old-verification-token" &&
                x.IsExpired());
    }

    [Fact]
    public async Task ResendVerificationAsync_WhenEmailAlreadyVerified_ShouldThrowConflict()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var jwtTokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "new-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        var user =
            new User(
                "verified_user",
                "verified@example.com",
                "Verified User");

        var identity =
            new UserIdentity(
                user.Id,
                passwordHasher.Hash("Password123!"));

        identity.VerifyEmail();

        db.Users.Add(user);
        db.UserIdentities.Add(identity);

        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<ConflictException>(
            () => service.ResendVerificationAsync(
                user.Id,
                CancellationToken.None));
    }

    [Fact]
    public async Task ResendVerificationAsync_WhenUserDoesNotExist_ShouldThrowUnauthorized()
    {
        await using var db =
            CreateDatabase();

        var passwordHasher =
            new Argon2PasswordHasher();

        var jwtTokenService =
            new FakeJwtTokenService();

        var emailVerificationTokenService =
            new FakeEmailVerificationTokenService(
                "new-verification-token");

        var passwordResetTokenService =
            new FakePasswordResetTokenService(
                "test-password-reset-token");

        var refreshTokenService =
            new FakeRefreshTokenService(
            "test-refresh-token");

        var service =
            new AuthenticationService(
                db,
                passwordHasher,
                jwtTokenService,
                emailVerificationTokenService,
                passwordResetTokenService,
                refreshTokenService);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.ResendVerificationAsync(
                Guid.NewGuid(),
                CancellationToken.None));
    }
}