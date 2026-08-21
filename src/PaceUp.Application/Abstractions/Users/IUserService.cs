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
}