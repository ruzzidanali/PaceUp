using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.DTOs.Users;
using PaceUp.Domain.Entities;
using PaceUp.Application.Exceptions;

namespace PaceUp.Application.Features.Users;

public class UserService : IUserService
{
    private readonly IApplicationDbContext _dbContext;

    public UserService(IApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<UserResponse> CreateAsync(
        CreateUserRequest request,
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

        _dbContext.Users.Add(user);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(user);
    }

    public async Task<UserResponse?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(
                x => x.Id == id,
                cancellationToken);

        return user is null
            ? null
            : Map(user);
    }

    private static UserResponse Map(User user)
    {
        return new UserResponse(
            user.Id,
            user.Username,
            user.Email,
            user.DisplayName,
            user.Bio,
            user.ProfileImageUrl,
            user.CreatedAt);
    }
}