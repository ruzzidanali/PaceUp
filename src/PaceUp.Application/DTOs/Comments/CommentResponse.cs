namespace PaceUp.Application.DTOs.Comments;

public record CommentResponse(
    Guid Id,
    Guid ActivityId,
    Guid UserId,
    string Username,
    string DisplayName,
    string? ProfileImageUrl,
    string Content,
    DateTime CreatedAt);