namespace PaceUp.Application.DTOs.Comments;

public record CommentListRequest(
    int Page = 1,
    int PageSize = 20);
