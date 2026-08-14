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

    public AuthenticationService(
        IApplicationDbContext dbContext,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtTokenService)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
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

        _dbContext.Users.Add(user);
        _dbContext.UserIdentities.Add(identity);

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
}