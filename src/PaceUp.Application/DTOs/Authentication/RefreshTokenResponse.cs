namespace PaceUp.Application.DTOs.Authentication;

public record RefreshTokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt);