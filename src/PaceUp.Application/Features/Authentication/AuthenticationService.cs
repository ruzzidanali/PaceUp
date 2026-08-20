using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Authentication;
using PaceUp.Application.Exceptions;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Authentication;

public class AuthenticationService : IAuthenticationService
{
    private readonly IApplicationDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;

    private readonly IEmailVerificationTokenService _emailVerificationTokenService;

    public AuthenticationService(
IApplicationDbContext dbContext,
IPasswordHasher passwordHasher,
IJwtTokenService jwtTokenService,
IEmailVerificationTokenService emailVerificationTokenService)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
        _emailVerificationTokenService =
            emailVerificationTokenService;
    }

    public async Task<AuthResponse> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken)
    {
        var usernameExists = await _dbContext.Users
            .AnyAsync(
                x => x.Username == request.Username,
                cancellationToken);

        if (usernameExists)
        {
            throw new ConflictException(
                "Username is already taken.");
        }

        var emailExists = await _dbContext.Users
            .AnyAsync(
                x => x.Email == request.Email,
                cancellationToken);

        if (emailExists)
        {
            throw new ConflictException(
                "Email is already registered.");
        }

        var user = new User(
            request.Username,
            request.Email,
            request.DisplayName);

        var passwordHash =
            _passwordHasher.Hash(request.Password);

        var identity = new UserIdentity(
            user.Id,
            passwordHash);

        var verificationToken =
    _emailVerificationTokenService.GenerateToken();

        var emailVerificationToken =
            new EmailVerificationToken(
                user.Id,
                verificationToken,
                DateTime.UtcNow.AddHours(24));

        _dbContext.Users.Add(user);
        _dbContext.UserIdentities.Add(identity);
        _dbContext.EmailVerificationTokens.Add(
    emailVerificationToken);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        var accessToken =
            _jwtTokenService.GenerateAccessToken(
                user.Id,
                user.Username,
                user.Email);

        return new AuthResponse(
            user.Id,
            user.Username,
            user.Email,
            user.DisplayName,
            accessToken,
            _jwtTokenService.GetAccessTokenExpiration());
    }

    public async Task<AuthResponse> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .FirstOrDefaultAsync(
                x => x.Email == request.Email,
                cancellationToken);

        if (user is null)
        {
            throw new UnauthorizedAccessException(
                "Invalid email or password.");
        }

        var identity = await _dbContext.UserIdentities
            .FirstOrDefaultAsync(
                x => x.UserId == user.Id,
                cancellationToken);

        if (identity is null)
        {
            throw new UnauthorizedAccessException(
                "Invalid email or password.");
        }

        var passwordValid =
            _passwordHasher.Verify(
                request.Password,
                identity.PasswordHash);

        if (!passwordValid)
        {
            throw new UnauthorizedAccessException(
                "Invalid email or password.");
        }

        var accessToken =
            _jwtTokenService.GenerateAccessToken(
                user.Id,
                user.Username,
                user.Email);

        return new AuthResponse(
            user.Id,
            user.Username,
            user.Email,
            user.DisplayName,
            accessToken,
            _jwtTokenService.GetAccessTokenExpiration());
    }

    public async Task ChangePasswordAsync(
    Guid userId,
    ChangePasswordRequest request,
    CancellationToken cancellationToken)
    {
        var identity =
            await _dbContext.UserIdentities
                .FirstOrDefaultAsync(
                    x => x.UserId == userId,
                    cancellationToken);

        if (identity is null)
        {
            throw new UnauthorizedAccessException(
                "Invalid user.");
        }

        var currentPasswordValid =
            _passwordHasher.Verify(
                request.CurrentPassword,
                identity.PasswordHash);

        if (!currentPasswordValid)
        {
            throw new UnauthorizedAccessException(
                "Current password is incorrect.");
        }

        var newPasswordHash =
            _passwordHasher.Hash(
                request.NewPassword);

        identity.UpdatePassword(
            newPasswordHash);

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

    public async Task<EmailVerificationResponse> VerifyEmailAsync(
    string token,
    CancellationToken cancellationToken)
    {
        var verificationToken =
            await _dbContext.EmailVerificationTokens
                .FirstOrDefaultAsync(
                    x => x.Token == token,
                    cancellationToken);

        if (verificationToken is null)
        {
            throw new UnauthorizedAccessException(
                "Invalid email verification token.");
        }

        if (verificationToken.IsUsed())
        {
            throw new ConflictException(
                "Email verification token has already been used.");
        }

        if (verificationToken.IsExpired())
        {
            throw new UnauthorizedAccessException(
                "Email verification token has expired.");
        }

        var identity =
            await _dbContext.UserIdentities
                .FirstOrDefaultAsync(
                    x => x.UserId == verificationToken.UserId,
                    cancellationToken);

        if (identity is null)
        {
            throw new UnauthorizedAccessException(
                "Unable to verify email.");
        }

        identity.VerifyEmail();

        verificationToken.MarkAsUsed();

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return new EmailVerificationResponse(true);
    }
}