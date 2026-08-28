using PaceUp.Application.DTOs.Users;

namespace PaceUp.Application.Abstractions.Users;

public interface IUserService
{
    Task<UserResponse> CreateAsync(
        CreateUserRequest request,
        CancellationToken cancellationToken);

    Task<UserResponse?> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken);

    Task<UserResponse?> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequest request,
        CancellationToken cancellationToken);

    Task<UserResponse?> UpdateProfileImageAsync(
        Guid userId,
        UpdateProfileImageRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<bool> FollowAsync(
        Guid followerId,
        Guid followingId,
        CancellationToken cancellationToken);

    Task<bool> UnfollowAsync(
        Guid followerId,
        Guid followingId,
        CancellationToken cancellationToken);

    Task<bool> IsFollowingAsync(
        Guid followerId,
        Guid followingId,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<UserSearchResponse>> SearchAsync(
        Guid currentUserId,
        string query,
        CancellationToken cancellationToken);

    Task<FollowListResponse?> GetFollowersAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<FollowListResponse?> GetFollowingAsync(
        Guid userId,
        CancellationToken cancellationToken);
}