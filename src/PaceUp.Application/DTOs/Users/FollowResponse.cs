namespace PaceUp.Application.DTOs.Users;

public record FollowResponse(
    Guid UserId,
    string Username,
    string DisplayName,
    string? ProfileImageUrl,
    DateTime FollowedAt);