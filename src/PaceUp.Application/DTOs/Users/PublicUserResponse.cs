namespace PaceUp.Application.DTOs.Users;

public record PublicUserResponse(
    Guid Id,
    string Username,
    string DisplayName,
    string? Bio,
    string? ProfileImageUrl,
    DateTime CreatedAt);
