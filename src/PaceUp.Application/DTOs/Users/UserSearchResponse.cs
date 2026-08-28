namespace PaceUp.Application.DTOs.Users;

public record UserSearchResponse(
    Guid Id,
    string Username,
    string DisplayName,
    string? ProfileImageUrl);