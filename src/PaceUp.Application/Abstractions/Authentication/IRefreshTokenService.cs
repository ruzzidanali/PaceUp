namespace PaceUp.Application.Abstractions.Authentication;

public interface IRefreshTokenService
{
    Task<string> CreateAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<Guid?> ValidateAsync(
        string refreshToken,
        CancellationToken cancellationToken);

    Task RevokeAsync(
        string refreshToken,
        CancellationToken cancellationToken);

    Task<string?> RotateAsync(
        string refreshToken,
        CancellationToken cancellationToken);
}