namespace PaceUp.Application.DTOs.Authentication;

public record AuthResponse(
    Guid UserId,
    string Username,
    string Email,
    string DisplayName,
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt);