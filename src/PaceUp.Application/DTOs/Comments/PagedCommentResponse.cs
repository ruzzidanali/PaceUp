namespace PaceUp.Application.DTOs.Comments;

public record PagedCommentResponse(
    IReadOnlyList<CommentResponse> Comments,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);
