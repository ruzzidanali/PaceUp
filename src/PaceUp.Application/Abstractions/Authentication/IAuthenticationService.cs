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

    Task ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest request,
        CancellationToken cancellationToken);

    Task<EmailVerificationResponse> VerifyEmailAsync(
        string token,
        CancellationToken cancellationToken);

    Task ForgotPasswordAsync(
        string email,
        CancellationToken cancellationToken);

    Task<PasswordResetResponse> ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken);

    Task ResendVerificationAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<RefreshTokenResponse> RefreshAsync(
        string refreshToken,
        CancellationToken cancellationToken);

    Task RevokeRefreshTokenAsync(
        string refreshToken,
        CancellationToken cancellationToken); 
}