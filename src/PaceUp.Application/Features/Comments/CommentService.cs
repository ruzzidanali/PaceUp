using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Comments;
using PaceUp.Application.Abstractions.Notifications;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Comments;
using PaceUp.Domain.Constants;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Features.Comments;

public class CommentService : ICommentService
{
    private readonly IApplicationDbContext _dbContext;
    private readonly INotificationService _notificationService;

    public CommentService(IApplicationDbContext dbContext, INotificationService notificationService)
    {
        _dbContext = dbContext;
        _notificationService = notificationService;
    }

    public async Task<PagedCommentResponse> GetAsync(
    Guid userId,
    Guid activityId,
    CommentListRequest request,
    CancellationToken cancellationToken)
{
    var exists = await _dbContext.Activities
        .AsNoTracking()
        .AnyAsync(x => x.Id == activityId, cancellationToken);

    if (!exists)
        throw new KeyNotFoundException("Activity not found.");

    var page = Math.Max(1, request.Page);
    var pageSize = Math.Clamp(request.PageSize, 1, 100);

    var query = _dbContext.Comments
        .AsNoTracking()
        .Where(x => x.ActivityId == activityId);

    var totalCount = await query.CountAsync(cancellationToken);

    var totalPages = totalCount == 0
        ? 0
        : (int)Math.Ceiling(totalCount / (double)pageSize);

    var comments = await query
        .OrderBy(x => x.CreatedAt)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .Select(x => new CommentResponse(
            x.Id,
            x.ActivityId,
            x.UserId,
            x.User.Username,
            x.User.DisplayName,
            x.User.ProfileImageUrl,
            x.Content,
            x.CreatedAt))
        .ToListAsync(cancellationToken);

    return new PagedCommentResponse(
        comments,
        page,
        pageSize,
        totalCount,
        totalPages);
}

    public async Task<CommentResponse> CreateAsync(
        Guid userId,
        Guid activityId,
        CreateCommentRequest request,
        CancellationToken cancellationToken)
    {
        var activity = await _dbContext.Activities
            .FirstOrDefaultAsync(x => x.Id == activityId, cancellationToken);

        if (activity is null)
            throw new KeyNotFoundException("Activity not found.");

        var comment = new Comment(activityId, userId, request.Content);
        _dbContext.Comments.Add(comment);
        await _dbContext.SaveChangesAsync(cancellationToken);

        if (activity.UserId != userId)
        {
            await _notificationService.CreateAsync(
                activity.UserId,
                userId,
                NotificationTypes.ActivityComment,
                activityId,
                cancellationToken);
        }

        return await _dbContext.Comments.AsNoTracking()
            .Where(x => x.Id == comment.Id)
            .Select(x => new CommentResponse(
                x.Id, x.ActivityId, x.UserId, x.User.Username,
                x.User.DisplayName, x.User.ProfileImageUrl,
                x.Content, x.CreatedAt))
            .SingleAsync(cancellationToken);
    }

    public async Task<bool> DeleteAsync(Guid userId, Guid commentId, CancellationToken cancellationToken)
    {
        var comment = await _dbContext.Comments
            .FirstOrDefaultAsync(
                x => x.Id == commentId && x.UserId == userId,
                cancellationToken);

        if (comment is null)
            return false;

        _dbContext.Comments.Remove(comment);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }
}