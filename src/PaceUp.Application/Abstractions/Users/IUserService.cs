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
}