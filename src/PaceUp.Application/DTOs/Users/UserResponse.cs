namespace PaceUp.Application.DTOs.Users;

public record UserResponse(
    Guid Id,
    string Username,
    string Email,
    string DisplayName,
    string? Bio,
    string? ProfileImageUrl,
    DateTime CreatedAt);