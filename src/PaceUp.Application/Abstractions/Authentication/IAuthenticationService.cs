using PaceUp.Application.DTOs.Authentication;

namespace PaceUp.Application.Abstractions.Authentication;

public interface IAuthenticationService
{
    Task<AuthResponse> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken);

    Task<AuthResponse> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken);
}