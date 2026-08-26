namespace PaceUp.Application.DTOs.Notifications;

public record NotificationResponse(
    Guid Id,
    string Type,
    bool IsRead,
    Guid ActorUserId,
    string ActorUsername,
    string ActorDisplayName,
    string? ActorProfileImageUrl,
    DateTime CreatedAt);