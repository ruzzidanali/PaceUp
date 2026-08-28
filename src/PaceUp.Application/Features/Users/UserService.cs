using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.DTOs.Users;
using PaceUp.Domain.Entities;
using PaceUp.Application.Exceptions;
using PaceUp.Domain.Constants;
using PaceUp.Application.Abstractions.Notifications;

namespace PaceUp.Application.Features.Users;

public class UserService : IUserService
{
    private readonly IApplicationDbContext _dbContext;

    private readonly INotificationService _notificationService;

    public UserService(
    IApplicationDbContext dbContext,
    INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
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

    public async Task<UserResponse?> UpdateProfileAsync(
    Guid userId,
    UpdateProfileRequest request,
    CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .FirstOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken);

        if (user is null)
        {
            return null;
        }

        user.UpdateProfile(
            request.DisplayName,
            request.Bio);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(user);
    }

    public async Task<UserResponse?> UpdateProfileImageAsync(
    Guid userId,
    UpdateProfileImageRequest request,
    CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .FirstOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken);

        if (user is null)
        {
            return null;
        }

        user.UpdateProfileImage(
            request.ProfileImageUrl);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(user);
    }

    public async Task<bool> DeleteAsync(
    Guid userId,
    CancellationToken cancellationToken)
    {
        var user =
            await _dbContext.Users
                .FirstOrDefaultAsync(
                    x => x.Id == userId,
                    cancellationToken);

        if (user is null)
        {
            return false;
        }

        _dbContext.Users.Remove(user);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    public async Task<bool> FollowAsync(
    Guid followerId,
    Guid followingId,
    CancellationToken cancellationToken)
    {
        if (followerId == followingId)
        {
            throw new ConflictException(
                "A user cannot follow themselves.");
        }

        var followingUserExists =
            await _dbContext.Users
                .AnyAsync(
                    x => x.Id == followingId,
                    cancellationToken);

        if (!followingUserExists)
        {
            return false;
        }

        var alreadyFollowing =
            await _dbContext.Follows
                .AnyAsync(
                    x =>
                        x.FollowerId == followerId &&
                        x.FollowingId == followingId,
                    cancellationToken);

        if (alreadyFollowing)
        {
            throw new ConflictException(
                "You are already following this user.");
        }

        var follow =
            new Follow(
                followerId,
                followingId);

        _dbContext.Follows.Add(follow);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        await _notificationService.CreateAsync(
            followingId,
            followerId,
            "NewFollower",
            cancellationToken);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    public async Task<bool> UnfollowAsync(
        Guid followerId,
        Guid followingId,
        CancellationToken cancellationToken)
    {
        var follow =
            await _dbContext.Follows
                .FirstOrDefaultAsync(
                    x =>
                        x.FollowerId == followerId &&
                        x.FollowingId == followingId,
                    cancellationToken);

        if (follow is null)
        {
            return false;
        }

        _dbContext.Follows.Remove(follow);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return true;
    }

    public async Task<bool> IsFollowingAsync(
    Guid followerId,
    Guid followingId,
    CancellationToken cancellationToken)
    {
        return await _dbContext.Follows
            .AsNoTracking()
            .AnyAsync(
                x =>
                    x.FollowerId == followerId &&
                    x.FollowingId == followingId,
                cancellationToken);
    }

    public async Task<FollowListResponse?> GetFollowersAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var userExists =
            await _dbContext.Users
                .AnyAsync(
                    x => x.Id == userId,
                    cancellationToken);

        if (!userExists)
        {
            return null;
        }

        var follows =
            await _dbContext.Follows
                .AsNoTracking()
                .Where(x => x.FollowingId == userId)
                .Include(x => x.Follower)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

        var users =
            follows
                .Select(
                    x =>
                        new FollowResponse(
                            x.Follower.Id,
                            x.Follower.Username,
                            x.Follower.DisplayName,
                            x.Follower.ProfileImageUrl,
                            x.CreatedAt))
                .ToList();

        return new FollowListResponse(
            users,
            users.Count);
    }

    public async Task<FollowListResponse?> GetFollowingAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var userExists =
            await _dbContext.Users
                .AnyAsync(
                    x => x.Id == userId,
                    cancellationToken);

        if (!userExists)
        {
            return null;
        }

        var follows =
            await _dbContext.Follows
                .AsNoTracking()
                .Where(x => x.FollowerId == userId)
                .Include(x => x.Following)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

        var users =
            follows
                .Select(
                    x =>
                        new FollowResponse(
                            x.Following.Id,
                            x.Following.Username,
                            x.Following.DisplayName,
                            x.Following.ProfileImageUrl,
                            x.CreatedAt))
                .ToList();

        return new FollowListResponse(
            users,
            users.Count);
    }

    public async Task<IReadOnlyList<UserSearchResponse>> SearchAsync(
    Guid currentUserId,
    string query,
    CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return [];
        }

        var normalizedQuery = query.Trim().ToLower();

        var users =
            await _dbContext.Users
                .AsNoTracking()
                .Where(
                    x =>
                        x.Id != currentUserId &&
                        (
                            x.Username.ToLower().Contains(normalizedQuery) ||
                            x.DisplayName.ToLower().Contains(normalizedQuery)
                        ))
                .OrderBy(x => x.Username)
                .Take(20)
                .Select(
                    x =>
                        new UserSearchResponse(
                            x.Id,
                            x.Username,
                            x.DisplayName,
                            x.ProfileImageUrl))
                .ToListAsync(cancellationToken);

        return users;
    }
}

