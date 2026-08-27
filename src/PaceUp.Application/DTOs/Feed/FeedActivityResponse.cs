namespace PaceUp.Application.DTOs.Feed;

public record FeedActivityResponse(
    Guid Id,
    Guid UserId,
    string Username,
    string DisplayName,
    string? ProfileImageUrl,
    string Type,
    double Distance,
    int DurationSeconds,
    int? Calories,
    DateTime StartedAt,
    DateTime CreatedAt
);