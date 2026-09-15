using PaceUp.Application.DTOs.Comments;

namespace PaceUp.Application.Abstractions.Comments;

public interface ICommentService
{
    Task<PagedCommentResponse> GetAsync(
        Guid userId,
        Guid activityId,
        CommentListRequest request,
        CancellationToken cancellationToken);

    Task<CommentResponse> CreateAsync(
        Guid userId,
        Guid activityId,
        CreateCommentRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        Guid userId,
        Guid commentId,
        CancellationToken cancellationToken);
}